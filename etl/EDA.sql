--TO DO: explore azure data studio ability to add code snippets
use baseball

--how many ID columns are there?
IF OBJECT_ID('tempdb..#AllIDs') IS NOT NULL 
BEGIN 
    DROP TABLE #AllIDs 
END

select t.name as tbl, c.name as col, dtype.name as datatype
into #AllIDs
from sys.columns as c
join sys.tables as t on c.object_id = t.object_id
left join sys.types as dtype on c.user_type_id = dtype.user_type_id
where c.name like '%ID%' and c.name <> 'GIDP'

select col, datatype, count(*) from #allIDs group by col, datatype order by count(*) desc

--YEARID is most common, cast as bigint (totally unnecessary, can go to smallint)
--all other IDs are varchars: most common are playerID, lgID, teamID
--start with replacing playerID in core player db.  

select * from #AllIDs where col = 'playerid'

--start with core_People.  these all live in the "stg" database to not be confused with live data.
select * from core_People
select * from core_managers

/*
cleanup of this table: int IDs, convert birth items to smallint 

CREATE TABLE [dbo].[core_People](
	[playerID] [varchar](max) NULL, -- convert me to an int!  personID
	[birthYear] [float] NULL, --smallint
	[birthMonth] [float] NULL, --tinyint
	[birthDay] [float] NULL, --tinyint
    --geographies may need to be normalized?  start with country and state
	[birthCountry] [varchar](max) NULL, 
	[birthState] [varchar](max) NULL,
	[birthCity] [varchar](max) NULL,
    --tinyint/smallint
	[deathYear] [float] NULL,
	[deathMonth] [float] NULL,
	[deathDay] [float] NULL,

	[deathCountry] [varchar](max) NULL,
	[deathState] [varchar](max) NULL,
	[deathCity] [varchar](max) NULL,
	[nameFirst] [varchar](max) NULL,
	[nameLast] [varchar](max) NULL,
	[nameGiven] [varchar](max) NULL,
	[weight] [float] NULL,
	[height] [float] NULL,
    --bats/throws can be shrunk for sure
	[bats] [varchar](max) NULL,
	[throws] [varchar](max) NULL,
    --why are debut and finalgame varchar?
	[debut] [varchar](max) NULL,
	[finalGame] [varchar](max) NULL,
	[retroID] [varchar](max) NULL,
	[bbrefID] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

*/

select birthyear, count(*) from core_People group by birthyear order by birthYear -- 120 nulls,  otherwise clean
select * from core_people where birthyear is null order by debut -- all missing births were early players, largely 19th century

select birthmonth, count(*) from core_People group by birthmonth order by birthmonth --279 nulls
select birthday, count(*) from core_People group by birthday order by birthday --awkward column name.  421 nulls

select * from core_people where birthday is null order by birthMonth

select month(finalgame), count(*) from core_people group by month(finalgame) order by month(finalgame)
select day(finalgame), count(*) from core_people group by day(finalgame) order by day(finalgame) -- interesting distribution here, bunched around beginning and end of mo.  likley due tos tructure of season?

select len(playerid), count(*) from core_people group by len(playerid) order by len(playerID) -- most are 9 chars by a wide margin -- varchar(10) or so to be safe should be fine


select distinct birthcountry from core_people order by birthcountry
/*
issues with birth country record:
sometimes short, sometimes abbrev (DR, CAN, PR vs United States )
will need to import ISO CODES
*/
select t.name as tbl, c.name as col, dtype.name as datatype
from sys.columns as c
join sys.tables as t on c.object_id = t.object_id
left join sys.types as dtype on c.user_type_id = dtype.user_type_id
where c.name like '%country%' -- parks, people, schools

--exploration of country codes
IF OBJECT_ID('tempdb..#country') IS NOT NULL 
BEGIN 
    DROP TABLE #country
END

;with country as (
    SELECT country from core_Parks
    UNION ALL
    SELECT birthCountry from core_People
    UNION ALL
    SELECT deathCountry from core_People
    UNION ALL
    select country from contrib_schools
)
select country as country_raw into #country from country

select country_raw, count(*) from #country group by country_raw order by country_raw  --solution: import ISO codes for states and countries

--ok now let's do states
select t.name as tbl, c.name as col, dtype.name as datatype
from sys.columns as c
join sys.tables as t on c.object_id = t.object_id
left join sys.types as dtype on c.user_type_id = dtype.user_type_id
where c.name like '%state%' -- parks, people, schools

--how many ID columns are there?
IF OBJECT_ID('tempdb..#state') IS NOT NULL 
BEGIN 
    DROP TABLE #state
END

;with [state] as (
    SELECT [state], country from core_Parks
    UNION ALL
    SELECT birthstate, birthcountry from core_People
    UNION ALL
    SELECT deathstate, deathcountry from core_People
    UNION ALL
    select [state], country from contrib_schools
)
select [state] as state_raw, country as country_raw into #state from [state]

select state_raw, country_raw, count(*) 
from #state 
group by country_raw, state_raw 
order by country_raw, state_raw  --yikes.  LOTS of subnational units/states from other countries, etc.  
--will definitely need to normalize countries first before unwinding this.

select *
from misc_countrycode


--check count
IF OBJECT_ID('tempdb..#countrymap') IS NOT NULL 
BEGIN 
    DROP TABLE #countrymap
END


;with country_agg as (
    SELECT country from core_Parks
    UNION ALL
    SELECT birthCountry from core_People
    UNION ALL
    SELECT deathCountry from core_People
    UNION ALL
    select country from contrib_schools
)
select country as country_raw
       ,count(*) as cnt
into    #countrymap
from    country_agg
group by country
order by country

select max(len([English short name lower case])) from misc_countrycode
select max([numeric code]) from misc_countrycode