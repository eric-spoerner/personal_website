IF EXISTS (SELECT * FROM sys.tables WHERE [name] = 'Country')
DROP TABLE dbo.Country
GO

CREATE TABLE [dbo].[Country](
    ID INT identity (1,1) PRIMARY KEY -- creating new int-based PK
	,FullName [varchar](50) NULL -- convert me to an int!  personID
	,[ISO_Two] [varchar](2) NULL
	,[ISO_Three] [varchar](3) NULL
	,[ISO_Numeric] [int] NULL
) ON [PRIMARY]