-- Months

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q2 cascade;

create table q2(
    client_id INTEGER,
    name varchar(41),
    email VARCHAR(30) default 'unknown',
    billed real,
    decline INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS moreThan500Before CASCADE;
DROP VIEW IF EXISTS aFewIn2014 CASCADE;
DROP VIEW IF EXISTS In2015 CASCADE;
DROP VIEW IF EXISTS FewerThan2014 CASCADE;
-- Define views for your intermediate steps here:
create view moreThan500Before as 
	select Client.client_id, concat(firstname, ' ', surname) as name, email, sum(amount) as billed
	from Client 
		join Request on Client.client_id = Request.client_id 
		join Billed on Request.request_id = Billed.request_id
	where date_part('year', Request.datetime) < 2014
	group by Client.client_id
	having sum(amount) >= 500;

create view aFewIn2014 as
	select Client.client_id, count(Dropoff.request_id) as num_rides
	from Client 
		join Request on Client.client_id = Request.client_id 
		join Dropoff on Request.request_id = Dropoff.request_id
	where date_part('year', Request.datetime) = 2014
	group by Client.client_id
	having count(Dropoff.request_id) > 0 and count(Dropoff.request_id) < 10;

create view In2015 as
	select Client.client_id, count(Dropoff.request_id) as num_rides
	from Client 
		join Request on Client.client_id = Request.client_id 
		join Dropoff on Request.request_id = Dropoff.request_id
	where date_part('year', Request.datetime) = 2015
	group by Client.client_id;

create view FewerThan2014 as
	select aFewIn2014.client_id, aFewIn2014.num_rides - In2015.num_rides as decline
	from aFewIn2014 join In2015 on aFewIn2014.client_id = In2015.client_id
	where aFewIn2014.num_rides > In2015.num_rides;

-- Your query that answers the question goes below the "insert into" line:
insert into q2
	(select moreThan500Before.client_id, name, email, billed, decline
		from moreThan500Before join FewerThan2014 on moreThan500Before.client_id = FewerThan2014.client_id);
