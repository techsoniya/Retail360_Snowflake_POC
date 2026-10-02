use database RETAIL360_DEMO;
use schema ML;

select count(*) from ML.SALES_FORECAST_30D;
--30
select count(*) from ML.SALES_ANOMALIES;
--151
select count(*) from ML.INVENTORY_ANOMALIES;
--194
select count(*) from ML.CUSTOMER_SEGMENTS;
--440
select * from ML.VW_AI_CONTROL_TOWER_SUMMARY;
--FORECAST_DAYS	FORECAST_30D_SALES	SALES_ANOMALY_COUNT	INVENTORY_ANOMALY_COUNT	HIGH_VALUE_CUSTOMERS	REFRESHED_AT
--30	47697.59	15	9	42	2026-04-28 01:57:31.277 -0700


-- Step 2: Create app schema and stage
use database RETAIL360_DEMO;

create schema if not exists APP;


create warehouse if not exists RETAIL360_STREAMLIT
with
    warehouse_size = 'XSMALL'
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true;
    
use schema APP;
USE WAREHOUSE RETAIL360_STREAMLIT;

create or replace stage ST_RETAIL360_STREAMLIT;



grant database role SNOWFLAKE.CORTEX_USER to role SYSADMIN;

grant usage on database RETAIL360_DEMO to role SYSADMIN;
grant usage on schema RETAIL360_DEMO.MART to role SYSADMIN;
grant usage on schema RETAIL360_DEMO.ML to role SYSADMIN;

grant select on all views in schema RETAIL360_DEMO.MART to role SYSADMIN;
grant select on all tables in schema RETAIL360_DEMO.ML to role SYSADMIN;
grant select on all views in schema RETAIL360_DEMO.ML to role SYSADMIN;

