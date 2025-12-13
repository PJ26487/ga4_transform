{{config(materialized='table')}}

select event_name, event_timestamp, event_date, user_pseudo_id,user_id,unnest(user_ltv)
from {{source('raw_ga4_export','ga4_raw')}}
