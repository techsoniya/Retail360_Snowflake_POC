-- 3) Baseline count script before incremental load

-- Run this before uploading new files.

use database RETAIL360_DEMO;
-- RAW counts



select 'RAW' as layer, 'BRAND_SRC' as object_name, count(*) as row_count from RAW.BRAND_SRC
union all
select 'RAW', 'CATEGORY_SRC', count(*) from RAW.CATEGORY_SRC
union all
select 'RAW', 'SUPPLIER_SRC', count(*) from RAW.SUPPLIER_SRC
union all
select 'RAW', 'STORE_SRC', count(*) from RAW.STORE_SRC
union all
select 'RAW', 'EMPLOYEE_SRC', count(*) from RAW.EMPLOYEE_SRC
union all
select 'RAW', 'CUSTOMER_SRC', count(*) from RAW.CUSTOMER_SRC
union all
select 'RAW', 'CUSTOMER_ADDRESS_SRC', count(*) from RAW.CUSTOMER_ADDRESS_SRC
union all
select 'RAW', 'PRODUCT_SRC', count(*) from RAW.PRODUCT_SRC
union all
select 'RAW', 'PRODUCT_SKU_SRC', count(*) from RAW.PRODUCT_SKU_SRC
union all
select 'RAW', 'PROMOTION_SRC', count(*) from RAW.PROMOTION_SRC
union all
select 'RAW', 'PROMOTION_PRODUCT_SRC', count(*) from RAW.PROMOTION_PRODUCT_SRC
union all
select 'RAW', 'PROMOTION_STORE_SRC', count(*) from RAW.PROMOTION_STORE_SRC
union all
select 'RAW', 'SALES_ORDER_SRC', count(*) from RAW.SALES_ORDER_SRC
union all
select 'RAW', 'SALES_ORDER_LINE_SRC', count(*) from RAW.SALES_ORDER_LINE_SRC
union all
select 'RAW', 'PAYMENT_SRC', count(*) from RAW.PAYMENT_SRC
union all
select 'RAW', 'SHIPMENT_SRC', count(*) from RAW.SHIPMENT_SRC
union all
select 'RAW', 'RETURN_ORDER_SRC', count(*) from RAW.RETURN_ORDER_SRC
union all
select 'RAW', 'RETURN_ORDER_LINE_SRC', count(*) from RAW.RETURN_ORDER_LINE_SRC
union all
select 'RAW', 'PURCHASE_ORDER_SRC', count(*) from RAW.PURCHASE_ORDER_SRC
union all
select 'RAW', 'PURCHASE_ORDER_LINE_SRC', count(*) from RAW.PURCHASE_ORDER_LINE_SRC
union all
select 'RAW', 'INVENTORY_BALANCE_SRC', count(*) from RAW.INVENTORY_BALANCE_SRC
union all
select 'RAW', 'INVENTORY_TRANSACTION_SRC', count(*) from RAW.INVENTORY_TRANSACTION_SRC
union all
select 'RAW', 'CDC_EVENTS_SRC', count(*) from RAW.CDC_EVENTS_SRC
union all
select 'RAW', 'RAW_REJECT_LOG', count(*) from RAW.RAW_REJECT_LOG
order by layer, object_name;



-- CLEAN counts


