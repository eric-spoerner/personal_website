DROP TABLE IF EXISTS ref.state_province CASCADE;

CREATE TABLE IF NOT EXISTS ref.state_province(
	ID SERIAL PRIMARY KEY
	,country_id INT REFERENCES ref.country(ID)
	,code VARCHAR(50)
	,full_name VARCHAR(100)
	,abbrev_name VARCHAR(100)
	--,ISO_Two CHAR(2)
	--,ISO_Three CHAR(3)
	--,ISO_Numeric INT
);