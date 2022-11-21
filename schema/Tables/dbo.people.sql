IF EXISTS (SELECT * FROM sys.tables WHERE [name] = 'people')
DROP TABLE dbo.people
GO

CREATE TABLE [dbo].[People](
    ID INT identity (1,1) PRIMARY KEY -- creating new int-based PK
	,ChadwickID [varchar](10) NULL
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
	,[DeathYear] [float] NULL
	,[DeathMonth] [float] NULL
	,[DeathDay] [float] NULL
    ,[DeathCountryID] [int] NULL
	-- [deathState] [varchar](max) NULL,
	-- [deathCity] [varchar](max) NULL,
	,[Weight] [float] NULL
	,[Height] [float] NULL
    -- --bats/throws can be shrunk for sure
	,[Bats] [char] NULL
	,[Throws] [char] NULL
    -- --why are debut and finalgame varchar?
	,[Debut] [date] NULL
	,[FinalGame] [date] NULL
	,[retroID] [varchar](10) NULL
	,[bbrefID] [varchar](10) NULL
) ON [PRIMARY]