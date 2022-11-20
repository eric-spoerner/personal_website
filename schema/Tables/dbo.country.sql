IF EXISTS (SELECT * FROM sys.tables WHERE [name] = 'Country')
DROP TABLE dbo.Country
GO

CREATE TABLE [dbo].[Country](
    ID INT identity (1,1) PRIMARY KEY -- creating new int-based PK
	,FullName [varchar](50) NULL -- convert me to an int!  personID
	,[ISO_Two] [varchar](2) NULL
	,[ISO_Three] [varchar](3) NULL
	,[ISO_Numeric] [int] NULL
    -- --geographies may need to be normalized?  start with country and state
	-- [birthCountry] [varchar](max) NULL, 
	-- [birthState] [varchar](max) NULL,
	-- [birthCity] [varchar](max) NULL,
    -- --tinyint/smallint
	-- [deathYear] [float] NULL,
	-- [deathMonth] [float] NULL,
	-- [deathDay] [float] NULL,

	-- [deathCountry] [varchar](max) NULL,
	-- [deathState] [varchar](max) NULL,
	-- [deathCity] [varchar](max) NULL,
	-- [nameFirst] [varchar](max) NULL,
	-- [nameLast] [varchar](max) NULL,
	-- [nameGiven] [varchar](max) NULL,
	-- [weight] [float] NULL,
	-- [height] [float] NULL,
    -- --bats/throws can be shrunk for sure
	-- [bats] [varchar](max) NULL,
	-- [throws] [varchar](max) NULL,
    -- --why are debut and finalgame varchar?
	-- [debut] [varchar](max) NULL,
	-- [finalGame] [varchar](max) NULL,
	-- [retroID] [varchar](max) NULL,
	-- [bbrefID] [varchar](max) NULL
) ON [PRIMARY]