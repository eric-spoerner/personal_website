select * from stg."chad_core_Parks";

--IDs to import before teams:
--League, Team (?), Franchise, Division
select * from stg."chad_core_Teams";

select * from stg."chad_core_Teams" where "yearID" = '1984'
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


--Null IDs look to be pre-league, professional barnstormers etc.
SELECT "yearID", "lgID", "teamID", "franchID", "name" FROM stg."chad_core_Teams" WHERE "lgID" IS NULL;

select * from stg."chad_core_TeamsFranchises";

--convert this to a serial ID
--NAAssoc = ID of the team 
select * from stg."chad_core_TeamsFranchises" WHERE "NAassoc" is not null;
select * from stg."chad_core_TeamsFranchises" WHERE "franchName" like '%San Diego%'