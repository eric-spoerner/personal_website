--TO DO: explore azure data studio ability to add code snippets
use baseball

--how many ID columns are there?
IF OBJECT_ID('tempdb..#AllIDs') IS NOT NULL 
BEGIN 
    DROP TABLE #AllIDs 
END

select t.name as tbl, c.name as col, dtype.name as datatype
into #AllIDs
from sys.columns as c
join sys.tables as t on c.object_id = t.object_id
left join sys.types as dtype on c.user_type_id = dtype.user_type_id
where c.name like '%ID%' and c.name <> 'GIDP'

select col, datatype, count(*) from #allIDs group by col, datatype order by count(*) desc

select * from sys.columns

select * from sys.types

--YEARID is most common, cast as bigint (totally unnecessary, can go to smallint)
--all other IDs are varchars: most common are playerID, lgID, teamID
--start with replacing playerID in core player db.  