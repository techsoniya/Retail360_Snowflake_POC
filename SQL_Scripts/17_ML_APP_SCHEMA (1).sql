-- Retail360 Sales Forecast + Anomaly Detection App
-- Final flow:
-- MART tables
--    ↓
-- ML feature/training tables
--    ↓
-- Snowflake ML forecast model
--    ↓
-- Snowflake ML anomaly models
--    ↓
-- Result tables
--    ↓
-- Streamlit in Snowflake app


-- Part 0 — Create schema and warehouse setup

use database RETAIL360_DEMO;

create schema if not exists ML;
create schema if not exists APP;

use schema ML;

-- Optional, but recommended for ML/demo work
create warehouse if not exists RETAIL360_ML_WH
    warehouse_size = 'SMALL'
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true;

use warehouse RETAIL360_ML_WH;


-- Part 1 — Check whether you have enough history

-- Run this first.

use database RETAIL360_DEMO;
use schema ML;

select
    min(order_date) as min_order_date,
    max(order_date) as max_order_date,
    count(distinct order_date) as distinct_days,
    count(*) as mart_rows
from RETAIL360_DEMO.MART.VW_SALES_DETAIL_CURRENT;

-- For a better model, you ideally want:

-- distinct_days >= 60

-- For anomaly detection, minimum useful threshold:

-- distinct_days >= 12

-- If you only have around 7 days, forecasting will not be meaningful. In that case, regenerate more historical source data first, reload Snowflake, and rebuild marts.



-- MIN_ORDER_DATE	MAX_ORDER_DATE	DISTINCT_DAYS	MART_ROWS
-- 2024-01-01	    2026-01-07	     504	        1340



use database RETAIL360_DEMO;
use schema ML;

create or replace table SALES_DAILY_TRAIN as
select
    to_timestamp_ntz(order_date) as ds,
    sum(net_sales_amount)::float as y,
    count(order_count)::float as order_count,
    sum(total_quantity)::float as units_sold,
    avg(net_sales_amount)::float as avg_daily_sales
from RETAIL360_DEMO.MART.VW_SALES_DAILY_STORE
group by order_date
having sum(net_sales_amount) is not null
order by ds;

-- Validate:

select *
from ML.SALES_DAILY_TRAIN
order by ds;

select
    count(*) as training_days,
    min(ds) as min_ds,
    max(ds) as max_ds,
    min(y) as min_sales,
    max(y) as max_sales,
    avg(y) as avg_sales
from ML.SALES_DAILY_TRAIN;

--TRAINING_DAYS	MIN_DS	MAX_DS	MIN_SALES	MAX_SALES	AVG_SALES
--504	2024-01-01 00:00:00.000	2026-01-07 00:00:00.000	11.1835	4039.0609	350.908701389


-- Part 3 — Create store/channel-level training table
-- This gives your app a more impressive business feel.

create or replace table SALES_DAILY_STORE_CHANNEL_TRAIN as
select
    to_variant(store_id || '|' || sales_channel) as series_id,
    store_id,
    store_code,
    store_name,
    sales_channel,
    to_timestamp_ntz(order_date) as ds,
    sum(net_sales_amount)::float as y,
    sum(total_quantity)::float as units_sold,
    count(distinct order_count)::float as order_count
from RETAIL360_DEMO.MART.VW_SALES_DAILY_STORE
group by
    store_id,
    store_code,
    store_name,
    sales_channel,
    order_date
having sum(net_sales_amount) is not null
order by store_id, sales_channel, ds;

-- Validate per series:

select
    series_id,
    min(ds) as min_ds,
    max(ds) as max_ds,
    count(*) as days_count,
    sum(y) as total_sales
from ML.SALES_DAILY_STORE_CHANNEL_TRAIN
group by series_id
order by days_count desc, total_sales desc;

-- If many series have fewer than 12 rows, use the overall model first.

-- Part 4 — Train the sales forecast model
-- Option A — Overall sales forecast model
create or replace SNOWFLAKE.ML.FORECAST ML.SALES_FORECAST_MODEL(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.SALES_DAILY_TRAIN_SIMPLE'),
    TIMESTAMP_COLNAME => 'DS',
    TARGET_COLNAME => 'Y',
    CONFIG_OBJECT => {
        'frequency': '1 day',
        'method': 'best',
        'lower_bound': 0,
        'evaluate': true
    }
);

