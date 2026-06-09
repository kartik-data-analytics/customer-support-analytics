/*
Customer Support Analytics Project

File:
01_data_preparation.sql

Purpose:
Creates raw, clean and final analytical tables.
Performs validation, profiling, debugging,
data cleaning and standardization.
*/


-- =====================================
-- RAW TABLE CREATION
-- =====================================

create table customer_support_raw (
    case_id TEXT,
    timestamp TEXT,
    support_channel TEXT,
    issue_type TEXT,
    agent_name TEXT,
    handling_time_mins TEXT,
    sla_status TEXT,
    quality_indicator TEXT,
    csat_score TEXT,
    customer_tier TEXT,
    customer_region TEXT,
    product_category TEXT,
    queue_name TEXT,
    ticket_priority TEXT,
    resolution_status TEXT,
    escalated_flag TEXT,
    first_contact_resolution TEXT,
    reopen_count TEXT,
    agent_tenure_months TEXT
);

-- =====================================
-- DATA IMPORT
-- =====================================

-- Imported CSV through Import/Export Data.. in Pgadmin
-- Source file: customer_support_dataset.csv

-- =====================================
-- INITIAL VALIDATION
-- =====================================

select count(*)
from customer_support_raw;

-- =====================================
-- TRANSFORMATION: RAW TO CLEAN TABLE
-- =====================================

create table customer_support_clean as
select
    case_id,
    cast(timestamp as TIMESTAMP) as timestamp,
    support_channel,
    issue_type,
    agent_name,
    cast(handling_time_mins as numeric (8,1)) as handling_time_mins,
    sla_status,
    cast(nullif(quality_indicator, '') as numeric(5,2)) as quality_indicator,
    cast(nullif(csat_score, '') as numeric(3,1)) as csat_score,
    customer_tier,
    customer_region,
    product_category,
    queue_name,
    ticket_priority,
    resolution_status,
    escalated_flag,
    first_contact_resolution,
    cast(reopen_count as integer) as reopen_count,
    cast(agent_tenure_months as integer) as agent_tenure_months
from customer_support_raw;



-- =====================================
-- DEBUGGING: INTEGER CONVERSION ERROR
-- =====================================

select handling_time_mins
from customer_support_raw
where handling_time_mins like '%.%'
limit 20;

select reopen_count
from customer_support_raw
where reopen_count like '%.%'
limit 20;

select agent_tenure_months
from customer_support_raw
where agent_tenure_months like '%.%'
limit 20;

-- =====================================
-- DEBUGGING: NUMERIC OVERFLOW
-- =====================================

select quality_indicator 
from customer_support_raw 
order by cast(quality_indicator as numeric) desc 
limit 20;


select max(quality_indicator) 
from customer_support_raw;

-- Initial validation queries returned incorrect results
-- due to text datatype handling. Explicit casting was required.

select max(cast(quality_indicator as numeric))
from customer_support_raw
where quality_indicator is not null
and quality_indicator <> '';

select max(cast(csat_score as numeric))
from customer_support_raw
where csat_score is not null
and csat_score <> '';

select max(cast(handling_time_mins as numeric))
from customer_support_raw; 
-- Null filtering not required because the column contained no missing values.

-- =====================================
-- DATA PROFILING
-- =====================================

select count(*)
from customer_support_clean;

-- Missing Value Analysis

select
count(*) as total_rows,
count(csat_score) as available_csat,
count(*) - count(csat_score) as missing_csat
from customer_support_clean;

select count (*) as total_rows,
count(quality_indicator) as quality_indicator_available,
count(*) - count(quality_indicator) as missing_quality_indicator
from customer_support_clean;

select count (*) as total_rows,
count(customer_tier) as customer_tier_available,
count(*) - count(customer_tier) as missing_customer_tier
from customer_support_clean;

select count (*) as total_rows,
count(first_contact_resolution) as first_contact_resolution_available,
count(*) - count(first_contact_resolution) as missing_first_contact_resolution
from customer_support_clean;

-- Distribution Analysis

select customer_region, count (*)
from customer_support_clean
group by customer_region
order by count (*) desc;

select ticket_priority, count (*)
from customer_support_clean
group by ticket_priority
order by count (*) desc;

select queue_name, count (*)
from customer_support_clean
group by queue_name
order by count (*) desc;

-- Categorical Consistency Checks (dirty data checks)

select distinct support_channel
from customer_support_clean
order by support_channel;


select distinct product_category 
from customer_support_clean
order by product_category;

-- =====================================
-- BASIC STATISTICAL PROFILING
-- =====================================


--Handling Time Analysis
--  Validating handling time and investigating potential outlier (maximum handling time value) 

select
min(handling_time_mins),
max(handling_time_mins),
round(avg(handling_time_mins),2) as "AHT"
from customer_support_clean;

--CSAT Analysis

select
min(csat_score),
round(avg(csat_score),2) as "CSAT_average",
max(csat_score)
from customer_support_clean;


--Quality Indicator Analysis

select
min(quality_indicator),
round(avg(quality_indicator),2) as "quality_average",
max(quality_indicator)
from customer_support_clean;

--Resolution Status Distribution

select
resolution_status,
count(*)
from customer_support_clean
group by resolution_status
order by count(*) desc;

--Product Category Distribution

select	
product_category,
count(*)
from customer_support_clean
group by product_category
order by count(*) desc;

-- =====================================
-- FINAL TABLE CREATION
-- =====================================

-- Standardize categorical values for reporting consistency

drop table if exists customer_support_final;

create table customer_support_final as
select
    case_id,
    timestamp,
    lower(support_channel) as support_channel,
    issue_type,
    agent_name,
    handling_time_mins,
    sla_status,
    quality_indicator,
    csat_score,
    customer_tier,
    customer_region,
    lower(product_category) as product_category,
    queue_name,
    ticket_priority,
    resolution_status,
    escalated_flag,
    first_contact_resolution,
    reopen_count,
    agent_tenure_months
from customer_support_clean;


-- =====================================
-- FINAL VALIDATION
-- =====================================

select distinct(product_category) 
from customer_support_final;

select distinct(support_channel) 
from customer_support_final;

/*
Outcome:

customer_support_final was created as the
analysis-ready dataset used for all subsequent
SQL analysis and Power BI reporting.
*/
