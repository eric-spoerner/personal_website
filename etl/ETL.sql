--going to start with a basic drop and create and move on from there.  going to assume we are going to flush rather than make upsert amendments due to limited frequency of new publication
--likely annual

--error handling?

--how aggressive should we be with creating individual schemas?  what is their overall purpose?

--convert this to a proc in the long term.  Make the output a permanent reference table.
--why does the table name have to be in quotations?  CAPS.  make it all lower case.
--"snake case"

--SELECT * FROM misc_countrycode;

--DELETE FROM dbo.country

--DBCC CHECKIDENT ('country', RESEED, 0)

--DROP TABLE IF EXISTS ref.state_province;

DELETE FROM ref.state_province;
DELETE FROM ref.country;
DELETE FROM ref.league;

INSERT INTO ref.country (
        "Name"
        ,iso_two
        ,iso_three
        ,iso_numeric
)

SELECT  "English short name lower case"
        ,"Alpha-2 code"
        ,"Alpha-3 code"
        ,"Numeric code"
FROM    stg."misc_CountryCode";

DROP TABLE IF EXISTS country_map;

--research me: temporary tables in postgres
/* CLEAN UP COUNTRY REFERENCES AND NORMALIZE.  CONSIDER RETAINING ME AS A PERMANENT REFERNETIAL MAP */
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

--ONLY null country ID should be "at sea"
--SELECT * FROM country_map where country_id is null;

--Importing ISO State Data.

--DBCC CHECKIDENT ('StateProvince', RESEED, 0)



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


/* START WITH PEOPLE DATA */
DELETE FROM core.people; -- will need to be more clever about this going forward due to referential integrity considerations.

--DBCC CHECKIDENT ('people', RESEED, 0)

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

--select * from stg."chad_core_People";

SELECT * FROM core.people WHERE name_last = 'Gwynn';
select * from country_map;

-- select * from core.people where birth_state_id is not null or death_state_id is not null
-- select * from core.people where birthstateid is null and birthcountryid = 233 -- no null US records.  most important.

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

SELECT * FROM ref.league;