-- Snowflake forecast models require a timestamp column and target column; optional config can define frequency, method, bounds, and evaluation behavior. The forecast output includes TS, FORECAST, LOWER_BOUND, and UPPER_BOUND.



----------------------------------------------------------------------------------
--was egtting error here so changed the code
-- Part 5 — Store forecast output into tables
-- Overall 30-day forecast


use database RETAIL360_DEMO;
use schema ML;
use warehouse RETAIL360_ML_WH;

create or replace table ML.SALES_DAILY_TRAIN_SIMPLE as
select
    ds,
    y
from ML.SALES_DAILY_TRAIN
where ds is not null
  and y is not null
order by ds;


-- Then your forecast output query should work:

create or replace table ML.SALES_FORECAST_30D as
select
    current_timestamp() as generated_at,
    ts as forecast_date,
    forecast as forecast_sales_amount,
    lower_bound as lower_bound_sales_amount,
    upper_bound as upper_bound_sales_amount
from table(
    ML.SALES_FORECAST_MODEL!FORECAST(
        FORECASTING_PERIODS => 30,
        CONFIG_OBJECT => {'prediction_interval': 0.95}
    )
);




-- Check it:

select *
from ML.SALES_FORECAST_30D
order by forecast_date;






-- Option B — Store/channel multi-series forecast model
use database RETAIL360_DEMO;
use schema ML;
use warehouse RETAIL360_ML_WH;

create or replace table ML.SALES_DAILY_STORE_CHANNEL_TRAIN_SIMPLE as
select
    to_variant(store_id || '|' || sales_channel) as series_id,
    to_timestamp_ntz(order_date) as ds,
    sum(net_sales_amount)::float as y
from RETAIL360_DEMO.MART.VW_SALES_DAILY_STORE
group by
    store_id,
    sales_channel,
    order_date
having sum(net_sales_amount) is not null
order by series_id, ds;
-- Use this only if each store/channel has enough daily rows.

create or replace SNOWFLAKE.ML.FORECAST ML.SALES_STORE_CHANNEL_FORECAST_MODEL(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.SALES_DAILY_STORE_CHANNEL_TRAIN_SIMPLE'),
    SERIES_COLNAME => 'SERIES_ID',
    TIMESTAMP_COLNAME => 'DS',
    TARGET_COLNAME => 'Y',
    CONFIG_OBJECT => {
        'frequency': '1 day',
        'method': 'best',
        'lower_bound': 0,
        'evaluate': true,
        'on_error': 'skip'
    }
);

-- For multiple time series, Snowflake supports a SERIES_COLNAME; the forecast method can forecast all trained series or a specific series value.


-- Store/channel 30-day forecast
create or replace table ML.SALES_STORE_CHANNEL_FORECAST_30D as
select
    current_timestamp() as generated_at,
    series::string as series_id,
    split_part(series::string, '|', 1)::number as store_id,
    split_part(series::string, '|', 2)::string as sales_channel,
    ts as forecast_date,
    forecast as forecast_sales_amount,
    lower_bound as lower_bound_sales_amount,
    upper_bound as upper_bound_sales_amount
from table(
    ML.SALES_STORE_CHANNEL_FORECAST_MODEL!FORECAST(
        FORECASTING_PERIODS => 30,
        CONFIG_OBJECT => {
            'prediction_interval': 0.95,
            'on_error': 'skip'
        }
    )
);

-- If this fails because your time series are too short, skip store/channel forecast and use only the overall forecast until you generate more data.

-- Part 6 — Create actual-vs-forecast mart

-- This is what your Streamlit app will chart.

create or replace view ML.VW_SALES_ACTUAL_VS_FORECAST as
select
    ds as report_date,
    y as actual_sales_amount,
    null::float as forecast_sales_amount,
    null::float as lower_bound_sales_amount,
    null::float as upper_bound_sales_amount,
    'ACTUAL' as row_type
from ML.SALES_DAILY_TRAIN

union all

select
    forecast_date as report_date,
    null::float as actual_sales_amount,
    forecast_sales_amount,
    lower_bound_sales_amount,
    upper_bound_sales_amount,
    'FORECAST' as row_type
from ML.SALES_FORECAST_30D;




-- Part 7 — Create sales anomaly input table

-- Anomaly detection is best when you train on a clean “normal” period and detect anomalies on newer data. Snowflake’s anomaly detection compares actual values against predicted ranges and returns fields like IS_ANOMALY, FORECAST, LOWER_BOUND, UPPER_BOUND, PERCENTILE, and DISTANCE.

