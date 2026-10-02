use database RETAIL360_DEMO;
use schema CLEAN;

create or replace table BRAND as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.BRAND_SRC r
where 1=0;


create or replace table BRAND_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.BRAND_SRC r
where 1=0;

create or replace table CATEGORY as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.CATEGORY_SRC r
where 1=0;

create or replace table CATEGORY_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.CATEGORY_SRC r
where 1=0;

create or replace table SUPPLIER as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.SUPPLIER_SRC r
where 1=0;

create or replace table SUPPLIER_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.SUPPLIER_SRC r
where 1=0;

create or replace table STORE as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.STORE_SRC r
where 1=0;

create or replace table STORE_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.STORE_SRC r
where 1=0;

create or replace table EMPLOYEE as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.EMPLOYEE_SRC r
where 1=0;

create or replace table EMPLOYEE_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.EMPLOYEE_SRC r
where 1=0;

create or replace table CUSTOMER as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.CUSTOMER_SRC r
where 1=0;

create or replace table CUSTOMER_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.CUSTOMER_SRC r
where 1=0;

create or replace table CUSTOMER_ADDRESS as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.CUSTOMER_ADDRESS_SRC r
where 1=0;

create or replace table CUSTOMER_ADDRESS_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.CUSTOMER_ADDRESS_SRC r
where 1=0;

create or replace table PRODUCT as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.PRODUCT_SRC r
where 1=0;

create or replace table PRODUCT_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.PRODUCT_SRC r
where 1=0;

create or replace table PRODUCT_SKU as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.PRODUCT_SKU_SRC r
where 1=0;

create or replace table PRODUCT_SKU_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.PRODUCT_SKU_SRC r
where 1=0;

create or replace table PROMOTION as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.PROMOTION_SRC r
where 1=0;

create or replace table PROMOTION_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.PROMOTION_SRC r
where 1=0;

create or replace table PROMOTION_PRODUCT as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.PROMOTION_PRODUCT_SRC r
where 1=0;

create or replace table PROMOTION_PRODUCT_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.PROMOTION_PRODUCT_SRC r
where 1=0;

create or replace table PROMOTION_STORE as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.PROMOTION_STORE_SRC r
where 1=0;

create or replace table PROMOTION_STORE_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.PROMOTION_STORE_SRC r
where 1=0;

create or replace table SALES_ORDER as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.SALES_ORDER_SRC r
where 1=0;

create or replace table SALES_ORDER_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.SALES_ORDER_SRC r
where 1=0;

create or replace table SALES_ORDER_LINE as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.SALES_ORDER_LINE_SRC r
where 1=0;

create or replace table SALES_ORDER_LINE_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.SALES_ORDER_LINE_SRC r
where 1=0;

create or replace table PAYMENT as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.PAYMENT_SRC r
where 1=0;

create or replace table PAYMENT_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.PAYMENT_SRC r
where 1=0;

create or replace table SHIPMENT as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.SHIPMENT_SRC r
where 1=0;

create or replace table SHIPMENT_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.SHIPMENT_SRC r
where 1=0;

create or replace table RETURN_ORDER as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.RETURN_ORDER_SRC r
where 1=0;

create or replace table RETURN_ORDER_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.RETURN_ORDER_SRC r
where 1=0;

create or replace table RETURN_ORDER_LINE as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.RETURN_ORDER_LINE_SRC r
where 1=0;

create or replace table RETURN_ORDER_LINE_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.RETURN_ORDER_LINE_SRC r
where 1=0;

create or replace table PURCHASE_ORDER as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.PURCHASE_ORDER_SRC r
where 1=0;

create or replace table PURCHASE_ORDER_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.PURCHASE_ORDER_SRC r
where 1=0;

create or replace table PURCHASE_ORDER_LINE as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.PURCHASE_ORDER_LINE_SRC r
where 1=0;

create or replace table PURCHASE_ORDER_LINE_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.PURCHASE_ORDER_LINE_SRC r
where 1=0;

create or replace table INVENTORY_BALANCE as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.INVENTORY_BALANCE_SRC r
where 1=0;

create or replace table INVENTORY_BALANCE_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.INVENTORY_BALANCE_SRC r
where 1=0;

create or replace table INVENTORY_TRANSACTION as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.INVENTORY_TRANSACTION_SRC r
where 1=0;

create or replace table INVENTORY_TRANSACTION_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.INVENTORY_TRANSACTION_SRC r
where 1=0;

create or replace table CDC_EVENTS as
select r.*, current_timestamp()::timestamp_ntz as cleaned_at
from RAW.CDC_EVENTS_SRC r
where 1=0;

create or replace table CDC_EVENTS_REJECT as
select r.*, cast(null as string) as reject_reason, current_timestamp()::timestamp_ntz as rejected_at
from RAW.CDC_EVENTS_SRC r
where 1=0;





