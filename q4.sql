-- Months

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q4 cascade;

create table q4(
    type varchar(10),
    number INTEGER default 0,
    early real default NULL,
    late real default NULL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS atLeast10Days CASCADE;
DROP VIEW IF EXISTS avgOfFirst5Days CASCADE;
DROP VIEW IF EXISTS avgOfAfter5Days CASCADE;
DROP VIEW IF EXISTS earlyAndLate CASCADE;
Drop view if exists finalResult cascade;
drop view if exists train cascade;
Drop table if exists train cascade;
-- Define views for your intermediate steps here:
create view atLeast10Days as 
	select Driver.driver_id, trained, min(Pickup.datetime) as firstDay
	from Driver 
		join Dispatch on Driver.driver_id = Dispatch.driver_id
		join Pickup on Dispatch.request_id = Pickup.request_id
		join Dropoff on Pickup.request_id = Dropoff.request_id
	group by Driver.driver_id
	having count(distinct to_char(Dispatch.datetime, 'YYYY:MM:DD')) >= 10;

create view avgOfFirst5Days as
	select atLeast10Days.driver_id, trained, avg(rating) as early
	from atLeast10Days join Dispatch 
		on atLeast10Days.driver_id = Dispatch.driver_id
		join Dropoff on Dispatch.request_id = Dropoff.request_id
		join DriverRating on Dropoff.request_id = DriverRating.request_id
	where to_date(to_char(Dispatch.datetime, 'YYYY:MM:DD'), 'YYYY:MM:DD') 
		>= to_date(to_char(firstDay, 'YYYY:MM:DD'), 'YYYY:MM:DD')
		and to_date(to_char(Dispatch.datetime, 'YYYY:MM:DD'), 'YYYY:MM:DD') 
			< to_date(to_char(firstDay, 'YYYY:MM:DD'), 'YYYY:MM:DD') + 5
	group by atLeast10Days.driver_id, trained;

create view avgOfAfter5Days as
	select atLeast10Days.driver_id, trained, avg(rating) as late
	from atLeast10Days join Dispatch 
		on atLeast10Days.driver_id = Dispatch.driver_id
		join Dropoff on Dispatch.request_id = Dropoff.request_id
		join DriverRating on Dropoff.request_id = DriverRating.request_id
	where to_date(to_char(Dispatch.datetime, 'YYYY:MM:DD'), 'YYYY:MM:DD') 
		>= to_date(to_char(firstDay, 'YYYY:MM:DD'), 'YYYY:MM:DD') + 5
	group by atLeast10Days.driver_id, trained;

create view earlyAndLate as
	select avgOfFirst5Days.driver_id, avgOfFirst5Days.trained, early, late
	from avgOfFirst5Days full join avgOfAfter5Days 
		on avgOfAfter5Days.driver_id = avgOfFirst5Days.driver_id;

create table train(type varchar(10));
insert into train values ('trained'), ('untrained');

create view finalResult as
	select case when trained then 'trained' else 'untrained' end as type, 
		count(distinct driver_id) as number, avg(early) as early, 
		avg(late) as late
	from earlyAndLate
	group by trained;
	

-- Your query that answers the question goes below the "insert into" line:
insert into q4
	(select type, 
		case when number is NULL then 0 else number end as number, 
		early, late 
	from finalResult natural full join train);