-- For a simple demo, use the first 70% of dates for training and the latest 30% for detection.

use database RETAIL360_DEMO;
use schema ML;
use warehouse RETAIL360_ML_WH;

-- Base anomaly data: only DS and Y
create or replace table ML.SALES_ANOMALY_BASE as
select
    ds,
    y
from ML.SALES_DAILY_TRAIN_SIMPLE
where ds is not null
  and y is not null
order by ds;

-- First 70% = training/normal period
create or replace table ML.SALES_ANOMALY_TRAIN as
select ds, y
from (
    select
        ds,
        y,
        percent_rank() over (order by ds) as pct_rank
    from ML.SALES_ANOMALY_BASE
)
where pct_rank <= 0.70;

-- Latest 30% = detection period
create or replace table ML.SALES_ANOMALY_TEST as
select ds, y
from (
    select
        ds,
        y,
        percent_rank() over (order by ds) as pct_rank
    from ML.SALES_ANOMALY_BASE
)
where pct_rank > 0.70;

-- Validate split
select 'TRAIN' as dataset, count(*) as rrows, min(ds), max(ds)
from ML.SALES_ANOMALY_TRAIN
union all
select 'TEST', count(*), min(ds), max(ds)
from ML.SALES_ANOMALY_TEST;

-- Train anomaly model


-- Part 8 — Train sales anomaly detection model
create or replace SNOWFLAKE.ML.ANOMALY_DETECTION ML.SALES_ANOMALY_MODEL(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.SALES_ANOMALY_TRAIN'),
    TIMESTAMP_COLNAME => 'DS',
    TARGET_COLNAME => 'Y',
    LABEL_COLNAME => '',
    CONFIG_OBJECT => {
        'frequency': '1 day'
    }
);





-- Part 9 — Store sales anomaly results
create or replace table ML.SALES_ANOMALIES as
select
    current_timestamp() as generated_at,
    ts as anomaly_date,
    y as actual_sales_amount,
    forecast as expected_sales_amount,
    lower_bound,
    upper_bound,
    is_anomaly,
    percentile,
    distance,
    case
        when is_anomaly and y > upper_bound then 'SALES_SPIKE'
        when is_anomaly and y < lower_bound then 'SALES_DROP'
        else 'NORMAL'
    end as anomaly_type,
    case
        when abs(distance) >= 3 then 'HIGH'
        when abs(distance) >= 2 then 'MEDIUM'
        when is_anomaly then 'LOW'
        else 'NORMAL'
    end as anomaly_severity
from table(
    ML.SALES_ANOMALY_MODEL!DETECT_ANOMALIES(
        INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.SALES_ANOMALY_TEST'),
        TIMESTAMP_COLNAME => 'DS',
        TARGET_COLNAME => 'Y',
        CONFIG_OBJECT => {'prediction_interval': 0.95}
    )
);

-- Validate:

select
    count(*) as checked_days,
    count_if(is_anomaly) as anomaly_days
from ML.SALES_ANOMALIES;

select *
from ML.SALES_ANOMALIES
order by is_anomaly desc, abs(distance) desc;


-- Part 10 — Inventory anomaly detection

-- This is a strong retail use case.

-- Input
create or replace table ML.INVENTORY_ANOMALY_INPUT as
select
    to_timestamp_ntz(transaction_date) as ds,
    abs(sum(net_quantity_change))::float as y
from RETAIL360_DEMO.MART.VW_INVENTORY_MOVEMENT_DAILY
group by transaction_date
having abs(sum(net_quantity_change)) is not null
order by ds;

-- Validate:

select
    count(*) as days_count,
    min(ds),
    max(ds),
    min(y),
    max(y),
    avg(y)
from ML.INVENTORY_ANOMALY_INPUT;


-- Train/test split
create or replace table ML.INVENTORY_ANOMALY_TRAIN as
select ds, y
from (
    select
        ds,
        y,
        percent_rank() over (order by ds) as pct_rank
    from ML.INVENTORY_ANOMALY_INPUT
)
where pct_rank <= 0.70;


