{{config(materialized='table')}}

select event_name, event_timestamp, user_pseudo_id,unnest(privacy_info)
from {{source('raw_ga4_export','ga4_raw')}}
