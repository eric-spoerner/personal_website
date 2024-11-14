DROP TABLE IF EXISTS ref.country CASCADE;

CREATE TABLE IF NOT EXISTS ref.country
(
	ID SERIAL PRIMARY KEY -- SERIAL = auto-increment IDENTITY(1,1) in T-SQL
	,"Name" VARCHAR(100)
	,iso_two CHAR(2)
	,iso_three CHAR(3)
	,iso_numeric INT
);