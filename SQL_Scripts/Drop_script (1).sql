-- =========================================================
-- RETAIL360_DEMO FULL CLEAN / CORE / RAW RESET SCRIPT
-- Order:
--   1) Suspend tasks
--   2) Drop tasks
--   3) Drop procedures
--   4) Drop streams
--   5) Drop CORE tables
--   6) Drop CLEAN tables
--   7) Drop RAW tables
-- =========================================================

use database RETAIL360_DEMO;

-- =========================================================
-- 1) SUSPEND TASKS
-- =========================================================

use schema INGEST;

alter task if exists TSK_PROCESS_BRAND_RAW suspend;
alter task if exists TSK_PROCESS_CATEGORY_RAW suspend;
alter task if exists TSK_PROCESS_SUPPLIER_RAW suspend;
alter task if exists TSK_PROCESS_STORE_RAW suspend;
alter task if exists TSK_PROCESS_EMPLOYEE_RAW suspend;
alter task if exists TSK_PROCESS_CUSTOMER_RAW suspend;
alter task if exists TSK_PROCESS_CUSTOMER_ADDRESS_RAW suspend;
alter task if exists TSK_PROCESS_PRODUCT_RAW suspend;
alter task if exists TSK_PROCESS_PRODUCT_SKU_RAW suspend;
alter task if exists TSK_PROCESS_PROMOTION_RAW suspend;
alter task if exists TSK_PROCESS_PROMOTION_PRODUCT_RAW suspend;
alter task if exists TSK_PROCESS_PROMOTION_STORE_RAW suspend;
alter task if exists TSK_PROCESS_SALES_ORDER_RAW suspend;
alter task if exists TSK_PROCESS_SALES_ORDER_LINE_RAW suspend;
alter task if exists TSK_PROCESS_PAYMENT_RAW suspend;
alter task if exists TSK_PROCESS_SHIPMENT_RAW suspend;
alter task if exists TSK_PROCESS_RETURN_ORDER_RAW suspend;
alter task if exists TSK_PROCESS_RETURN_ORDER_LINE_RAW suspend;
alter task if exists TSK_PROCESS_PURCHASE_ORDER_RAW suspend;
alter task if exists TSK_PROCESS_PURCHASE_ORDER_LINE_RAW suspend;
alter task if exists TSK_PROCESS_INVENTORY_BALANCE_RAW suspend;
alter task if exists TSK_PROCESS_INVENTORY_TXN_RAW suspend;
alter task if exists TSK_PROCESS_CDC_RAW suspend;

use schema CORE;

alter task if exists TSK_LOAD_DIM_CUSTOMER_CORE suspend;
alter task if exists TSK_LOAD_DIM_STORE_CORE suspend;
alter task if exists TSK_LOAD_DIM_PRODUCT_SKU_CORE suspend;
alter task if exists TSK_LOAD_FACT_SALES_ORDER_CORE suspend;
alter task if exists TSK_LOAD_FACT_SALES_ORDER_LINE_CORE suspend;
alter task if exists TSK_LOAD_FACT_PAYMENT_CORE suspend;
alter task if exists TSK_LOAD_FACT_INVENTORY_TXN_CORE suspend;

-- =========================================================
-- 2) DROP TASKS
-- =========================================================

use schema INGEST;

drop task if exists TSK_PROCESS_BRAND_RAW;
drop task if exists TSK_PROCESS_CATEGORY_RAW;
drop task if exists TSK_PROCESS_SUPPLIER_RAW;
drop task if exists TSK_PROCESS_STORE_RAW;
drop task if exists TSK_PROCESS_EMPLOYEE_RAW;
drop task if exists TSK_PROCESS_CUSTOMER_RAW;
drop task if exists TSK_PROCESS_CUSTOMER_ADDRESS_RAW;
drop task if exists TSK_PROCESS_PRODUCT_RAW;
drop task if exists TSK_PROCESS_PRODUCT_SKU_RAW;
drop task if exists TSK_PROCESS_PROMOTION_RAW;
drop task if exists TSK_PROCESS_PROMOTION_PRODUCT_RAW;
drop task if exists TSK_PROCESS_PROMOTION_STORE_RAW;
drop task if exists TSK_PROCESS_SALES_ORDER_RAW;
drop task if exists TSK_PROCESS_SALES_ORDER_LINE_RAW;
drop task if exists TSK_PROCESS_PAYMENT_RAW;
drop task if exists TSK_PROCESS_SHIPMENT_RAW;
drop task if exists TSK_PROCESS_RETURN_ORDER_RAW;
drop task if exists TSK_PROCESS_RETURN_ORDER_LINE_RAW;
drop task if exists TSK_PROCESS_PURCHASE_ORDER_RAW;
drop task if exists TSK_PROCESS_PURCHASE_ORDER_LINE_RAW;
drop task if exists TSK_PROCESS_INVENTORY_BALANCE_RAW;
drop task if exists TSK_PROCESS_INVENTORY_TXN_RAW;
drop task if exists TSK_PROCESS_CDC_RAW;

