/*
select * from stg."chad_core_Parks";

--IDs to import before teams:
--League, Team (?), Franchise, Division
select * from stg."chad_core_Teams";

select * from stg."chad_core_Teams" where "yearID" = '1984';
SELECT * from stg."chad_core_Teams" WHERE "franchID" IN ('SDP','SFG')
--why are teamID and franchise ID different for SDP?  quirk of naming, may have something to do with Pacific Coast League.

--what are some of these other leagues?
SELECT "lgID", count(*) from stg."chad_core_Teams" GROUP by "lgID";

SELECT "yearID", "lgID", "teamID", "franchID", "name" FROM stg."chad_core_Teams" WHERE "lgID" NOT IN ('NL','AL');

/*
BEGIN TRANSACTION;

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
*/

--UA: Union Association
--AA: American Association
--FL: Federal League
--PL: Players League
SELECT DISTINCT  "lgID", "teamID", "franchID", "name" 
FROM stg."chad_core_Teams" 
WHERE (COALESCE("lgID",'none') NOT IN ('NL','AL'))
ORDER BY "lgID", "teamID";

--solely exists for strike-affected 1981 season with odd schedule.  address this later.
SELECT * FROM stg."chad_core_TeamsHalf";

select * from stg."chad_core_Teams" where "yearID" = 1981;


--Null IDs look to be pre-league, professional barnstormers etc.
SELECT "yearID", "lgID", "teamID", "franchID", "name" FROM stg."chad_core_Teams" WHERE "lgID" IS NULL;


--convert this to a serial ID
--NAAssoc = ID of the team 
select * from stg."chad_core_TeamsFranchises" WHERE "NAassoc" is not null;
select * from stg."chad_core_TeamsFranchises" WHERE "franchName" like '%San Diego%'

SELECT
    column_name,
    data_type
FROM
    information_schema.columns
WHERE
    table_name = 'chad_core_Teams';

select * from stg."chad_core_Parks";

SELECT "teamID", "franchID", "name", park, count(*) from stg."chad_core_Teams" group by "teamID", "franchID", "name", park;

select * from stg."chad_core_Parks";

--parks: stadium ID, country ID -- disaggregate alias to map to individual names in the 

--normalization here might get a little painful.
--will need to parse out special characters (/ or ;)
--special characters
with teams_parks as (
SELECT "teamID", "franchID", "name", park, count(*) from stg."chad_core_Teams" group by "teamID", "franchID", "name", park
)
select * from teams_parks
order by "name";

with teams_parks as (
SELECT "teamID", "franchID", "name", park, count(*) from stg."chad_core_Teams" group by "teamID", "franchID", "name", park
)
select * from teams_parks
*/

--start alias manipulation
DROP TABLE IF EXISTS ballpark_stg;

select *
into temporary table ballpark_stg
from stg."chad_core_Parks"; 
--where "park.alias" like '%;%' or "park.alias" like '%/%';

alter table ballpark_stg add column alias_temp VARCHAR(100);
alter table ballpark_stg add column alias1 VARCHAR(100);
alter table ballpark_stg add column alias2 VARCHAR(100);
alter table ballpark_stg add column alias3 VARCHAR(100);
alter table ballpark_stg add column alias4 VARCHAR(100);

--only slash is for "San Diego/Jack Murphy".  Don't worrry about that one procedurally, ahndle the semicolons

update ballpark_stg set alias_temp = "park.alias"
where "park.alias" is not null ;

update ballpark_stg set alias1 = "park.alias", alias_temp=null where strpos("alias_temp", ';') = 0;

update ballpark_stg
set  	alias1 = trim(substring("park.alias", 0, strpos("park.alias", ';')))
		,alias_temp =  trim(substring("alias_temp"
						,strpos("alias_temp", ';') + 1
						,length("alias_temp") - strpos("alias_temp", ';')))
--from ballpark_stg
where strpos("alias_temp", ';') > 0;

update ballpark_stg set alias2 = "alias_temp", alias_temp=null where strpos("alias_temp", ';') = 0;

update ballpark_stg
set  	alias2 = trim(substring("alias_temp", 0, strpos("alias_temp", ';')))
		,alias_temp =  trim(substring("alias_temp"
						,strpos("alias_temp", ';') + 1
						,length("alias_temp") - strpos("alias_temp", ';')))
