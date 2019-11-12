-- Months

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q6 cascade;

create table q6(
    client_id INTEGER,
    year char(4),
    rides INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS yearsWithRides CASCADE;
DROP VIEW IF EXISTS clientsToYears;
DROP VIEW IF EXISTS Rides CASCADE;
DROP VIEW IF EXISTS top1 CASCADE;
DROP VIEW IF EXISTS withoutTop1 CASCADE;
DROP VIEW IF EXISTS top2 CASCADE;
DROP VIEW IF EXISTS withoutTop2 CASCADE;
DROP VIEW IF EXISTS top3 CASCADE;
DROP VIEW IF EXISTS least1 CASCADE;
DROP VIEW IF EXISTS withoutLeast1 CASCADE;
DROP VIEW IF EXISTS least2 CASCADE;
DROP VIEW IF EXISTS withoutLeast2 CASCADE;
DROP VIEW IF EXISTS least3 CASCADE;
drop view if exists finalResult cascade;

-- Define views for your intermediate steps here:
create view yearsWithRides as
	select distinct to_char(Request.datetime, 'YYYY') as year
	from Request join Dropoff on Request.request_id = Dropoff.request_id;

create view clientsToYears as
	select Client.client_id, year
	from Client, yearsWithRides;

create view Rides as
	select clientsToYears.client_id, year, count(Request.request_id) as rides
	from Request join Dropoff on Request.request_id = Dropoff.request_id
		right join clientsToYears 
			on Request.client_id = clientsToYears.client_id
			and year = to_char(Request.datetime, 'YYYY')
		--right join Client on Client.client_id = Request.client_id
	group by clientsToYears.client_id, year;

create view top1 as
	select * from Rides
	where rides = (select max(rides) from Rides);

create view withoutTop1 as
	(select * from Rides) except (select * from top1);

create view top2 as
	select * from withoutTop1
	where rides = (select max(rides) from withoutTop1);

create view withoutTop2 as
	(select * from withoutTop1) except (select * from top2);

create view top3 as
	select * from withoutTop2
	where rides = (select max(rides) from withoutTop2);

create view least1 as
	select * from Rides
	where rides = (select min(rides) from Rides);

create view withoutLeast1 as
	(select * from Rides) except (select * from least1);

create view least2 as
	select * from withoutLeast1
	where rides = (select min(rides) from withoutLeast1);

create view withoutLeast2 as
	(select * from withoutLeast1) except (select * from least2);

create view least3 as
	select * from withoutLeast2
	where rides = (select min(rides) from withoutLeast2);

create view finalResult as
	(select * from top1)
		union
	(select * from top2)
		union
	(select * from top3)
		union
	(select * from least1)
		union
	(select * from least2)
		union
	(select * from least3);
-- Your query that answers the question goes below the "insert into" line:
insert into q6
	(select * from finalResult order by rides DESC);
	
