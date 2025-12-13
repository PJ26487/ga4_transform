{{config(materialized='table')}}

select event_name, event_timestamp, event_date, user_pseudo_id, user_id, 
  device.advertising_id as advertising_id,
  device.category as category,
  device.is_limited_ad_tracking as is_limited_ad_tracking,
  device.language as language,
  device.mobile_brand_name as mobile_brand_name,
  device.mobile_marketing_name as mobile_marketing_name,
  device.mobile_model_name as mobile_model_name,
  device.mobile_os_hardware_model as mobile_os_hardware_model,
  device.operating_system as operating_system,
  device.operating_system_version as operating_system_version,
  device.time_zone_offset_seconds as time_zone_offset_seconds,
  device.vendor_id as vendor_id,
  unnest(device.web_info)
from {{source('raw_ga4_export','ga4_raw')}}

