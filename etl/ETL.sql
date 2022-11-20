--going to start with a basic drop and create and move on from there.  going to assume we are going to flush rather than make upsert amendments due to limited frequency of new publication
--likely annual

--convert this to a proc in the long term.

DELETE FROM dbo.people -- will need to be more clever about this going forward due to referential integrity considerations.

DBCC CHECKIDENT ('people', RESEED, 0)

INSERT INTO dbo.people (
        ChadwickID
        ,BirthYear
        ,BirthMonth
        ,BirthDay
)
SELECT  playerid
        ,BirthYear
        ,BirthMonth
        ,BirthDay
FROM    dbo.core_people

select * from dbo.people