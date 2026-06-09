/*
Customer Support Analytics Project

File:
03_reporting_views.sql

Purpose:
Creates reporting views used for
Power BI dashboard development.
*/

-- == CREATE VIEWS == 

-- Compounding Failures

create or replace view view_failure_score_analysis as
select
    (
        case when first_contact_resolution = 'No' then 1 else 0 end +
        case when escalated_flag = 'Yes' then 1 else 0 end +
        case when sla_status = 'Breached' then 1 else 0 end
    ) as failure_score,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat,
    round(avg(handling_time_mins),2) as aht
from customer_support_final
group by failure_score
order by failure_score;

-- Quality Vs. Reopen Predictor

-- Added quality_sort column to support
-- custom sorting in Power BI visuals.

create or replace view view_quality_reopen_analysis as
select
    case
        when quality_indicator is null then 'Missing'
        when quality_indicator < 70 then 'Below 70'
        when quality_indicator < 85 then '70-84'
        when quality_indicator < 95 then '85-94'
        else '95+'
    end as quality_band,
    case
        when quality_indicator < 70 then 1
        when quality_indicator < 85 then 2
        when quality_indicator < 95 then 3
        when quality_indicator >= 95 then 4
        else 5
    end as quality_sort, -- for changing the sort order in PowerBI
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
group by
    quality_band,
    quality_sort;

-- Escalation Penalty

create or replace view view_escalation_penalty as
select
    ticket_priority,
    case
        when ticket_priority = 'Low' then 1
        when ticket_priority = 'Medium' then 2
        when ticket_priority = 'High' then 3
        when ticket_priority = 'Critical' then 4
    end as priority_sort,
    escalated_flag,
    count(*) as tickets,
    round(avg(handling_time_mins), 2) as aht
from customer_support_final
group by
    ticket_priority,
    escalated_flag
order by
    priority_sort,
    escalated_flag;


-- Handling Time Vs. CSAT

create or replace view view_handling_time_csat as
select
    floor(handling_time_mins / 10) * 10 as time_bucket,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat
from customer_support_final
where csat_score is not null
group by time_bucket
having count(*) >= 50
order by time_bucket;

-- Regional Service Performance

create or replace view view_regional_service_performance as
select
    customer_region,
    customer_tier,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat,
    round(
        100.0 *
        sum(
            case when sla_status = 'Breached'
            then 1 else 0 end
        ) / count(*),
        2
    ) as sla_breach_rate,
    round(
        100.0 *
        sum(
            case when escalated_flag = 'Yes'
            then 1 else 0 end
        ) / count(*),
        2
    ) as escalation_rate,
    round(
        100.0 *
        sum(
            case when first_contact_resolution = 'Yes'
            then 1 else 0 end
        ) / count(*),
        2
    ) as fcr_rate
from customer_support_final
where customer_tier in ('Premium','VIP')
group by
    customer_region,
    customer_tier;

-- Queue Performance Analysis

create or replace view view_queue_performance as
select
    queue_name,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat,
    round(avg(handling_time_mins),2) as aht,
    round(
        100.0 *
        sum(
            case when sla_status = 'Breached'
            then 1 else 0 end
        ) / count(*),
        2
    ) as sla_breach_rate,
    round(
        100.0 *
        sum(
            case when escalated_flag = 'Yes'
            then 1 else 0 end
        ) / count(*),
        2
    ) as escalation_rate
from customer_support_final
group by queue_name;




-- Agent Experience Analysis

create or replace view view_agent_tenure_analysis as
select
    case
        when agent_tenure_months < 12 then 'New'
        when agent_tenure_months < 36 then 'Developing'
        when agent_tenure_months < 60 then 'Experienced'
        else 'Veteran'
    end as tenure_band,
    count(*) as tickets,
    round(avg(csat_score),2) as avg_csat,
    round(avg(handling_time_mins),2) as aht,
    round(
        100.0 * sum(case when sla_status = 'Met' then 1 else 0 end)
        / count(*),
        2
    ) as sla_compliance_pct,
    round(
        100.0 * sum(case when escalated_flag = 'Yes' then 1 else 0 end)
        / count(*),
        2
    ) as escalation_rate_pct,
    round(
        100.0 * sum(case when first_contact_resolution = 'Yes' then 1 else 0 end)
        / count(*),
        2
    ) as fcr_rate_pct

from customer_support_final
group by tenure_band
order by aht desc; 

/*
Outcome:

These reporting views were imported into Power BI
and used to support dashboard visualizations,
tooltips and diagnostic reporting pages.
*/