DROP TABLE IF EXISTS ref.ballpark CASCADE;

CREATE TABLE IF NOT EXISTS ref.ballpark
(
	id SERIAL PRIMARY KEY -- SERIAL = auto-increment IDENTITY(1,1) in T-SQL
	,"name" VARCHAR(100)
	,"city" VARCHAR(100)
	,"state_province_id" INT -- FK
	,"country_id" INT
	,"alias1" VARCHAR(100)
	,"alias2" VARCHAR(100)
	,"alias3" VARCHAR(100)
	,"alias4" VARCHAR(100)
	--,"alias5" VARCHAR(100)
	,"lahman_id" CHAR(5) -- same as park key
);