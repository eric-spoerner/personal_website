DROP TABLE IF EXISTS core.people;

CREATE TABLE core.people(
    ID SERIAL PRIMARY KEY -- creating new int-based PK
	,chadwick_id varchar(10) NULL
	,name_first varchar(25) NULL
	,name_last varchar(25) NULL
    ,name_given varchar(100) NULL
	,birth_year smallint NULL
	,birth_month smallint NULL
	,birth_day smallint NULL
    -- --geographies may need to be normalized?  start with country and state
	,birth_country_id int NULL
	,birth_state_id int NULL
	-- birthState varchar(max) NULL,
	-- birthCity varchar(max) NULL,
	,death_year float NULL
	,death_month float NULL
	,death_day float NULL
    ,death_country_id int NULL
	,death_state_id int NULL
	-- deathState varchar(max) NULL,
	-- deathCity varchar(max) NULL,
	,weight float NULL
	,height float NULL
    -- --bats/throws can be shrunk for sure
	,bats char NULL
	,throws char NULL
    -- --why are debut and finalgame varchar?
	,debut date NULL
	,final_game date NULL
	,retro_id varchar(10) NULL
	,bbref_id varchar(10) NULL
);