{{ config(materialized='table')}}

select 
  user_pseudo_id, 
  user_id, us.key, 
  us.value.double_value as user_prop_double_value,
  us.value.float_value as user_prop_float_value,
  us.value.int_value as user_prop_int_value,
  us.value.set_timestamp_micros as user_prop_timestamp_micros,
  us.value.string_value as user_prop_string_value
from {{source('raw_ga4_export','ga4_raw')}}, 
    unnest(user_properties) as t(us)