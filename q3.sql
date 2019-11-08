-- Rest by-law

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q3 cascade;

create table q3(
    driver_id INTEGER,
    start DATE,
    driving INTERVAL,
    breaks INTERVAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS allRides CASCADE;
DROP VIEW IF EXISTS duration CASCADE;
DROP VIEW IF EXISTS pickupAfterDrop CASCADE;
DROP VIEW IF EXISTS multiRidesBreak CASCADE;
DROP VIEW IF EXISTS oneRideBreak CASCADE;
DROP VIEW IF EXISTS break CASCADE;
DROP VIEW IF EXISTS brokePerDay CASCADE;
DROP VIEW IF EXISTS answer CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW allRides AS
select Dispatch.driver_id as driver, Pickup.datetime as pickupTime, 
    Dropoff.datetime as dropoffTime, 
    to_date(to_char(Pickup.datetime, 'YYYY:MM:DD'), 'YYYY:MM:DD') as day
from Dispatch join Pickup on Dispatch.request_id = Pickup.request_id 
    join Dropoff on Pickup.request_id = Dropoff.request_id
where to_char(Pickup.datetime, 'YYYY:MM:DD') = 
    to_char(Dropoff.datetime, 'YYYY:MM:DD')
order by Dispatch.driver_id, Pickup.datetime;
	
CREATE VIEW duration AS
select driver, day, sum(dropoffTime - pickupTime) as driving
from allRides
group by driver, day
having date_part('hour', sum(dropoffTime - pickupTime)) >= 12;

CREATE VIEW pickupAfterDrop AS
select A1.driver as driver, A2.pickupTime as pickupTime, 
    max(A1.dropoffTime) as dropoffTime, A1.day as day
from allRides A1 join allRides A2 on A1.driver = A2.driver
where A1.day = A2.day and A1.dropoffTime <= A2.pickupTime
group by A1.driver, A1.day, A2.pickupTime;

CREATE VIEW multiRidesBreak AS
select driver, day, sum(pickupTime - dropoffTime) as breaks
from pickupAfterDrop
group by driver, day
having date_part('minute', sum(pickupTime - dropoffTime)) + 
    60 * date_part('hour', sum(pickupTime - dropoffTime)) <= 15;

CREATE VIEW oneRideBreak AS
select driver, day, INTERVAL '00:00:00' as breaks
from duration
where not exists
    (select driver, day
    from multiRidesBreak b
    where duration.driver = b.driver and duration.day = b.day);

CREATE VIEW break AS
(select * from multiRidesBreak)
union
(select * from oneRideBreak);

CREATE VIEW brokePerDay AS
select duration.driver as driver, duration.day as day, 
    duration.driving as driving, break.breaks as breaks
from duration join break on duration.driver = break.driver
where duration.day = break.day;

CREATE VIEW answer AS
select B1.driver, B1.day as start, 
    B1.driving + B2.driving + B3.driving as driving,
    B1.breaks + B2.breaks + B3.breaks as breaks
from brokePerDay B1, brokePerDay B2, brokePerDay B3
where B1.driver = B2.driver and B2.driver = B3.driver 
    and B1.driver = B3.driver
    and B1.day + 1 = B2.day and B2.day + 1 = B3.day and B1.day + 2 = B3.day;

-- Your query that answers the question goes below the "insert into" line:
insert into q3
(select * from answer
order by driver, start);

