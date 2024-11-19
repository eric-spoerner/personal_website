--going to start with a basic drop and create and move on from there.  
--going to assume we are going to flush rather than make upsert amendments due to limited frequency of new publication
--likely annual

--error handling?

--how aggressive should we be with creating individual schemas?  what is their overall purpose?

--convert this to a proc in the long term.  Make the output a permanent reference table?

INSERT INTO ref.country 
(
        "Name"
        ,"iso_two"
        ,"iso_three"
        ,"iso_numeric"
        )
SELECT  "English short name lower case"
        ,"Alpha-2 code"
        ,"Alpha-3 code"
        ,"Numeric code"
FROM    stg."misc_CountryCode";

DROP TABLE IF EXISTS country_map;

--Country cleanup/normalization.

CREATE TEMPORARY TABLE IF NOT EXISTS country_map
(
	country_raw VARCHAR(50)
	,country_clean VARCHAR(50)
	,country_id INT
);

WITH country_agg AS (
    SELECT country FROM stg."chad_core_Parks"
    UNION ALL
    SELECT "birthCountry" FROM stg."chad_core_People"
    UNION ALL
    SELECT "deathCountry" FROM stg."chad_core_People"
    UNION ALL
    select country FROM stg."chad_contrib_Schools"
)
INSERT INTO country_map (country_raw)
SELECT DISTINCT country FROM country_agg WHERE country IS NOT NULL;

UPDATE country_map SET country_clean = replace(country_raw,'.','') WHERE STRPOS(country_raw,'.') > 0;
UPDATE country_map SET country_clean = 'UA' WHERE country_raw = 'Ukriane';
UPDATE country_map SET country_clean = 'DO' WHERE country_raw = 'D.R.';
UPDATE country_map SET country_clean = 'AN' WHERE country_raw = 'Curacao'; --curacao captured under netherlands antilles
UPDATE country_map SET country_clean = 'KOR' WHERE country_raw = 'South Korea'; 
UPDATE country_map SET country_clean = 'PRK' WHERE country_raw = 'North Korea'; 
UPDATE country_map SET country_clean = 'GB' WHERE country_raw = 'UK'; 
UPDATE country_map SET country_clean = 'VN' WHERE country_raw = 'Viet Nam'; 
UPDATE country_map SET country_clean = country_raw WHERE country_clean IS NULL;

UPDATE      country_map
SET         country_ID = list.ID
FROM        ref.country AS list WHERE list.ISO_Two = country_map.country_clean;

UPDATE      country_map
SET         country_ID = list.ID
FROM        ref.country AS list WHERE list.ISO_Three = country_map.country_clean;

UPDATE      country_map
SET         country_ID = list.ID
FROM        ref.country AS list WHERE list."Name" = country_map.country_clean;

--Importing ISO State Data.

INSERT INTO ref.state_province (
    code
    ,full_name
    ,abbrev_name
    ,country_id
)
SELECT      "COUNTRY NAME  ISO 3166-2 SUB-DIVISION/STATE CODE"
            ,"ISO 3166-2 SUBDIVISION/STATE NAME"
            ,CASE WHEN c.iso_two IN ('AU','US','CA') -- Will expand this as needed for other countries with good state data
                THEN substring("COUNTRY NAME  ISO 3166-2 SUB-DIVISION/STATE CODE",4,LENGTH("COUNTRY NAME  ISO 3166-2 SUB-DIVISION/STATE CODE"))
            END
            ,c.ID
FROM        stg.misc_states AS s
INNER JOIN  ref.country AS c on s."COUNTRY ISO CHAR 2 CODE" = c.iso_two
WHERE      "ISO 3166-2 SUBDIVISION/STATE NAME" IS NOT NULL;

--START WITH PEOPLE DATA 
DELETE FROM core.people; -- will need to be more clever about this going forward due to referential integrity considerations.

INSERT INTO     core.people (
                chadwick_id
                ,name_first
                ,name_last
                ,name_given
                ,birth_year
                ,birth_month
                ,birth_day
                ,birth_country_id
                ,birth_state_id
                ,death_year
                ,death_month
                ,death_day
                ,death_country_id
                ,death_state_id
                ,bats
                ,throws
                ,height
                ,weight
                ,debut
                ,final_game
                ,retro_id
                ,bbref_id
)
SELECT          peeps."playerID"
                ,peeps."nameFirst"
                ,peeps."nameLast"
                ,peeps."nameGiven"
                ,peeps."birthYear"
                ,peeps."birthMonth"
                ,peeps."birthDay"
                ,countrymap_birth.country_id
                ,state_birth.id
                ,peeps."deathYear"
                ,peeps."deathMonth"
                ,peeps."deathDay"
                ,countrymap_death.country_id
                ,state_death.ID
                ,peeps.Bats
                ,peeps.Throws
                ,peeps.Height
                ,peeps.weight
                ,CAST(peeps."debut" as date)
                ,CAST(peeps."finalGame" as date)
                ,peeps."retroID"
                ,peeps."bbrefID"
