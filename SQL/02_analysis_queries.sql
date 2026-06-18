/* =========================================
   Author: Kartik
   Project: Customer Support Analytics
   Portfolio: github.com/kartik-data-analytics
   ========================================= */
/*
Customer Support Analytics Project

File:
02_analysis_queries.sql

Purpose:
Exploratory analysis, diagnostic investigation,
hypothesis testing and root-cause analysis.
*/


-- =====================================
-- EXPLORATORY ANALYSIS
-- =====================================

-- FCR vs CSAT

select first_contact_resolution,
round(avg(csat_score),2) as CSAT_avg
from customer_support_final
group by first_contact_resolution;


-- Escalation vs CSAT

select escalated_flag, round(avg(csat_score),2) as CSAT_avg
from customer_support_final
group by escalated_flag;


-- Priority Level and Handling Time relationship

select ticket_priority, round(avg(handling_time_mins),2) as "AHT" 
from customer_support_final
group by ticket_priority;


-- Agent Experience Analysis

select 
	case 
		when agent_tenure_months < 12 then '0-11 Months'
		when agent_tenure_months < 36 then '12-35 Months'
		else '36+ Months'
		end as Tenure_at_office,
count(case_id) as cases_processed,
round(avg(handling_time_mins),2) as "AHT", 
round(avg(csat_score),2) as CSAT_avg,
round(avg(quality_indicator),2) as quality_avg,
round(
	100.0 *
	sum(case escalated_flag when 'Yes' then 1 
else 0 end)
	/ count(*),
	2
) as escalation_rate
from customer_support_final
group by Tenure_at_office
order by Tenure_at_office desc;


-- SLA Impact on CSAT

select 
sla_status,
round(avg(csat_score),2) as csat_average 
from customer_support_final
group by sla_status;


-- Queue Escalation Rate Analysis

select queue_name, 
round(
	100.0 *
	sum(case escalated_flag when 'Yes' then 1 
else 0 end)
	/ count(*),
	2
) as escalation_rate
from customer_support_final
group by queue_name
order by escalation_rate desc;


-- Product Category CSAT Analysis

select product_category, 
round(avg(csat_score),2) as csat_average 
from customer_support_final
group by product_category
order by csat_average;



-- =====================================
-- TECHNICAL SUPPORT ROOT-CAUSE INVESTIGATION
-- =====================================


-- SLA Analysis

select
    sla_status,
    count(*) as tickets
from customer_support_final
where queue_name = 'Technical Support'
group by sla_status;

select
    queue_name,
    round(
        100.0 *
        sum(case sla_status when 'Breached' then 1 else 0 end)
        / count(*),
        2
    ) as sla_breach_rate
from customer_support_final
group by queue_name
order by sla_breach_rate desc;


-- FCR Analysis

select
    first_contact_resolution,
    count(*) as tickets
from customer_support_final
where queue_name = 'Technical Support'
group by first_contact_resolution;

-- AHT Analysis (Comparative)

select
    queue_name,
    round(avg(handling_time_mins),2) as aht
from customer_support_final
group by queue_name
order by aht desc;

-- Checking Priority Level of Tickets

select ticket_priority, count(*) as tickets 
from customer_support_final
where queue_name = 'Technical Support'
group by ticket_priority;

-- Queue CSAT Analysis (Comparative)

select
    queue_name,
    round(avg(csat_score),2) as avg_csat
from customer_support_final
group by queue_name
order by avg_csat;

-- Checking Ticket Priority distribution in Each Queue

select
    queue_name,
    ticket_priority, 
	count(*),
    round(
        100.0 * count(*) /
        sum(count(*)) over(partition by queue_name),
        2
    ) as percentage_of_queue
from customer_support_final
group by
    queue_name,
    ticket_priority;


-- Escalation by Priority

select ticket_priority, 
	round(
		100 * 
		sum(case escalated_flag when 'Yes' then 1 else 0 end) 
		/ count(*),
		2) 
	as escalation_rate from customer_support_final
group by ticket_priority;


-- =====================================
-- ADDITIONAL INVESTIGATIONS
-- =====================================

-- First Contact Resolution and Reopen Rate Analysis


select                               
	count(first_contact_resolution) 
	from customer_support_final
	where first_contact_resolution = 'Yes' 
	and reopen_count <> 0;


select
    first_contact_resolution,
    reopen_count,
    count(*) as tickets
from customer_support_final
group by first_contact_resolution, reopen_count
order by first_contact_resolution, reopen_count;