-- ------------------------------
-- use database RETAIL360_DEMO;
-- use schema CLEAN;

-- -- =========================
-- -- MASTER TABLES
-- -- =========================
-- truncate table if exists BRAND;
-- truncate table if exists BRAND_REJECT;

-- truncate table if exists CATEGORY;
-- truncate table if exists CATEGORY_REJECT;

-- truncate table if exists SUPPLIER;
-- truncate table if exists SUPPLIER_REJECT;

-- truncate table if exists STORE;
-- truncate table if exists STORE_REJECT;

-- truncate table if exists EMPLOYEE;
-- truncate table if exists EMPLOYEE_REJECT;

-- truncate table if exists CUSTOMER;
-- truncate table if exists CUSTOMER_REJECT;

-- truncate table if exists CUSTOMER_ADDRESS;
-- truncate table if exists CUSTOMER_ADDRESS_REJECT;

-- truncate table if exists PRODUCT;
-- truncate table if exists PRODUCT_REJECT;

-- truncate table if exists PRODUCT_SKU;
-- truncate table if exists PRODUCT_SKU_REJECT;

-- truncate table if exists PROMOTION;
-- truncate table if exists PROMOTION_REJECT;

-- truncate table if exists PROMOTION_PRODUCT;
-- truncate table if exists PROMOTION_PRODUCT_REJECT;

-- truncate table if exists PROMOTION_STORE;
-- truncate table if exists PROMOTION_STORE_REJECT;

-- -- =========================
-- -- TRANSACTION TABLES
-- -- =========================
-- truncate table if exists SALES_ORDER;
-- truncate table if exists SALES_ORDER_REJECT;

-- -- truncate table if exists SALES_ORDER_LINE;
-- -- truncate table if exists SALES_ORDER_LINE_REJECT;

-- -- truncate table if exists PAYMENT;
-- -- truncate table if exists PAYMENT_REJECT;

-- -- truncate table if exists SHIPMENT;
-- -- truncate table if exists SHIPMENT_REJECT;

-- truncate table if exists RETURN_ORDER;
-- truncate table if exists RETURN_ORDER_REJECT;

-- truncate table if exists RETURN_ORDER_LINE;
-- truncate table if exists RETURN_ORDER_LINE_REJECT;

-- truncate table if exists PURCHASE_ORDER;
-- truncate table if exists PURCHASE_ORDER_REJECT;

-- truncate table if exists PURCHASE_ORDER_LINE;
-- truncate table if exists PURCHASE_ORDER_LINE_REJECT;

-- truncate table if exists INVENTORY_BALANCE;
-- truncate table if exists INVENTORY_BALANCE_REJECT;

-- truncate table if exists INVENTORY_TRANSACTION;
-- truncate table if exists INVENTORY_TRANSACTION_REJECT;

-- -- =========================
-- -- CDC TABLES
-- -- =========================
-- truncate table if exists CDC_EVENTS;
-- truncate table if exists CDC_EVENTS_REJECT;


-- delete from RETAIL360_DEMO.RAW.RAW_REJECT_LOG
-- where table_name = 'BRAND';








-- use database RETAIL360_DEMO;
-- use schema CLEAN;

