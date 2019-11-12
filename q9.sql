-- Consistent raters

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q9 cascade;

create table q9(
	client_id INTEGER,
	email VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS allRides CASCADE;
DROP VIEW IF EXISTS allDriverRatings CASCADE;
DROP VIEW IF EXISTS answer CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW allRides AS
select Request.client_id as client_id, count(distinct driver_id) as numRides
from Request join Dropoff on Request.request_id = Dropoff.request_id
	join Dispatch on Request.request_id = Dispatch.request_id
group by client_id;

CREATE VIEW allDriverRatings AS
select Request.client_id as client_id, count(distinct driver_id) as numRatings
from Request join Dropoff on Request.request_id = Dropoff.request_id
	join DriverRating on DriverRating.request_id = Request.request_id
	join Dispatch on Request.request_id = Dispatch.request_id
group by client_id;

CREATE VIEW answer AS
select allRides.client_id, email
from allRides join Client on allRides.client_id = Client.client_id
	join allDriverRatings on Client.client_id = allDriverRatings.client_id
where numRides = numRatings;

-- Your query that answers the question goes below the "insert into" line:
insert into q9
(select * from answer
order by client_id);
