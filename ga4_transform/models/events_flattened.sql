{{config(materialized='table')}}

select
    event_date,
    event_timestamp,
    event_name,
    user_pseudo_id,
    param.key as param_key,
    param.value.string_value as param_string_value,
    param.value.int_value as param_int_value,
    param.value.double_value as param_double_value
from
    {{ source('raw_ga4_export','ga4_raw')}},
    UNNEST(event_params) as t(param)
