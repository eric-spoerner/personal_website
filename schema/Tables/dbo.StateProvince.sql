IF EXISTS (SELECT * FROM sys.tables WHERE [name] = 'StateProvince')
DROP TABLE dbo.StateProvince
GO

CREATE TABLE [dbo].[StateProvince](
    ID [int] identity (1,1) PRIMARY KEY
	,[Code] [varchar](10) NOT NULL
	,[FullName] [varchar](50) NOT NULL
	,[AbbrevName] [varchar](2) NULL
	,[CountryID] [int] NOT NULL -- I will need to be an FK eventually.
) ON [PRIMARY]