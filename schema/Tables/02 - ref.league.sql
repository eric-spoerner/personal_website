DROP TABLE IF EXISTS ref.league CASCADE;

CREATE TABLE IF NOT EXISTS ref.league
(
	"id" SERIAL PRIMARY KEY -- SERIAL = auto-increment IDENTITY(1,1) in T-SQL
	,"name" VARCHAR(100)
	,abbrev_name VARCHAR(3)
	,lahman_id CHAR(2)
	,is_active BOOLEAN
);