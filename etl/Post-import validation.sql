select * from ref.country c ;

select * from ref.state_province where abbrev_name is not null;

select * from core.people where "weight" is not null order by "weight" asc limit 100;

--check on missing states/countries for birth.
select * from core.people where birth_country_id is not null and birth_state_id is null ;

--only people with missing birth countries died in the 19th century. 
select * from core.people where birth_country_id is null;

select * from core.people where birth_country_id is not null and birth_state_id is null;

--stadiums: check in on state/prov/country.
select * from ref.ballpark b;