-- select 'BRAND' as table_name, count(*) as row_count from BRAND
-- union all
-- select 'BRAND_REJECT', count(*) from BRAND_REJECT
-- union all
-- select 'CATEGORY', count(*) from CATEGORY
-- union all
-- select 'CATEGORY_REJECT', count(*) from CATEGORY_REJECT
-- union all
-- select 'SUPPLIER', count(*) from SUPPLIER
-- union all
-- select 'SUPPLIER_REJECT', count(*) from SUPPLIER_REJECT
-- union all
-- select 'STORE', count(*) from STORE
-- union all
-- select 'STORE_REJECT', count(*) from STORE_REJECT
-- union all
-- select 'EMPLOYEE', count(*) from EMPLOYEE
-- union all
-- select 'EMPLOYEE_REJECT', count(*) from EMPLOYEE_REJECT
-- union all
-- select 'CUSTOMER', count(*) from CUSTOMER
-- union all
-- select 'CUSTOMER_REJECT', count(*) from CUSTOMER_REJECT
-- union all
-- select 'CUSTOMER_ADDRESS', count(*) from CUSTOMER_ADDRESS
-- union all
-- select 'CUSTOMER_ADDRESS_REJECT', count(*) from CUSTOMER_ADDRESS_REJECT
-- union all
-- select 'PRODUCT', count(*) from PRODUCT
-- union all
-- select 'PRODUCT_REJECT', count(*) from PRODUCT_REJECT
-- union all
-- select 'PRODUCT_SKU', count(*) from PRODUCT_SKU
-- union all
-- select 'PRODUCT_SKU_REJECT', count(*) from PRODUCT_SKU_REJECT
-- union all
-- select 'PROMOTION', count(*) from PROMOTION
-- union all
-- select 'PROMOTION_REJECT', count(*) from PROMOTION_REJECT
-- union all
-- select 'PROMOTION_PRODUCT', count(*) from PROMOTION_PRODUCT
-- union all
-- select 'PROMOTION_PRODUCT_REJECT', count(*) from PROMOTION_PRODUCT_REJECT
-- union all
-- select 'PROMOTION_STORE', count(*) from PROMOTION_STORE
-- union all
-- select 'PROMOTION_STORE_REJECT', count(*) from PROMOTION_STORE_REJECT
-- union all
-- select 'SALES_ORDER', count(*) from SALES_ORDER
-- union all
-- select 'SALES_ORDER_REJECT', count(*) from SALES_ORDER_REJECT
-- union all
-- select 'SALES_ORDER_LINE', count(*) from SALES_ORDER_LINE
-- union all
-- select 'SALES_ORDER_LINE_REJECT', count(*) from SALES_ORDER_LINE_REJECT
-- union all
-- select 'PAYMENT', count(*) from PAYMENT
-- union all
-- select 'PAYMENT_REJECT', count(*) from PAYMENT_REJECT
-- union all
-- select 'SHIPMENT', count(*) from SHIPMENT
-- union all
-- select 'SHIPMENT_REJECT', count(*) from SHIPMENT_REJECT
-- union all
-- select 'RETURN_ORDER', count(*) from RETURN_ORDER
-- union all
-- select 'RETURN_ORDER_REJECT', count(*) from RETURN_ORDER_REJECT
-- union all
-- select 'RETURN_ORDER_LINE', count(*) from RETURN_ORDER_LINE
-- union all
-- select 'RETURN_ORDER_LINE_REJECT', count(*) from RETURN_ORDER_LINE_REJECT
-- union all
-- select 'PURCHASE_ORDER', count(*) from PURCHASE_ORDER
-- union all
-- select 'PURCHASE_ORDER_REJECT', count(*) from PURCHASE_ORDER_REJECT
-- union all
-- select 'PURCHASE_ORDER_LINE', count(*) from PURCHASE_ORDER_LINE
-- union all
-- select 'PURCHASE_ORDER_LINE_REJECT', count(*) from PURCHASE_ORDER_LINE_REJECT
-- union all
-- select 'INVENTORY_BALANCE', count(*) from INVENTORY_BALANCE
-- union all
-- select 'INVENTORY_BALANCE_REJECT', count(*) from INVENTORY_BALANCE_REJECT
-- union all
-- select 'INVENTORY_TRANSACTION', count(*) from INVENTORY_TRANSACTION
-- union all
-- select 'INVENTORY_TRANSACTION_REJECT', count(*) from INVENTORY_TRANSACTION_REJECT
-- union all
-- select 'CDC_EVENTS', count(*) from CDC_EVENTS
-- union all
-- select 'CDC_EVENTS_REJECT', count(*) from CDC_EVENTS_REJECT
-- order by table_name;





-- select 'SALES_ORDER_SRC' as src_table, count(*) from RAW.SALES_ORDER_SRC
-- union all
-- select 'SALES_ORDER', count(*) from CLEAN.SALES_ORDER
-- union all
-- select 'SALES_ORDER_REJECT', count(*) from CLEAN.SALES_ORDER_REJECT
-- union all
-- select 'RETURN_ORDER_SRC', count(*) from RAW.RETURN_ORDER_SRC
-- union all
-- select 'RETURN_ORDER', count(*) from CLEAN.RETURN_ORDER
-- union all
-- select 'RETURN_ORDER_REJECT', count(*) from CLEAN.RETURN_ORDER_REJECT;


-- select 'SALES_ORDER' as table_name,
--        (select count(*) from RAW.SALES_ORDER_SRC) as raw_count,
--        (select count(*) from CLEAN.SALES_ORDER) as clean_count,
--        (select count(*) from CLEAN.SALES_ORDER_REJECT) as reject_count,
--        (select count(*) from RAW.SALES_ORDER_SRC)
--        - (
--            (select count(*) from CLEAN.SALES_ORDER)
--            + (select count(*) from CLEAN.SALES_ORDER_REJECT)
--          ) as missing_count
-- union all
-- select 'RETURN_ORDER',
--        (select count(*) from RAW.RETURN_ORDER_SRC),
--        (select count(*) from CLEAN.RETURN_ORDER),
--        (select count(*) from CLEAN.RETURN_ORDER_REJECT),
--        (select count(*) from RAW.RETURN_ORDER_SRC)
--        - (
--            (select count(*) from CLEAN.RETURN_ORDER)
--            + (select count(*) from CLEAN.RETURN_ORDER_REJECT)
--          );


select * from clean.customer;

DESCRIBE table clean.customer;
--23
select * from raw.category_src;


DESCRIBE TABLE raw.category_src;
--15
DESCRIBE TABLE raw.customer_address_src;
--20

