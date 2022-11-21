IF EXISTS (SELECT * FROM sys.tables WHERE [name] = 'people')
DROP TABLE dbo.people
GO

CREATE TABLE [dbo].[People](
    ID INT identity (1,1) PRIMARY KEY -- creating new int-based PK
	,ChadwickID [varchar](10) NULL -- convert me to an int!  personID
	,[NameFirst] [varchar](25) NULL
	,[NameLast] [varchar](25) NULL
    ,[NameGiven] [varchar](100) NULL
	,[BirthYear] [smallint] NULL
	,[BirthMonth] [tinyint] NULL
	,[BirthDay] [tinyint] NULL
    -- --geographies may need to be normalized?  start with country and state
	,BirthCountryID [int] NULL
	-- [birthState] [varchar](max) NULL,
	-- [birthCity] [varchar](max) NULL,
    -- --tinyint/smallint
	,[DeathYear] [float] NULL
	,[DeathMonth] [float] NULL
	,[DeathDay] [float] NULL
    ,[DeathCountryID] [int] NULL
	-- [deathState] [varchar](max) NULL,
	-- [deathCity] [varchar](max) NULL,
	-- [nameGiven] [varchar](max) NULL,
	-- [weight] [float] NULL,
	-- [height] [float] NULL,
    -- --bats/throws can be shrunk for sure
	,[bats] [char] NULL
	,[throws] [char] NULL
    -- --why are debut and finalgame varchar?
	,[debut] [varchar](max)
	,[finalGame] [varchar](max)
	-- [retroID] [varchar](max) NULL,
	-- [bbrefID] [varchar](max) NULL
) ON [PRIMARY]