create or replace table ML.INVENTORY_ANOMALY_TEST as
select ds, y
from (
    select
        ds,
        y,
        percent_rank() over (order by ds) as pct_rank
    from ML.INVENTORY_ANOMALY_INPUT
)
where pct_rank > 0.70;
-- Model
create or replace SNOWFLAKE.ML.ANOMALY_DETECTION ML.INVENTORY_ANOMALY_MODEL(
    INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.INVENTORY_ANOMALY_TRAIN'),
    TIMESTAMP_COLNAME => 'DS',
    TARGET_COLNAME => 'Y',
    LABEL_COLNAME => '',
    CONFIG_OBJECT => {
        'frequency': '1 day'
    }
);
-- Results
create or replace table ML.INVENTORY_ANOMALIES as
select
    current_timestamp() as generated_at,
    ts as anomaly_date,
    y as actual_inventory_movement,
    forecast as expected_inventory_movement,
    lower_bound,
    upper_bound,
    is_anomaly,
    percentile,
    distance,
    case
        when is_anomaly and y > upper_bound then 'INVENTORY_MOVEMENT_SPIKE'
        when is_anomaly and y < lower_bound then 'INVENTORY_MOVEMENT_DROP'
        else 'NORMAL'
    end as anomaly_type,
    case
        when abs(distance) >= 3 then 'HIGH'
        when abs(distance) >= 2 then 'MEDIUM'
        when is_anomaly then 'LOW'
        else 'NORMAL'
    end as anomaly_severity
from table(
    ML.INVENTORY_ANOMALY_MODEL!DETECT_ANOMALIES(
        INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.INVENTORY_ANOMALY_TEST'),
        TIMESTAMP_COLNAME => 'DS',
        TARGET_COLNAME => 'Y',
        CONFIG_OBJECT => {'prediction_interval': 0.95}
    )
);

-- Validate:

select
    count(*) as checked_days,
    count_if(is_anomaly) as anomaly_days
from ML.INVENTORY_ANOMALIES;

select *
from ML.INVENTORY_ANOMALIES
order by is_anomaly desc, abs(distance) desc;
-- Part 11 — Customer features and segments

-- This is not ML classification yet, but it is very useful for the app.

create or replace table ML.CUSTOMER_FEATURES as
select
    customer_id,
    customer_code,
    first_name,
    last_name,
    preferred_channel,
    marketing_opt_in,
    customer_status,
    coalesce(lifetime_orders, 0) as lifetime_orders,
    coalesce(lifetime_revenue, 0) as lifetime_revenue,
    coalesce(lifetime_units, 0) as lifetime_units,
    coalesce(stores_shopped, 0) as stores_shopped,
    coalesce(unique_skus_purchased, 0) as unique_skus_purchased,
    datediff('day', last_order_date, current_date()) as days_since_last_order
from RETAIL360_DEMO.MART.VW_CUSTOMER_360
where is_current = true;


create or replace table ML.CUSTOMER_SEGMENTS as
select
    *,
    case
        when lifetime_revenue >= 1000 or lifetime_orders >= 5 then 'HIGH_VALUE'
        when lifetime_orders >= 2 then 'REPEAT_CUSTOMER'
        when lifetime_orders = 1 then 'ONE_TIME_BUYER'
        else 'NO_PURCHASE'
    end as customer_segment,
    case
        when days_since_last_order is null then 'NO_PURCHASE_HISTORY'
        when days_since_last_order > 60 then 'CHURN_RISK'
        when days_since_last_order > 30 then 'NEEDS_REENGAGEMENT'
        else 'ACTIVE_RECENT'
    end as engagement_status
from ML.CUSTOMER_FEATURES;

-- Validate:

select customer_segment, engagement_status, count(*) as customer_count
from ML.CUSTOMER_SEGMENTS
group by customer_segment, engagement_status
order by customer_count desc;


-- Part 12 — Create a single dashboard view

-- This makes Streamlit easier.

create or replace view ML.VW_AI_CONTROL_TOWER_SUMMARY as
select
    (select count(*) from ML.SALES_FORECAST_30D) as forecast_days,
    (select round(sum(forecast_sales_amount), 2) from ML.SALES_FORECAST_30D) as forecast_30d_sales,
    (select count_if(is_anomaly) from ML.SALES_ANOMALIES) as sales_anomaly_count,
    (select count_if(is_anomaly) from ML.INVENTORY_ANOMALIES) as inventory_anomaly_count,
    (select count_if(customer_segment = 'HIGH_VALUE') from ML.CUSTOMER_SEGMENTS) as high_value_customers,
    current_timestamp() as refreshed_at;

    
