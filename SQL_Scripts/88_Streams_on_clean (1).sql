-- 1) Create CLEAN streams for CORE triggers

-- Create these after your historical bootstrap is complete and CLEAN counts are validated.

use database RETAIL360_DEMO;
use schema CLEAN;

create or replace stream STRM_CUSTOMER on table CUSTOMER;
create or replace stream STRM_STORE on table STORE;
create or replace stream STRM_PRODUCT_SKU on table PRODUCT_SKU;
create or replace stream STRM_SALES_ORDER on table SALES_ORDER;
create or replace stream STRM_SALES_ORDER_LINE on table SALES_ORDER_LINE;
create or replace stream STRM_PAYMENT on table PAYMENT;
create or replace stream STRM_INVENTORY_TRANSACTION on table INVENTORY_TRANSACTION;