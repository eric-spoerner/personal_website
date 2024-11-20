
--CONSIDER GRABBING SEAMHEADS BASEBALL DB INSTEAD.

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
/*
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

--select * from teams_parks;

--most dupes on team parks are a result of multiple franchises playing in the same park, eg philly a's/phils
--eclipse park
--exposition park
--recreation park
--union grounds?
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


update ballpark_stg 
set "park.name" = "park.name" || ' in Cincinnati'
where "park.key" like 'CIN%' and "park.name" in ('League Park I', 'League Park II');

--select * from ballpark_stg where "park.key" like 'CIN%';

--DON'T TOUCH SOURCE FILE!  migrate to temp table and do it there.  or not?
--just do this for now, will reassess when updating/refreshing standard etl process.l
update stg."chad_core_Teams" set park = 'League Park II' where park = 'League Park II/Cleveland Stadium';

--four ballparks called "athletic park", none of them in Indianapolis.
--select * from ballpark_stg where "park.name" = 'Athletic Park';
update ballpark_stg set "park.name" = "park.name" || ' (' || "city" || ')' where "park.name" = 'Athletic Park';
--select * from ballpark_stg where "park.name" like 'Athletic Park%';

--Milwaukee and Kansas City "athletic park" not found here.
select * from stg."chad_core_Teams" where park like '%Athletic Park%';

--indianapolis: per wikipedia, real name is 'Tinker Park', alias "Athletic Park" or "Seventh Street Park"
--select * from ballpark_stg where "park.name" like 'Tinker%' or "park.name" like 'Seventh%';
update stg."chad_core_Teams" 
set "park" = REPLACE(park, 'Athletic Park', 'Seventh Street Park')
where park like '%Athletic Park%' and name like 'Indianapolis%';

update stg."chad_core_Teams" 
set "park" = 'Seventh Street Park I'
where park = 'Seventh Street Park' and name like 'Indianapolis%';
--select * from stg."chad_core_Teams" where park like 'Seventh%';

--milwaukee:
--select * from ballpark_stg where "park.name" like 'Borchert%';
--select * from ballpark_stg where "city" = 'Milwaukee';

update ballpark_stg set alias1 = 'Borchert Field' where "park.key" = 'MIL03';
--add borchert field alias to Athletic Park.  Milwaukee played there for one season in 1891.
select * from ballpark_stg where "city" = 'Milwaukee';

--washington and philly...
--washington's called athletic park
--philly's called Forepaugh Park.
--select * from stg."chad_core_Teams" where park like 'Athletic%';
update stg."chad_core_Teams" set park = 'Forepaugh Park' where park = 'Athletic Park' and "name" like 'Philadelphia%';
update ballpark_stg set "alias1" = 'Athletic Park' where "park.name" = 'Forepaugh Park';
--select * from stg."chad_core_Teams" where name like 'Philadelphia%' order by "yearID" ;

select * from ballpark_stg where city = 'Philadelphia';

--which names are dupes that we should look out for?  check all names and aliases
--9 total dupes across all names and aliases
--couple are generic, wrigley field has Federal League teams.
--consider appending city to name or something
--athletic park was two separate places -- philly (jeferson street grounds) and wash
--resolve duplicate names by appending city name in case of cin/cle "League Park" and Athletic park.

---recreation park: detroit/philly/pittsburgh i sall we have left.
--detroit: home of the detroit wolverines (NL) 1881-1888
--philadelpha: home of the phillies / quakers 1883-1886
--pittsburgh: aka union park / 3a park / coliseum (allegheneys = pirates)
--for pittsburgh, note ballpark switch in mid 1909.  also mid 1970 for move to 3 rivers.  See if this is a common use case?
--15 records -- olympic + hiram bithorn in late expos years for example.
select * from stg."chad_core_Teams" cct where position('/' in "park") > 0;

--update ballpark_stg

update ballpark_stg 
set "park.name" = "park.name" || ' (' || "city" || ')'
where "park.name" like '%Recreation%'
and city IN ('Philadelphia','Pittsburgh','Detroit');

select *
from ballpark_stg 
where "park.name" like '%Recreation%'
and city IN ('Philadelphia','Pittsburgh','Detroit')
order by "park.key";

update stg."chad_core_Teams" 
set "park" = 'Recreation Park (Pittsburgh)'
where name like 'Pittsburg%' and park = 'Recreation Park';

update stg."chad_core_Teams" 
set "park" = 'Recreation Park (Detroit)'
where name like 'Detroit%' and park = 'Recreation Park';

update stg."chad_core_Teams" 
set "park" = 'Recreation Park (Philadelphia)'
where name like 'Philadelphia%' and park = 'Recreation Park';

select * from stg."chad_core_Teams" where "park" like 'Recreation Park%';

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
), dupe_parks AS (
	select "park.name" AS "name", count(*) AS "cnt"
	from ballpark_stg
	where "park.name" is not null
	group by "park.name"
	having count(*) > 1
)
SELECT distinct dupe_parks.*, t."name", t."lgID", t."franchID"
FROM dupe_parks 
LEFT JOIN stg."chad_core_Teams" AS t ON dupe_parks.name = t."park"
order by dupe_parks.name
;

--select * from ballpark_stg where "park.name" like 'League Park%' or "park.name" like '%Cleveland%';


--league park II slash cleveland stadium
--select * from stg."chad_core_Teams" where "park" like 'League Park%';
--select * from stg."chad_core_Parks" where "park.name" like 'League Park%' or "park.name" like '%Cleveland%';

--geauga park grounds not found in teams?
--per wikipedia, was a site of NL cleveland blues/spiders games in 1887.  safe to ignore.
--select * from stg."chad_core_Teams" where "park" like '%geauga%';
--select * from stg."chad_core_Parks" where "park.name" like '%Geauga%';
--select * from stg."chad_core_Teams" where "yearID" = 1887;



/*
 * 
 * 
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