use schema CORE;

drop task if exists TSK_LOAD_DIM_CUSTOMER_CORE;
drop task if exists TSK_LOAD_DIM_STORE_CORE;
drop task if exists TSK_LOAD_DIM_PRODUCT_SKU_CORE;
drop task if exists TSK_LOAD_FACT_SALES_ORDER_CORE;
drop task if exists TSK_LOAD_FACT_SALES_ORDER_LINE_CORE;
drop task if exists TSK_LOAD_FACT_PAYMENT_CORE;
drop task if exists TSK_LOAD_FACT_INVENTORY_TXN_CORE;

-- =========================================================
-- 3) DROP PROCEDURES
-- =========================================================

use schema CORE;

drop procedure if exists SP_LOAD_DIM_CUSTOMER_SCD2();
drop procedure if exists SP_LOAD_DIM_STORE_SCD2();
drop procedure if exists SP_LOAD_DIM_PRODUCT_SKU_SCD2();
drop procedure if exists SP_LOAD_FACT_SALES_ORDER();
drop procedure if exists SP_LOAD_FACT_SALES_ORDER_LINE();
drop procedure if exists SP_LOAD_FACT_PAYMENT();
drop procedure if exists SP_LOAD_FACT_INVENTORY_TRANSACTION();
drop procedure if exists SP_LOAD_CORE_ALL();

use schema CLEAN;

drop procedure if exists SP_PROCESS_BRAND_STREAM();
drop procedure if exists SP_PROCESS_CATEGORY_STREAM();
drop procedure if exists SP_PROCESS_SUPPLIER_STREAM();
drop procedure if exists SP_PROCESS_STORE_STREAM();
drop procedure if exists SP_PROCESS_EMPLOYEE_STREAM();
drop procedure if exists SP_PROCESS_CUSTOMER_STREAM();
drop procedure if exists SP_PROCESS_CUSTOMER_ADDRESS_STREAM();
drop procedure if exists SP_PROCESS_PRODUCT_STREAM();
drop procedure if exists SP_PROCESS_PRODUCT_SKU_STREAM();
drop procedure if exists SP_PROCESS_PROMOTION_STREAM();
drop procedure if exists SP_PROCESS_PROMOTION_PRODUCT_STREAM();
drop procedure if exists SP_PROCESS_PROMOTION_STORE_STREAM();
drop procedure if exists SP_PROCESS_SALES_ORDER_STREAM();
drop procedure if exists SP_PROCESS_SALES_ORDER_LINE_STREAM();
drop procedure if exists SP_PROCESS_PAYMENT_STREAM();
drop procedure if exists SP_PROCESS_SHIPMENT_STREAM();
drop procedure if exists SP_PROCESS_RETURN_ORDER_STREAM();
drop procedure if exists SP_PROCESS_RETURN_ORDER_LINE_STREAM();
drop procedure if exists SP_PROCESS_PURCHASE_ORDER_STREAM();
drop procedure if exists SP_PROCESS_PURCHASE_ORDER_LINE_STREAM();
drop procedure if exists SP_PROCESS_INVENTORY_BALANCE_STREAM();
drop procedure if exists SP_PROCESS_INVENTORY_TRANSACTION_STREAM();
drop procedure if exists SP_PROCESS_CDC_EVENTS_STREAM();

-- =========================================================
-- 4) DROP STREAMS
-- =========================================================

use schema CLEAN;

drop stream if exists STRM_CUSTOMER;
drop stream if exists STRM_STORE;
drop stream if exists STRM_PRODUCT_SKU;
drop stream if exists STRM_SALES_ORDER;
drop stream if exists STRM_SALES_ORDER_LINE;
drop stream if exists STRM_PAYMENT;
drop stream if exists STRM_INVENTORY_TRANSACTION;

use schema RAW;

drop stream if exists STRM_BRAND_SRC;
drop stream if exists STRM_CATEGORY_SRC;
drop stream if exists STRM_SUPPLIER_SRC;
drop stream if exists STRM_STORE_SRC;
drop stream if exists STRM_EMPLOYEE_SRC;
drop stream if exists STRM_CUSTOMER_SRC;
drop stream if exists STRM_CUSTOMER_ADDRESS_SRC;
drop stream if exists STRM_PRODUCT_SRC;
drop stream if exists STRM_PRODUCT_SKU_SRC;
drop stream if exists STRM_PROMOTION_SRC;
drop stream if exists STRM_PROMOTION_PRODUCT_SRC;
drop stream if exists STRM_PROMOTION_STORE_SRC;
drop stream if exists STRM_SALES_ORDER_SRC;
drop stream if exists STRM_SALES_ORDER_LINE_SRC;
drop stream if exists STRM_PAYMENT_SRC;
drop stream if exists STRM_SHIPMENT_SRC;
drop stream if exists STRM_RETURN_ORDER_SRC;
drop stream if exists STRM_RETURN_ORDER_LINE_SRC;
drop stream if exists STRM_PURCHASE_ORDER_SRC;
drop stream if exists STRM_PURCHASE_ORDER_LINE_SRC;
drop stream if exists STRM_INVENTORY_BALANCE_SRC;
drop stream if exists STRM_INVENTORY_TRANSACTION_SRC;
drop stream if exists STRM_CDC_EVENTS_SRC;

