-- Rest bylaw

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q3 cascade;

create table q3(
    driver INTEGER,
    start timestamp,
    driving timestamp,
    breaks timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW AllRides AS
select Dispatch.driver, Pickup.datetime as pickupTime, Dropoff.datetime as dropoffTime, 
date_part('year', Pickup.datetime) as year, date_part('month', Pickup.datetime) as month, 
date_part('day', Pickup.datetime) as day
-- (date_part('year', Pickup.datetime), date_part('month', Pickup.datetime), date_part('day', Pickup.datetime)) as day
from Dispatch join Pickup join Dropoff 
	on Dispatch.request_id = Pickup.request_id 
	and Pickup.request_id = Dropoff.request_id
where date_part('year', Pickup.datetime) = date_part('year', Dropoff.datetime)
	and date_part('month', Pickup.datetime) = date_part('month', Dropoff.datetime)
	and date_part('day', Pickup.datetime) = date_part('day', Dropoff.datetime)
order by Dispatch.driver, Pickup.datetime;
	
CREATE VIEW Duration AS
select driver, year, month, day, sum(age(dropoffTime, pickupTime)) as driving
from AllRides
group by driver, year, month, day
having sum(date_part('hour', age(dropoffTime, pickupTime))) >= 12;

CREATE VIEW PickupAfterDrop AS
select A1.driver as driver, A1.dropoffTime as dropoffTime, min(A2.pickupTime) as pickupTime, A1.day as day
from AllRide A1 join AllRide A2 on A1.driver = A2.driver
where A1.day = A2.day and A1.dropoffTime <= A2.pickupTime;

CREATE VIEW Break AS
select driver, year, month, day, sum(age(dropoffTime, pickupTime)) as breaks
from PickupAfterDrop
group by driver, year, month, day
having sum(date_part('minute', age(dropoffTime, pickupTime))) <= 15;

CREATE VIEW BrokePerDay AS
select Duration.driver as driver, Duration.year as year, Duration.month as month,Duration.day as day,
Duration.driving as driving, Break.breaks as breaks
-- to_char(year + '-' + month + '-' + day) as start
from Duration join Break on Duration.driver = Break.driver
where Duration.year = Break.year and Duration.month = Break.month and Duration.day = Break.day;

CREATE VIEW Answer AS
select B1.driver, to_char(year + '-' + month + '-' + day) as start, 
B1.driving + B2.driving + B3.driving as driving,
B1.breaks + B2.breaks + B3.breaks as breaks
from BrokePerDay B1, BrokePerDay B2, BrokePerDay B3
where B1.driver = B2.driver = B3.driver and
	-- compare whether the date is 3 in a row

-- Your query that answers the question goes below the "insert into" line:
insert into q3
(select * from Answer);

