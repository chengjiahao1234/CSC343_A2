-- Bigger and smaller spenders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q5 cascade;

create table q5(
    client_id INTEGER,
    month VARCHAR(7),
    total REAL,
    comparison VARCHAR(11)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS allBill CASCADE;
DROP VIEW IF EXISTS averageAmount CASCADE;
DROP VIEW IF EXISTS allClientBill CASCADE;
DROP VIEW IF EXISTS answer CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW allBill AS
select Request.client_id as client_id, 
    to_char(Request.datetime, 'YYYY MM') as month, 
    sum(Billed.amount) as amount
from Billed join Request on Request.request_id = Billed.request_id
group by Request.client_id, to_char(Request.datetime, 'YYYY MM');

CREATE VIEW averageAmount AS
select month, avg(amount) as average
from allBill
group by month;

CREATE VIEW allClientBill AS
select Client.client_id as client_id, month, 
    case when Client.client_id = allBill.client_id then amount
        else 0
    end as total
from Client, allBill;

CREATE VIEW answer AS
select client_id, allClientBill.month, total, 
    case when total >= average then 'at or above'
        else 'below'
    end as comparison
from allClientBill join averageAmount 
    on allClientBill.month = averageAmount.month;

-- Your query that answers the question goes below the "insert into" line:
insert into q5
(select * from answer);
