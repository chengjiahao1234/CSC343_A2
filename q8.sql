-- Months

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q8 cascade;

create table q8(
    client_id INTEGER,
    reciprocals INTEGER,
    difference float
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS hasReciprocals CASCADE;
DROP VIEW IF EXISTS finalResult CASCADE;


-- Define views for your intermediate steps here:
create view hasReciprocals as
	select Request.client_id, Request.request_id
	from Request join DriverRating 
		on Request.request_id = DriverRating.request_id
		join ClientRating on Request.request_id = ClientRating.request_id;

create view finalResult as
	select hasReciprocals.client_id, count(hasReciprocals.request_id), 
		avg(DriverRating.rating) - avg(ClientRating.rating) as difference
	from hasReciprocals join DriverRating 
		on hasReciprocals.request_id = DriverRating.request_id
		join ClientRating 
		on hasReciprocals.request_id = ClientRating.request_id
	group by hasReciprocals.client_id;


-- Your query that answers the question goes below the "insert into" line:
insert into q8
	(select * from finalResult);
