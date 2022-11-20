IF NOT EXISTS (SELECT * FROM sys.schemas where name = 'stg') 
    EXEC('CREATE SCHEMA [stg]');


	CREATE TABLE stg.[core_AllstarFull] (
        [playerID] VARCHAR(max) NULL,
        [yearID] BIGINT NULL,
        [gameNum] BIGINT NULL,
        [gameID] VARCHAR(max) NULL,
        [teamID] VARCHAR(max) NULL,
        [lgID] VARCHAR(max) NULL,
        [GP] BIGINT NULL,
        [startingPos] FLOAT(53) NULL
)

select * from dbo.core_Fielding