-- Streams on all RAW tables
--Streams record DML changes on tables, including rows inserted by COPY INTO, so they are exactly what you want between RAW and downstream processing.

use database RETAIL360_DEMO;
use schema RAW;

create or replace stream STRM_BRAND_SRC on table BRAND_SRC;
create or replace stream STRM_CATEGORY_SRC on table CATEGORY_SRC;
create or replace stream STRM_SUPPLIER_SRC on table SUPPLIER_SRC;
create or replace stream STRM_STORE_SRC on table STORE_SRC;
create or replace stream STRM_EMPLOYEE_SRC on table EMPLOYEE_SRC;
create or replace stream STRM_CUSTOMER_SRC on table CUSTOMER_SRC;
create or replace stream STRM_CUSTOMER_ADDRESS_SRC on table CUSTOMER_ADDRESS_SRC;
create or replace stream STRM_PRODUCT_SRC on table PRODUCT_SRC;
create or replace stream STRM_PRODUCT_SKU_SRC on table PRODUCT_SKU_SRC;
create or replace stream STRM_PROMOTION_SRC on table PROMOTION_SRC;
create or replace stream STRM_PROMOTION_PRODUCT_SRC on table PROMOTION_PRODUCT_SRC;
create or replace stream STRM_PROMOTION_STORE_SRC on table PROMOTION_STORE_SRC;
create or replace stream STRM_SALES_ORDER_SRC on table SALES_ORDER_SRC;
create or replace stream STRM_SALES_ORDER_LINE_SRC on table SALES_ORDER_LINE_SRC;
create or replace stream STRM_PAYMENT_SRC on table PAYMENT_SRC;
create or replace stream STRM_SHIPMENT_SRC on table SHIPMENT_SRC;
create or replace stream STRM_RETURN_ORDER_SRC on table RETURN_ORDER_SRC;
create or replace stream STRM_RETURN_ORDER_LINE_SRC on table RETURN_ORDER_LINE_SRC;
create or replace stream STRM_PURCHASE_ORDER_SRC on table PURCHASE_ORDER_SRC;
create or replace stream STRM_PURCHASE_ORDER_LINE_SRC on table PURCHASE_ORDER_LINE_SRC;
create or replace stream STRM_INVENTORY_BALANCE_SRC on table INVENTORY_BALANCE_SRC;
create or replace stream STRM_INVENTORY_TRANSACTION_SRC on table INVENTORY_TRANSACTION_SRC;
create or replace stream STRM_CDC_EVENTS_SRC on table CDC_EVENTS_SRC;


