DROP TABLE IF EXISTS ref.ballpark;

CREATE TABLE IF NOT EXISTS ref.ballpark
(
	ID SERIAL PRIMARY KEY -- SERIAL = auto-increment IDENTITY(1,1) in T-SQL
	,"Name" VARCHAR(100)
	,"City" VARCHAR(100)
	,"StateProvinceID" INT -- FK
	,"CountryID" INT
	,"Alias1" VARCHAR(100)
	,"Alias2" VARCHAR(100)
	,"Alias3" VARCHAR(100)
	,"Alias4" VARCHAR(100)
	,"Alias5" VARCHAR(100)
	,"lahmanID" CHAR(5) -- same as park key
);