-- Part 13 — Automate refresh using a stored procedure

-- Create one procedure that refreshes outputs. The model objects themselves are immutable, so CREATE OR REPLACE retrains them.

create or replace procedure ML.SP_REFRESH_RETAIL360_AI()
returns string
language sql
as
$$
begin

    -- 1) Simple sales training table: ONLY DS and Y
    create or replace table ML.SALES_DAILY_TRAIN_SIMPLE as
    select
        to_timestamp_ntz(order_date) as ds,
        sum(net_sales_amount)::float as y
    from RETAIL360_DEMO.MART.VW_SALES_DAILY_STORE
    group by order_date
    having sum(net_sales_amount) is not null
    order by ds;

    -- 2) Forecast model using ONLY DS and Y
    create or replace SNOWFLAKE.ML.FORECAST ML.SALES_FORECAST_MODEL(
        INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.SALES_DAILY_TRAIN_SIMPLE'),
        TIMESTAMP_COLNAME => 'DS',
        TARGET_COLNAME => 'Y',
        CONFIG_OBJECT => {
            'frequency': '1 day',
            'method': 'best',
            'lower_bound': 0,
            'evaluate': true
        }
    );

    -- 3) Forecast output
    create or replace table ML.SALES_FORECAST_30D as
    select
        current_timestamp() as generated_at,
        ts as forecast_date,
        forecast as forecast_sales_amount,
        lower_bound as lower_bound_sales_amount,
        upper_bound as upper_bound_sales_amount
    from table(
        ML.SALES_FORECAST_MODEL!FORECAST(
            FORECASTING_PERIODS => 30,
            CONFIG_OBJECT => {'prediction_interval': 0.95}
        )
    );

    -- 4) Sales anomaly input
    create or replace table ML.SALES_ANOMALY_BASE as
    select ds, y
    from ML.SALES_DAILY_TRAIN_SIMPLE
    where y is not null
    order by ds;

    create or replace table ML.SALES_ANOMALY_TRAIN as
    select ds, y
    from (
        select
            ds,
            y,
            percent_rank() over (order by ds) as pct_rank
        from ML.SALES_ANOMALY_BASE
    )
    where pct_rank <= 0.70;

    create or replace table ML.SALES_ANOMALY_TEST as
    select ds, y
    from (
        select
            ds,
            y,
            percent_rank() over (order by ds) as pct_rank
        from ML.SALES_ANOMALY_BASE
    )
    where pct_rank > 0.70;

    -- 5) Sales anomaly model
    create or replace SNOWFLAKE.ML.ANOMALY_DETECTION ML.SALES_ANOMALY_MODEL(
        INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.SALES_ANOMALY_TRAIN'),
        TIMESTAMP_COLNAME => 'DS',
        TARGET_COLNAME => 'Y',
        LABEL_COLNAME => '',
        CONFIG_OBJECT => {'frequency': '1 day'}
    );

    -- 6) Sales anomaly output
    create or replace table ML.SALES_ANOMALIES as
    select
        current_timestamp() as generated_at,
        ts as anomaly_date,
        y as actual_sales_amount,
        forecast as expected_sales_amount,
        lower_bound,
        upper_bound,
        is_anomaly,
        percentile,
        distance,
        case
            when is_anomaly and y > upper_bound then 'SALES_SPIKE'
            when is_anomaly and y < lower_bound then 'SALES_DROP'
            else 'NORMAL'
        end as anomaly_type,
        case
            when abs(distance) >= 3 then 'HIGH'
            when abs(distance) >= 2 then 'MEDIUM'
            when is_anomaly then 'LOW'
            else 'NORMAL'
        end as anomaly_severity
    from table(
        ML.SALES_ANOMALY_MODEL!DETECT_ANOMALIES(
            INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.SALES_ANOMALY_TEST'),
            TIMESTAMP_COLNAME => 'DS',
            TARGET_COLNAME => 'Y',
            CONFIG_OBJECT => {'prediction_interval': 0.95}
        )
    );

    -- 7) Inventory anomaly input
    create or replace table ML.INVENTORY_ANOMALY_INPUT as
    select
        to_timestamp_ntz(transaction_date) as ds,
        abs(sum(net_quantity_change))::float as y
    from RETAIL360_DEMO.MART.VW_INVENTORY_MOVEMENT_DAILY
    group by transaction_date
    having abs(sum(net_quantity_change)) is not null
    order by ds;

    create or replace table ML.INVENTORY_ANOMALY_TRAIN as
    select ds, y
    from (
        select
            ds,
            y,
            percent_rank() over (order by ds) as pct_rank
        from ML.INVENTORY_ANOMALY_INPUT
    )
    where pct_rank <= 0.70;

    create or replace table ML.INVENTORY_ANOMALY_TEST as
    select ds, y
    from (
        select
            ds,
            y,
            percent_rank() over (order by ds) as pct_rank
        from ML.INVENTORY_ANOMALY_INPUT
    )
    where pct_rank > 0.70;

    create or replace SNOWFLAKE.ML.ANOMALY_DETECTION ML.INVENTORY_ANOMALY_MODEL(
        INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.INVENTORY_ANOMALY_TRAIN'),
        TIMESTAMP_COLNAME => 'DS',
        TARGET_COLNAME => 'Y',
        LABEL_COLNAME => '',
        CONFIG_OBJECT => {'frequency': '1 day'}
    );

    create or replace table ML.INVENTORY_ANOMALIES as
    select
        current_timestamp() as generated_at,
        ts as anomaly_date,
        y as actual_inventory_movement,
        forecast as expected_inventory_movement,
        lower_bound,
        upper_bound,
        is_anomaly,
        percentile,
        distance,
        case
            when is_anomaly and y > upper_bound then 'INVENTORY_MOVEMENT_SPIKE'
            when is_anomaly and y < lower_bound then 'INVENTORY_MOVEMENT_DROP'
            else 'NORMAL'
        end as anomaly_type,
        case
            when abs(distance) >= 3 then 'HIGH'
            when abs(distance) >= 2 then 'MEDIUM'
            when is_anomaly then 'LOW'
            else 'NORMAL'
        end as anomaly_severity
    from table(
        ML.INVENTORY_ANOMALY_MODEL!DETECT_ANOMALIES(
            INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'RETAIL360_DEMO.ML.INVENTORY_ANOMALY_TEST'),
            TIMESTAMP_COLNAME => 'DS',
            TARGET_COLNAME => 'Y',
            CONFIG_OBJECT => {'prediction_interval': 0.95}
        )
    );

    -- 8) Customer features
    create or replace table ML.CUSTOMER_FEATURES as
    select
        customer_id,
        customer_code,
        first_name,
        last_name,
        preferred_channel,
        marketing_opt_in,
        customer_status,
        coalesce(lifetime_orders, 0) as lifetime_orders,
        coalesce(lifetime_revenue, 0) as lifetime_revenue,
        coalesce(lifetime_units, 0) as lifetime_units,
        coalesce(stores_shopped, 0) as stores_shopped,
        coalesce(unique_skus_purchased, 0) as unique_skus_purchased,
        datediff('day', last_order_date, current_date()) as days_since_last_order
    from RETAIL360_DEMO.MART.VW_CUSTOMER_360
    where is_current = true;

    create or replace table ML.CUSTOMER_SEGMENTS as
    select
        *,
        case
            when lifetime_revenue >= 1000 or lifetime_orders >= 5 then 'HIGH_VALUE'
            when lifetime_orders >= 2 then 'REPEAT_CUSTOMER'
            when lifetime_orders = 1 then 'ONE_TIME_BUYER'
            else 'NO_PURCHASE'
        end as customer_segment,
        case
            when days_since_last_order is null then 'NO_PURCHASE_HISTORY'
            when days_since_last_order > 60 then 'CHURN_RISK'
            when days_since_last_order > 30 then 'NEEDS_REENGAGEMENT'
            else 'ACTIVE_RECENT'
        end as engagement_status
    from ML.CUSTOMER_FEATURES;

    return 'Retail360 AI refresh complete';

end;
$$;

-- Run it:

call ML.SP_REFRESH_RETAIL360_AI();


-- Part 14 — Optional task to refresh the AI layer
create or replace task ML.TSK_REFRESH_RETAIL360_AI
    warehouse = RETAIL360_ML_WH
    schedule = 'USING CRON 0 7 * * * Asia/Kolkata'
as
    call ML.SP_REFRESH_RETAIL360_AI();

alter task ML.TSK_REFRESH_RETAIL360_AI resume;

-- For a demo, you can keep it manual and run the procedure after each new batch.