-- =========================================================
-- 5) DROP CORE TABLES
-- =========================================================

use schema CORE;

drop table if exists FACT_INVENTORY_TRANSACTION;
drop table if exists FACT_PAYMENT;
drop table if exists FACT_SALES_ORDER_LINE;
drop table if exists FACT_SALES_ORDER;

drop table if exists DIM_PRODUCT_SKU_SCD2;
drop table if exists DIM_STORE_SCD2;
drop table if exists DIM_CUSTOMER_SCD2;

drop table if exists LOAD_COUNT_SNAPSHOT;

-- =========================================================
-- 6) DROP CLEAN TABLES
-- =========================================================

use schema CLEAN;

drop table if exists BRAND_REJECT;
drop table if exists BRAND;

drop table if exists CATEGORY_REJECT;
drop table if exists CATEGORY;

drop table if exists SUPPLIER_REJECT;
drop table if exists SUPPLIER;

drop table if exists STORE_REJECT;
drop table if exists STORE;

drop table if exists EMPLOYEE_REJECT;
drop table if exists EMPLOYEE;

drop table if exists CUSTOMER_REJECT;
drop table if exists CUSTOMER;

drop table if exists CUSTOMER_ADDRESS_REJECT;
drop table if exists CUSTOMER_ADDRESS;

drop table if exists PRODUCT_REJECT;
drop table if exists PRODUCT;

drop table if exists PRODUCT_SKU_REJECT;
drop table if exists PRODUCT_SKU;

drop table if exists PROMOTION_REJECT;
drop table if exists PROMOTION;

drop table if exists PROMOTION_PRODUCT_REJECT;
drop table if exists PROMOTION_PRODUCT;

drop table if exists PROMOTION_STORE_REJECT;
drop table if exists PROMOTION_STORE;

drop table if exists SALES_ORDER_REJECT;
drop table if exists SALES_ORDER;

drop table if exists SALES_ORDER_LINE_REJECT;
drop table if exists SALES_ORDER_LINE;

drop table if exists PAYMENT_REJECT;
drop table if exists PAYMENT;

drop table if exists SHIPMENT_REJECT;
drop table if exists SHIPMENT;

drop table if exists RETURN_ORDER_REJECT;
drop table if exists RETURN_ORDER;

drop table if exists RETURN_ORDER_LINE_REJECT;
drop table if exists RETURN_ORDER_LINE;

drop table if exists PURCHASE_ORDER_REJECT;
drop table if exists PURCHASE_ORDER;

drop table if exists PURCHASE_ORDER_LINE_REJECT;
drop table if exists PURCHASE_ORDER_LINE;

drop table if exists INVENTORY_BALANCE_REJECT;
drop table if exists INVENTORY_BALANCE;

drop table if exists INVENTORY_TRANSACTION_REJECT;
drop table if exists INVENTORY_TRANSACTION;

drop table if exists CDC_EVENTS_REJECT;
drop table if exists CDC_EVENTS;

-- =========================================================
-- 7) DROP RAW TABLES
-- =========================================================

use schema RAW;

drop table if exists BRAND_SRC;
drop table if exists CATEGORY_SRC;
drop table if exists SUPPLIER_SRC;
drop table if exists STORE_SRC;
drop table if exists EMPLOYEE_SRC;
drop table if exists CUSTOMER_SRC;
drop table if exists CUSTOMER_ADDRESS_SRC;
drop table if exists PRODUCT_SRC;
drop table if exists PRODUCT_SKU_SRC;
drop table if exists PROMOTION_SRC;
drop table if exists PROMOTION_PRODUCT_SRC;
drop table if exists PROMOTION_STORE_SRC;
drop table if exists SALES_ORDER_SRC;
drop table if exists SALES_ORDER_LINE_SRC;
drop table if exists PAYMENT_SRC;
drop table if exists SHIPMENT_SRC;
drop table if exists RETURN_ORDER_SRC;
drop table if exists RETURN_ORDER_LINE_SRC;
drop table if exists PURCHASE_ORDER_SRC;
drop table if exists PURCHASE_ORDER_LINE_SRC;
drop table if exists INVENTORY_BALANCE_SRC;
drop table if exists INVENTORY_TRANSACTION_SRC;
drop table if exists CDC_EVENTS_SRC;
drop table if exists RAW_REJECT_LOG;