select 'CLEAN' as layer, 'CUSTOMER' as object_name, count(*) as row_count from CLEAN.CUSTOMER
union all
select 'CLEAN', 'CUSTOMER_REJECT', count(*) from CLEAN.CUSTOMER_REJECT
union all
select 'CLEAN', 'STORE', count(*) from CLEAN.STORE
union all
select 'CLEAN', 'STORE_REJECT', count(*) from CLEAN.STORE_REJECT
union all
select 'CLEAN', 'PRODUCT_SKU', count(*) from CLEAN.PRODUCT_SKU
union all
select 'CLEAN', 'PRODUCT_SKU_REJECT', count(*) from CLEAN.PRODUCT_SKU_REJECT
union all
select 'CLEAN', 'SALES_ORDER', count(*) from CLEAN.SALES_ORDER
union all
select 'CLEAN', 'SALES_ORDER_REJECT', count(*) from CLEAN.SALES_ORDER_REJECT
union all
select 'CLEAN', 'SALES_ORDER_LINE', count(*) from CLEAN.SALES_ORDER_LINE
union all
select 'CLEAN', 'SALES_ORDER_LINE_REJECT', count(*) from CLEAN.SALES_ORDER_LINE_REJECT
union all
select 'CLEAN', 'PAYMENT', count(*) from CLEAN.PAYMENT
union all
select 'CLEAN', 'PAYMENT_REJECT', count(*) from CLEAN.PAYMENT_REJECT
union all
select 'CLEAN', 'INVENTORY_TRANSACTION', count(*) from CLEAN.INVENTORY_TRANSACTION
union all
select 'CLEAN', 'INVENTORY_TRANSACTION_REJECT', count(*) from CLEAN.INVENTORY_TRANSACTION_REJECT
union all
select 'CLEAN', 'CDC_EVENTS', count(*) from CLEAN.CDC_EVENTS
union all
select 'CLEAN', 'CDC_EVENTS_REJECT', count(*) from CLEAN.CDC_EVENTS_REJECT
order by layer, object_name;




-- CORE counts



select 'CORE' as layer, 'DIM_CUSTOMER_SCD2_TOTAL' as object_name, count(*) as row_count from CORE.DIM_CUSTOMER_SCD2
union all
select 'CORE', 'DIM_CUSTOMER_SCD2_CURRENT', count(*) from CORE.DIM_CUSTOMER_SCD2 where is_current = true
union all
select 'CORE', 'DIM_STORE_SCD2_TOTAL', count(*) from CORE.DIM_STORE_SCD2
union all
select 'CORE', 'DIM_STORE_SCD2_CURRENT', count(*) from CORE.DIM_STORE_SCD2 where is_current = true
union all
select 'CORE', 'DIM_PRODUCT_SKU_SCD2_TOTAL', count(*) from CORE.DIM_PRODUCT_SKU_SCD2
union all
select 'CORE', 'DIM_PRODUCT_SKU_SCD2_CURRENT', count(*) from CORE.DIM_PRODUCT_SKU_SCD2 where is_current = true
union all
select 'CORE', 'FACT_SALES_ORDER', count(*) from CORE.FACT_SALES_ORDER
union all
select 'CORE', 'FACT_SALES_ORDER_LINE', count(*) from CORE.FACT_SALES_ORDER_LINE
union all
select 'CORE', 'FACT_PAYMENT', count(*) from CORE.FACT_PAYMENT
union all
select 'CORE', 'FACT_INVENTORY_TRANSACTION', count(*) from CORE.FACT_INVENTORY_TRANSACTION
order by layer, object_name;


-- 4) Even better: save before-counts into snapshot tables

-- This is much better than just copying query output.

-- Create audit table
use database RETAIL360_DEMO;
use schema CORE;

create or replace table CORE.LOAD_COUNT_SNAPSHOT (
    batch_id         string,
    snapshot_type    string,   -- BEFORE / AFTER
    layer            string,
    object_name      string,
    row_count        number,
    captured_at      timestamp_ntz default current_timestamp()
);

select * from load_count_snapshot;