FROM            stg."chad_core_People" peeps
LEFT JOIN       country_map countrymap_birth ON countrymap_birth.country_raw = peeps."birthCountry"
LEFT JOIN       country_map countrymap_death ON countrymap_death.country_raw = peeps."deathCountry"
LEFT JOIN       ref.state_province state_birth ON countrymap_birth.country_id = state_birth.country_id AND peeps."birthState" = state_birth.abbrev_name
LEFT JOIN       ref.state_province state_death ON countrymap_death.country_id = state_death.country_id AND peeps."deathState" = state_death.abbrev_name
;

INSERT INTO ref.league (
	"abbrev_name"
	,"lahman_id"
)
SELECT DISTINCT "lgID", "lgID"
FROM stg."chad_core_Teams"
WHERE "lgID" IS NOT NULL;

UPDATE ref.league SET "name" = 'National League', is_active = TRUE WHERE "lahman_id" = 'NL';
UPDATE ref.league SET "name" = 'American League', is_active = TRUE WHERE "lahman_id" = 'AL';
UPDATE ref.league SET "name" = 'Players'' League', is_active = FALSE WHERE "lahman_id" = 'PL';
UPDATE ref.league SET "name" = 'Federal League', is_active = FALSE WHERE "lahman_id" = 'FL';
UPDATE ref.league SET "name" = 'Union Assocation', is_active = FALSE WHERE "lahman_id" = 'UA';
UPDATE ref.league SET "name" = 'American Association', is_active = FALSE WHERE "lahman_id" = 'AA';

DROP TABLE IF EXISTS ballpark_stg;

select *
into temporary table ballpark_stg
from stg."chad_core_Parks"; 

alter table ballpark_stg add column alias_temp VARCHAR(100);
alter table ballpark_stg add column alias1 VARCHAR(100);
alter table ballpark_stg add column alias2 VARCHAR(100);
alter table ballpark_stg add column alias3 VARCHAR(100);
alter table ballpark_stg add column alias4 VARCHAR(100);

update ballpark_stg set alias_temp = "park.alias"
where "park.alias" is not null ;

update ballpark_stg set alias1 = "park.alias", alias_temp=null where strpos("alias_temp", ';') = 0;

update ballpark_stg
set  	alias1 = trim(substring("park.alias", 0, strpos("park.alias", ';')))
		,alias_temp =  trim(substring("alias_temp"
						,strpos("alias_temp", ';') + 1
						,length("alias_temp") - strpos("alias_temp", ';')))
where strpos("alias_temp", ';') > 0;

update ballpark_stg set alias2 = "alias_temp", alias_temp=null where strpos("alias_temp", ';') = 0;

update ballpark_stg
set  	alias2 = trim(substring("alias_temp", 0, strpos("alias_temp", ';')))
		,alias_temp =  trim(substring("alias_temp"
						,strpos("alias_temp", ';') + 1
						,length("alias_temp") - strpos("alias_temp", ';')))
where strpos("alias_temp", ';') > 0;

update ballpark_stg set alias3 = "alias_temp", alias_temp=null where strpos("alias_temp", ';') = 0;


update ballpark_stg
set  	alias3 = trim(substring("alias_temp", 0, strpos("alias_temp", ';')))
		,alias_temp =  trim(substring("alias_temp"
						,strpos("alias_temp", ';') + 1
						,length("alias_temp") - strpos("alias_temp", ';')))
where "alias_temp" is not null and strpos("alias_temp", ';') > 0;

update ballpark_stg set alias4 = "alias_temp", alias_temp=null where strpos("alias_temp", ';') = 0;

alter table ballpark_stg drop column "park.alias";
alter table ballpark_stg drop column "alias_temp";

--some cleanups to be done here.
update ballpark_stg set country = 'GB' where country = 'UK';
update ballpark_stg set state = 'NSW' where state = 'New South Wales';
update ballpark_stg set state = 'NL' where state = 'Nuevo Leon';

insert into ref.ballpark
(
	"name"
	,"city"
	,"state_province_id"
	,"country_id"
	,"alias1" 
	,"alias2"
	,"alias3"
	,"alias4"
	,"lahman_id"
)
select 	b."park.name"
		,b.city
		,sp.id
		,c.id
		,b.alias1
		,b.alias2
		,b.alias3
		,b.alias4
		,b."park.key"
from ballpark_stg as b
left join ref.country c on b.country = c.iso_two
left join ref.state_province sp on b.state = sp.abbrev_name and sp.country_id = c.id;


