--Part2 dispatch.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q11 cascade;

create table q11(
    driver_id INTEGER,
    month VARCHAR(2),
    mileage_2014 real,
    billings_2014 real,
    mileage_2015 real,
    billings_2015 real,
    billings_increase real,
    mileage_increase real
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS allBill CASCADE;
DROP VIEW IF EXISTS availableClient CASCADE;
DROP VIEW IF EXISTS latestAvail CASCADE;
DROP VIEW IF EXISTS ordered CASCADE;
DROP VIEW IF EXISTS goodDrivers CASCADE;
DROP VIEW IF EXISTS test1 CASCADE;
DROP VIEW IF EXISTS test2 CASCADE;
DROP VIEW IF EXISTS answer CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW allBill AS
select Request.client_id as client_id, sum(Billed.amount) as amount
from Billed join Request on Request.request_id = Billed.request_id
group by Request.client_id;

CREATE VIEW availableClient AS
select Request.request_id, Request.client_id
from Request join allBill on Request.client_id = allBill.client_id
join Place on source = name
where not exists
(select request_id
from Dispatch
where Dispatch.request_id = Request.request_id)
--and location[0] <= sth and location[1] <= sth
order by amount DESC;

create view latestAvail as
select Available.driver_id, Available.datetime, location
from Available join (select driver_id, max(datetime) as datetime
from Available 
group by driver_id) A1 on Available.driver_id = A1.driver_id and Available.datetime = A1.datetime
where location[0] <= 100 and location[0] >= 0 and location[1] <= 100
and location[1] >= 0;

create view ordered as 
select request_id, Request.client_id, datetime, location as source, amount
from Request join allBill on Request.client_id = allBill.client_id
join Place on source = name
order by amount DESC;

create view goodDrivers as 
select latestAvail.driver_id, latestAvail.location
from latestAvail --join Dispatch on latestAvail.driver_id = Dispatch.driver_id 
where not exists 
(select latestAvail.driver_id, latestAvail.datetime 
from latestAvail join Dispatch on latestAvail.driver_id = Dispatch.driver_id 
where Dispatch.datetime > latestAvail.datetime);

create view test1 as
select * 
from ordered
where source[0] >= 0 and source[0] <= 100 and source[1] >= 0 and source[1] <= 100;

create view test2 as
select driver_id, location, point (79.3871,43.6426) <@> location as distance
from goodDrivers
where location[0] >= 0 and location[0] <= 100 and location[1] >= 0 and location[1] <= 100
order by distance limit 1;

--CREATE VIEW answer AS


-- Your query that answers the question goes below the "insert into" line:
--insert into q11
--(select * from answer
--order by driver_id, month);
