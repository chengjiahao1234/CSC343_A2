--Ratings histogram.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q7 cascade;

create table q7(
    driver_id INTEGER,
    r5 INTEGER,
    r4 INTEGER,
    r3 INTEGER,
    r2 INTEGER,
    r1 INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS allDriverRating CASCADE;
DROP VIEW IF EXISTS newDriver CASCADE;
DROP VIEW IF EXISTS allDriver CASCADE;
DROP VIEW IF EXISTS answer CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW allDriverRating AS
select driver_id, 
    count(case rating when 5 then 1 else null end) as r5,
    count(case rating when 4 then 1 else null end) as r4,
    count(case rating when 3 then 1 else null end) as r3,
    count(case rating when 2 then 1 else null end) as r2,
    count(case rating when 1 then 1 else null end) as r1
from Dispatch join DriverRating 
    on Dispatch.request_id = DriverRating.request_id
group by driver_id;

CREATE VIEW newDriver AS
select driver_id, 0 as r5, 0 as r4, 0 as r3, 0 as r2, 0 as r1
from Driver 
where Driver.driver_id not in 
    (select driver_id from allDriverRating);

CREATE VIEW allDriver AS
(select * from allDriverRating) 
union 
(select * from newDriver);

CREATE VIEW answer AS
select driver_id,
    case when r5 = 0 then null else r5 end as r5,
    case when r4 = 0 then null else r4 end as r4,
    case when r3 = 0 then null else r3 end as r3,
    case when r2 = 0 then null else r2 end as r2,
    case when r1 = 0 then null else r1 end as r1
from allDriver;

-- Your query that answers the question goes below the "insert into" line:
insert into q7
(select * from answer);
