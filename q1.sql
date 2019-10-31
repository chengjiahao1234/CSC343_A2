-- Months

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q1 cascade;

create table q1(
    client_id INTEGER,
    email VARCHAR(30),
    months INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS allRides CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW allRides AS
SELECT Client.client_id, email, to_char(Dropoff.datetime, 'YYYY:MM') as month
FROM Client LEFT JOIN Request ON Client.client_id = Request.client_id 
LEFT JOIN Dropoff ON Request.request_id = Dropoff.request_id;

-- Your query that answers the question goes below the "insert into" line:
insert into q1
(select client_id, email, count(distinct month) as months
from allRides
group by client_id, email);