select
    first_contact_resolution,
    count(*) as tickets,
    round(
        100.0 *
        sum(case when reopen_count > 0 then 1 else 0 end)
        / count(*),
        2
    ) as reopen_rate
from customer_support_final
group by first_contact_resolution;


-- Escalation Analysis for Low and Medium Priority Tickets

select
    ticket_priority,
    count(*) as escalated_tickets
from customer_support_final
where escalated_flag = 'Yes'
and ticket_priority in ('Low','Medium')
group by ticket_priority;


select
    product_category,
    count(*) as escalated_tickets
from customer_support_final
where escalated_flag = 'Yes'
and ticket_priority in ('Low','Medium')
group by product_category
order by escalated_tickets desc;


select
    support_channel,
    count(*) as escalated_tickets
from customer_support_final
where escalated_flag = 'Yes'
and ticket_priority in ('Low','Medium')
group by support_channel
order by escalated_tickets desc;



-- Checking escalation rate by product category and support channel

select
    product_category,
	count(*) as total_tickets,
	sum(
        case
            when escalated_flag = 'Yes'
            then 1
            else 0
        end
    ) as escalated_tickets,
	round(
        100.0 *
        sum(
            case
                when escalated_flag = 'Yes'
                then 1
                else 0
            end
        )
        / count(*),
        2
    ) as escalation_rate
from customer_support_final
where ticket_priority in ('Low','Medium')
group by product_category
order by escalation_rate desc;



select
    support_channel,
    count(*) as total_tickets,
    sum(
        case
            when escalated_flag = 'Yes'
            then 1
            else 0
        end
    ) as escalated_tickets,
    round(
        100.0 *
        sum(
            case
                when escalated_flag = 'Yes'
                then 1
                else 0
            end
        )
        / count(*),
        2
    ) as escalation_rate
from customer_support_final
where ticket_priority in ('Low','Medium')
group by support_channel
order by escalation_rate desc;


-- -- Optional validation analysis ----
-- Used to verify whether issue complexity contributes
-- to low CSAT and high handling times.


select issue_type,
count(*) as tickets,
    round(avg(csat_score),2) as avg_csat,
    round(avg(handling_time_mins),2) as aht
from customer_support_final
group by issue_type;

-- =====================================
-- DIAGNOSTIC ANALYSIS
-- =====================================

-- Failure Score Analysis

select
    (
        case
            when first_contact_resolution = 'No' then 1
            else 0
        end
        +
        case
            when escalated_flag = 'Yes' then 1
            else 0
        end
        +
        case
            when sla_status = 'Breached' then 1
            else 0
        end
    ) as failure_score,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat
from customer_support_final
group by failure_score
order by failure_score;


-- Impact on CSAT and AHT

with failure_analysis as
(
    select
        (
            case when first_contact_resolution = 'No' then 1 else 0 end
            +
            case when escalated_flag = 'Yes' then 1 else 0 end
            +
            case when sla_status = 'Breached' then 1 else 0 end
        ) as failure_score,
        csat_score,
        handling_time_mins
    from customer_support_final
)

select
    failure_score,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat,
    round(avg(handling_time_mins),2) as aht
from failure_analysis
group by failure_score
order by failure_score;



-- Quality Indicator and Reopen Rate Analysis

select     
	case
		when quality_indicator is null then 'Missing'
        when quality_indicator < 70 then 'Below 70'
        when quality_indicator < 85 then '70-84'
        when quality_indicator < 95 then '85-94'
        else '95+'
    end as quality_band,
count(*) as tickets,
    round(
        100.0 *
        sum(
            case
                when reopen_count > 0 then 1
                else 0
            end
        ) / count(*),
        2
    ) as reopen_rate
from customer_support_final
group by quality_band
order by quality_band desc;

-- Checking reopened tickets compared to total tickets (95+ Quality)

select
    count(*) as tickets,
    sum(
        case
            when reopen_count > 0 then 1
            else 0
        end
    ) as reopened_tickets
from customer_support_final
where quality_indicator >= 95;



-- Escalation Penalty Analysis

select
    ticket_priority,
    escalated_flag,
    count(*) as tickets,
    round(avg(handling_time_mins),2) as aht
from customer_support_final
group by
    ticket_priority,
    escalated_flag
order by case ticket_priority --using CASE because otherwise sorted by alphabetically which makes medium comes after low
        when 'Critical' then 1
        when 'High' then 2
        when 'Medium' then 3
        when 'Low' then 4
    end,
    escalated_flag;



