--going to start with a basic drop and create and move on from there.  going to assume we are going to flush rather than make upsert amendments due to limited frequency of new publication
--likely annual

--convert this to a proc in the long term.
DELETE FROM dbo.country

DBCC CHECKIDENT ('country', RESEED, 0)

INSERT INTO dbo.country (
        FullName
        ,ISO_Two
        ,ISO_Three
        ,ISO_Numeric
)
SELECT  [English short name lower case]
        ,[Alpha-2 code]
        ,[Alpha-3 code]
        ,[numeric code]
FROM    misc_countrycode

select * from dbo.country

/* CLEAN UP COUNTRY REFERENCES AND NORMALIZE.  CONSIDER RETAINING ME AS A PERMANENT REFERNETIAL MAP */
IF OBJECT_ID('tempdb..#countrymap') IS NOT NULL 
BEGIN 
    DROP TABLE #countrymap
END

;WITH country_agg AS (
    SELECT country FROM core_Parks
    UNION ALL
    SELECT birthCountry FROM core_People
    UNION ALL
    SELECT deathCountry FROM core_People
    UNION ALL
    select country FROM contrib_schools
)
SELECT country AS country_raw
       ,cast(NULL AS VARCHAR(50)) AS country_clean
       ,cast(NULL AS INT) AS CountryID
INTO    #countrymap
FROM    country_agg
WHERE   country IS NOT NULL
GROUP BY country
ORDER BY country

UPDATE #countrymap SET country_clean = replace(country_raw,'.','') WHERE CHARINDEX('.', country_raw) > 0
UPDATE #countrymap SET country_clean = 'Ukraine' WHERE country_raw = 'Ukriane'
UPDATE #countrymap SET country_clean = 'DO' WHERE country_raw = 'D.R.' 
UPDATE #countrymap SET country_clean = 'AN' WHERE country_raw = 'Curacao' --curacao captured under netherlands antilles
UPDATE #countrymap SET country_clean = 'KOR' WHERE country_raw = 'South Korea' 
UPDATE #countrymap SET country_clean = 'PRK' WHERE country_raw = 'North Korea' 
UPDATE #countrymap SET country_clean = 'GB' WHERE country_raw = 'UK' 
UPDATE #countrymap SET country_clean = 'VN' WHERE country_raw = 'Viet Nam' 
UPDATE #countrymap SET country_clean = country_raw WHERE country_clean IS NULL

UPDATE      map
SET         countryID = list.ID
FROM        #countrymap map
INNER JOIN  dbo.country list ON list.ISO_Two = map.country_clean

UPDATE      map
SET         countryID = list.ID
FROM        #countrymap map
INNER JOIN  dbo.country list ON list.ISO_Three = map.country_clean

UPDATE      map
SET         CountryID = list.ID
FROM        #countrymap map
INNER JOIN  dbo.country list ON list.FullName = map.country_clean

--ONLY null country ID should be "at sea"
--SELECT * FROM #countrymap where CountryID is null

/* START WITH PEOPLE DATA */
DELETE FROM dbo.people -- will need to be more clever about this going forward due to referential integrity considerations.

DBCC CHECKIDENT ('people', RESEED, 0)

-- INSERT INTO     dbo.people (
--                 ChadwickID
--                 ,BirthYear
--                 ,BirthMonth
--                 ,BirthDay

-- )
SELECT          peeps.playerid
                ,peeps.BirthYear
                ,peeps.BirthMonth
                ,peeps.BirthDay
                ,peeps.BirthCountry
                ,countrymap.CountryID
FROM            dbo.core_people peeps
LEFT JOIN       #countrymap countrymap ON countrymap.country_raw = peeps.BirthCountry

--select * from dbo.people