--from ballpark_stg
	where strpos("alias_temp", ';') > 0;

update ballpark_stg set alias3 = "alias_temp", alias_temp=null where strpos("alias_temp", ';') = 0;


update ballpark_stg
set  	alias3 = trim(substring("alias_temp", 0, strpos("alias_temp", ';')))
		,alias_temp =  trim(substring("alias_temp"
						,strpos("alias_temp", ';') + 1
						,length("alias_temp") - strpos("alias_temp", ';')))
--from ballpark_stg
where "alias_temp" is not null 
	and strpos("alias_temp", ';') > 0;

update ballpark_stg set alias4 = "alias_temp", alias_temp=null where strpos("alias_temp", ';') = 0;

alter table ballpark_stg drop column "park.alias";
alter table ballpark_stg drop column "alias_temp";


--select * from ballpark_stg;

--end alias manipulation.  COMMENCE VERIFICATION.

drop table if exists teams_parks;

SELECT "teamID", "franchID", "name", park, count(*) 
into temporary table teams_parks
from stg."chad_core_Teams" 
group by "teamID", "franchID", "name", park;

select * from teams_parks;

--most dupes on team parks are a result of multiple franchises playing in the same park, eg philly a's/phils
;with dupes as (
select "park", count(*) as cnt
from teams_parks
where "park" is not null
group by "park"
having count(*) > 1
order by count(*) desc
)
select * 
from dupes
join teams_parks on teams_parks.park = dupes.park
order by dupes.park;

--which names are dupes that we should look out for?  check all names and aliases
--9 total dupes across all names and aliases
--couple are generic, wrigley field likely corresponds to early years of LA angels
--consider appending city to name or something
with allparknames as (
	select "park.name" from ballpark_stg
	union all
	select "alias1" from ballpark_stg
	union all
	select "alias2" from ballpark_stg
	union all
	select "alias3" from ballpark_stg
	union all
	select "alias4" from ballpark_stg
)
select "park.name", count(*) 
from ballpark_stg
where "park.name" is not null
group by "park.name"
having count(*) > 1
;



/*
select "park.name"
		, "park.alias"
		, strpos("park.alias", ';') 
		, trim(substring("park.alias", 0, strpos("park.alias", ';')))
		, trim(substring("park.alias"
					,strpos("park.alias", ';') + 1
					,length("park.alias") - strpos("park.alias", ';')))
from ballparks_stg
where "park.alias" is not null 
	and strpos("park.alias", ';') > 0;
*/


--next: create the stadium table



--conversion chart:
/*
	"yearID"	"bigint" -- why ID?  just be year
"lgID"	"text"  --normalize to table
"teamID"	"text" --primary ID, send to identifier table
"franchID"	"text" -- normalize to table?
"divID"	"text" -- normalize to table?
"Rank"	"bigint" -- what is this *division* rank?  Does wildcard ranking exist?
"G"	"bigint"
"Ghome"	"double precision"
"W"	"bigint"
"L"	"bigint"
"DivWin"	"text" -- bool
"WCWin"	"text" -- bool
"LgWin"	"text" -- bool
"WSWin"	"text" -- bool
"R"	"bigint"
"AB"	"bigint"
"H"	"bigint"
"2B"	"bigint"
"3B"	"bigint"
"HR"	"bigint"
"BB"	"double precision" -- int
"SO"	"double precision" -- int
"SB"	"double precision" -- int
"CS"	"double precision" -- int
"HBP"	"double precision" -- should be int
"SF"	"double precision" -- should be int
"RA"	"bigint"
"ER"	"bigint"
"ERA"	"double precision"
"CG"	"bigint"
"SHO"	"bigint"
"SV"	"bigint"
"IPouts"	"bigint"
"HA"	"bigint"
"HRA"	"bigint"
"BBA"	"bigint"
"SOA"	"bigint"
"E"	"bigint"
"DP"	"bigint"
"FP"	"double precision"
"name"	"text" -- maybe normalize?
"park"	"text" -- normalize
"attendance"	"double precision"   -- should be int
"BPF"	"bigint" -- ballpark factors should be float?
"PPF"	"bigint" -- ballpark factors should be flopat?
"teamIDBR"	"text" -- maybe send to id table
"teamIDlahman45"	"text" -- maybe send to id table
"teamIDretro"	"text"
*/