-- =====================================
-- PRODUCT CATEGORY ANALYSIS
-- =====================================

-- Priority mix

select
    product_category,
    ticket_priority,
    count(*) as tickets,
    round(
        100.0 * count(*) /
        sum(count(*)) over(partition by product_category),
        2
    ) as percentage_of_product
from customer_support_final
group by
    product_category,
    ticket_priority
order by
    product_category,
    percentage_of_product desc;

-- Escalation rate 

select
    product_category,
    count(*) as total_tickets,
    sum(
        case
            when escalated_flag = 'Yes' then 1
            else 0
        end
    ) as escalated_tickets,
    round(
        100.0 *
        sum(
            case
                when escalated_flag = 'Yes' then 1
                else 0
            end
        ) / count(*),
        2
    ) as escalation_rate
from customer_support_final
group by product_category
order by escalation_rate desc;



-- AHT by product

select
    product_category,
    round(avg(handling_time_mins),2) as aht
from customer_support_final
group by product_category
order by aht desc;

--SLA Breach Rate by Product


select
    product_category,
    round(
        100.0 *
        sum(
            case
                when sla_status = 'Breached' then 1
                else 0
            end
        ) / count(*),
        2
    ) as sla_breach_rate
from customer_support_final
group by product_category
order by sla_breach_rate desc;




-- =====================================
-- SLA BREACH RECOVERY ANALYSIS
-- =====================================

-- SLA Breach Recovery Through Service Quality

select
    case
        when quality_indicator is null then 'Missing'
        when quality_indicator < 70 then 'Below 70'
        when quality_indicator < 85 then '70-84'
        when quality_indicator < 95 then '85-94'
        else '95+'
    end as quality_band,
    round(avg(csat_score),2) as avg_csat,
    count(*) as tickets
from customer_support_final
where sla_status = 'Breached'
group by quality_band
order by quality_band;


-- Checking Whether 95+ Quality Tickets Include SLA-Breached Cases

select count(*)
from customer_support_final
where sla_status = 'Breached'
and quality_indicator >= 95;


-- =====================================
-- REGIONAL SERVICE CONSISTENCY ANALYSIS
-- =====================================


select
    customer_region,
    customer_tier,
    count(*) as total_tickets,

    sum(
        case
            when sla_status = 'Breached' then 1
            else 0
        end
    ) as breached_tickets,

    round(
        100.0 *
        sum(
            case
                when sla_status = 'Breached' then 1
                else 0
            end
        ) / count(*),
        2
    ) as sla_breach_rate
from customer_support_final
where customer_tier in ('VIP', 'Premium')
group by
    customer_region,
    customer_tier
order by
    customer_tier,
    customer_region;



-- CSAT, FCR and Escalation Rate Analysis (drilling down)

select
    customer_region,
    customer_tier,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat
from customer_support_final
where customer_tier in ('VIP', 'Premium')
group by
    customer_region,
    customer_tier
order by
    customer_tier,
    customer_region;



select
    customer_region,
    customer_tier,
    round(
        100.0 *
        sum(
            case
                when first_contact_resolution = 'Yes' then 1
                else 0
            end
        ) / count(*),
        2
    ) as fcr_rate
from customer_support_final
where customer_tier in ('VIP', 'Premium')
group by
    customer_region,
    customer_tier
order by
    customer_tier,
    customer_region;


select
    customer_region,
    customer_tier,
    round(
        100.0 *
        sum(
            case
                when escalated_flag = 'Yes' then 1
                else 0
            end
        ) / count(*),
        2
    ) as escalation_rate
from customer_support_final
where customer_tier in ('VIP','Premium')
group by
    customer_region,
    customer_tier
order by
    customer_tier,
    customer_region;



-- =====================================
-- HANDLING TIME VS CUSTOMER SATISFACTION
-- =====================================

-- Handling Time and Customer Satisfaction Analysis

select
    floor(handling_time_mins / 10) * 10 as time_bucket,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat
from customer_support_final
where csat_score is not null
group by time_bucket
having count(*) >= 50
order by time_bucket;



-- Follow-up analysis by support channel

select
    support_channel,
    floor(handling_time_mins / 10) * 10 as time_bucket,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat
from customer_support_final
where csat_score is not null
group by
    support_channel,
    time_bucket
having count(*) >= 50
order by
    support_channel,
    time_bucket;



/*
End of Analysis Queries

Outputs from this file informed dashboard design,
diagnostic investigations and reporting views
used in Power BI.
*/
