--going to start with a basic drop and create and move on from there.  going to assume we are going to flush rather than make upsert amendments due to limited frequency of new publication
--likely annual

--error handling?

--convert this to a proc in the long term.  Make the output a permanent reference table.
--why does the table name have to be in quotations?  CAPS.  make it all lower case.
--"snake case"

--SELECT * FROM misc_countrycode;

--DELETE FROM dbo.country

--DBCC CHECKIDENT ('country', RESEED, 0)

DROP TABLE IF EXISTS ref.country;

CREATE TABLE IF NOT EXISTS ref.country
(
	ID SERIAL PRIMARY KEY -- SERIAL = auto-increment IDENTITY(1,1) in T-SQL
	,"Name" VARCHAR(100)
	,iso_two CHAR(2)
	,iso_three CHAR(3)
	,iso_numeric INT
);

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
SELECT * FROM country_map where country_id is null;

--Importing ISO State Data.
DROP TABLE IF EXISTS ref.state_province;

--DBCC CHECKIDENT ('StateProvince', RESEED, 0)

SELECT * FROM stg.misc_states;
select * from stg.misc_states WHERE "COUNTRY ISO CHAR 2 CODE" IN ('US','CA');
select * from stg.misc_states WHERE "ISO 3166-2 PRIMARY LEVEL NAME" = 'state';


CREATE TABLE IF NOT EXISTS ref.state_province(
	ID SERIAL PRIMARY KEY
	,country_id INT --Add a FK here!
	,code VARCHAR(50)
	,full_name VARCHAR(100)
	,abbrev_name VARCHAR(100)
	--,ISO_Two CHAR(2)
	--,ISO_Three CHAR(3)
	--,ISO_Numeric INT
);




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

/*
/* START WITH PEOPLE DATA */
DELETE FROM dbo.people -- will need to be more clever about this going forward due to referential integrity considerations.

DBCC CHECKIDENT ('people', RESEED, 0)

INSERT INTO     dbo.people (
                ChadwickID
                ,NameFirst
                ,NameLast
                ,NameGiven
                ,BirthYear
                ,BirthMonth
                ,BirthDay
                ,BirthCountryID
                ,BirthStateID
                ,DeathYear
                ,DeathMonth
                ,DeathDay
                ,DeathCountryID
                ,DeathStateID
                ,Bats
                ,Throws
                ,Height
                ,Weight
                ,Debut
                ,FinalGame
                ,retroid
                ,bbrefid
)
SELECT          peeps.playerid
                ,peeps.NameFirst
                ,peeps.NameLast
                ,peeps.NameGiven
                ,peeps.BirthYear
                ,peeps.BirthMonth
                ,peeps.BirthDay
                ,countrymap_birth.CountryID
                ,state_birth.ID
                ,peeps.DeathYear
                ,peeps.DeathMonth
                ,peeps.DeathDay
                ,countrymap_death.CountryID
                ,state_death.ID
                ,peeps.Bats
                ,peeps.Throws
                ,peeps.Height
                ,peeps.weight
                ,CAST(Debut as date)
                ,CAST(FinalGame as date)
                ,retroid
                ,bbrefid
FROM            dbo.core_people peeps
LEFT JOIN       #countrymap countrymap_birth ON countrymap_birth.country_raw = peeps.BirthCountry
LEFT JOIN       #countrymap countrymap_death ON countrymap_death.country_raw = peeps.DeathCountry
LEFT JOIN       dbo.StateProvince state_birth ON countrymap_birth.CountryID = state_birth.CountryID AND peeps.birthState = state_birth.AbbrevName
LEFT JOIN       dbo.StateProvince state_death ON countrymap_death.CountryID = state_death.CountryID AND peeps.deathState = state_death.AbbrevName

-- select * from dbo.people where birthstateID is not null or deathstateID is not null
-- select * from dbo.people where birthstateid is null and birthcountryid = 233 -- no null US records.  most important.

*/