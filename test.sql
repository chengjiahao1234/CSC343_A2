-- Rainmakers

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q10 cascade;

create table q10(
	driver_id FLOAT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS test CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW test AS
select sum(amount)
from billed
where request_id >=5 and request_id <=7;


-- Your query that answers the question goes below the "insert into" line:
insert into q10
(select * from test);