create or replace procedure CORE.SP_CAPTURE_LOAD_COUNTS(
    P_BATCH_ID string,
    P_SNAPSHOT_TYPE string
)
returns string
language sql
as
$$
BEGIN

    insert into CORE.LOAD_COUNT_SNAPSHOT
    (batch_id, snapshot_type, layer, object_name, row_count)

    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'RAW', 'CUSTOMER_SRC', count(*) from RAW.CUSTOMER_SRC
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'RAW', 'STORE_SRC', count(*) from RAW.STORE_SRC
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'RAW', 'PRODUCT_SKU_SRC', count(*) from RAW.PRODUCT_SKU_SRC
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'RAW', 'SALES_ORDER_SRC', count(*) from RAW.SALES_ORDER_SRC
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'RAW', 'SALES_ORDER_LINE_SRC', count(*) from RAW.SALES_ORDER_LINE_SRC
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'RAW', 'PAYMENT_SRC', count(*) from RAW.PAYMENT_SRC
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'RAW', 'INVENTORY_TRANSACTION_SRC', count(*) from RAW.INVENTORY_TRANSACTION_SRC
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'RAW', 'CDC_EVENTS_SRC', count(*) from RAW.CDC_EVENTS_SRC
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'CUSTOMER', count(*) from CLEAN.CUSTOMER
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'CUSTOMER_REJECT', count(*) from CLEAN.CUSTOMER_REJECT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'STORE', count(*) from CLEAN.STORE
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'STORE_REJECT', count(*) from CLEAN.STORE_REJECT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'PRODUCT_SKU', count(*) from CLEAN.PRODUCT_SKU
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'PRODUCT_SKU_REJECT', count(*) from CLEAN.PRODUCT_SKU_REJECT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'SALES_ORDER', count(*) from CLEAN.SALES_ORDER
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'SALES_ORDER_REJECT', count(*) from CLEAN.SALES_ORDER_REJECT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'SALES_ORDER_LINE', count(*) from CLEAN.SALES_ORDER_LINE
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'SALES_ORDER_LINE_REJECT', count(*) from CLEAN.SALES_ORDER_LINE_REJECT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'PAYMENT', count(*) from CLEAN.PAYMENT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'PAYMENT_REJECT', count(*) from CLEAN.PAYMENT_REJECT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'INVENTORY_TRANSACTION', count(*) from CLEAN.INVENTORY_TRANSACTION
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'INVENTORY_TRANSACTION_REJECT', count(*) from CLEAN.INVENTORY_TRANSACTION_REJECT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'CDC_EVENTS', count(*) from CLEAN.CDC_EVENTS
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CLEAN', 'CDC_EVENTS_REJECT', count(*) from CLEAN.CDC_EVENTS_REJECT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'DIM_CUSTOMER_SCD2_TOTAL', count(*) from CORE.DIM_CUSTOMER_SCD2
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'DIM_CUSTOMER_SCD2_CURRENT', count(*) from CORE.DIM_CUSTOMER_SCD2 where is_current = true
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'DIM_STORE_SCD2_TOTAL', count(*) from CORE.DIM_STORE_SCD2
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'DIM_STORE_SCD2_CURRENT', count(*) from CORE.DIM_STORE_SCD2 where is_current = true
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'DIM_PRODUCT_SKU_SCD2_TOTAL', count(*) from CORE.DIM_PRODUCT_SKU_SCD2
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'DIM_PRODUCT_SKU_SCD2_CURRENT', count(*) from CORE.DIM_PRODUCT_SKU_SCD2 where is_current = true
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'FACT_SALES_ORDER', count(*) from CORE.FACT_SALES_ORDER
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'FACT_SALES_ORDER_LINE', count(*) from CORE.FACT_SALES_ORDER_LINE
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'FACT_PAYMENT', count(*) from CORE.FACT_PAYMENT
    union all
    select P_BATCH_ID, P_SNAPSHOT_TYPE, 'CORE', 'FACT_INVENTORY_TRANSACTION', count(*) from CORE.FACT_INVENTORY_TRANSACTION;

    RETURN 'SNAPSHOT CAPTURED';

END;
$$;


call CORE.SP_CAPTURE_LOAD_COUNTS('BATCH_00001', 'BEFORE');
call CORE.SP_CAPTURE_LOAD_COUNTS('BATCH_00001', 'AFTER');

