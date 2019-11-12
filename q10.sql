-- Rainmakers

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q10 cascade;

create table q10(
	driver_id INTEGER,
	month CHAR(2),
	mileage_2014 FLOAT,
	billings_2014 FLOAT,
	mileage_2015 FLOAT,
	billings_2015 FLOAT,
	billings_increase FLOAT,
	mileage_increase FLOAT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS allRides CASCADE;
DROP VIEW IF EXISTS allMonth CASCADE;
DROP VIEW IF EXISTS solutionOne CASCADE;
DROP VIEW IF EXISTS solutionTwo CASCADE;
DROP VIEW IF EXISTS answer CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW allRides AS
select Dispatch.driver_id as driver_id, 
    to_char(Request.datetime, 'MM') as month,
    case when to_char(Request.datetime, 'YYYY') = '2014' 
        then p1.location <@> p2.location
        else 0 
    end as distance_2014,
    case when to_char(Request.datetime, 'YYYY') = '2015' 
        then p1.location <@> p2.location 
        else 0 
    end as distance_2015,
    case when to_char(Request.datetime, 'YYYY') = '2014' 
        then amount 
        else 0
    end as bill_2014,
    case when to_char(Request.datetime, 'YYYY') = '2015' 
        then amount 
        else 0
    end as bill_2015
from Dispatch join Request on Dispatch.request_id = Request.request_id
    join Dropoff on Request.request_id = Dropoff.request_id
    join Billed on Dropoff.request_id = Billed.request_id
    join Place p1 on source = p1.name
    join Place p2 on destination = p2.name
where to_char(Request.datetime, 'YYYY') = '2014' or 
    to_char(Request.datetime, 'YYYY') = '2015';


CREATE VIEW allMonth as
select to_char(DATE '2014-01-01' + 
    (interval '1' month * generate_series(0, 11)), 'MM') as month;


CREATE VIEW solutionOne AS
select D.driver_id, M.month, 0 as mileage_2014, 0 as billings_2014, 
    0 as mileage_2015, 0 as billings_2015, 
    0 as billings_increase, 0 as mileage_increase
from Driver D, allMonth M
where not exists 
    (select driver_id, month 
    from allRides
    where D.driver_id = allRides.driver_id and M.month = allRides.month);


CREATE VIEW solutionTwo AS
select driver_id, month, sum(distance_2014) as mileage_2014, 
    sum(bill_2014) as billings_2014, 
    sum(distance_2015) as mileage_2015, 
    sum(bill_2015) as billings_2015, 
    sum(bill_2015) - sum(bill_2014) as billings_increase,
    sum(distance_2015) - sum(distance_2014) as mileage_increase
from allRides
group by driver_id, month;


CREATE VIEW answer AS
(select * from solutionOne)
union
(select * from solutionTwo);

-- Your query that answers the question goes below the "insert into" line:
insert into q10
(select * from answer
order by driver_id, month);
