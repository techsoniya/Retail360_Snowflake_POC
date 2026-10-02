use database RETAIL360_DEMO;
create schema if not exists CORE;
use schema CORE;


-- Drop old procedures first if needed

drop procedure if exists SP_LOAD_DIM_CUSTOMER_SCD2();
drop procedure if exists SP_LOAD_DIM_STORE_SCD2();
drop procedure if exists SP_LOAD_DIM_PRODUCT_SKU_SCD2();
drop procedure if exists SP_LOAD_FACT_SALES_ORDER();
drop procedure if exists SP_LOAD_FACT_SALES_ORDER_LINE();
drop procedure if exists SP_LOAD_FACT_PAYMENT();
drop procedure if exists SP_LOAD_FACT_INVENTORY_TRANSACTION();
drop procedure if exists SP_LOAD_CORE_ALL();
drop procedure if exists SP_REBUILD_CORE_ALL();


-- Recreate CORE tables

create or replace table DIM_CUSTOMER_SCD2 (
    dim_customer_sk        number autoincrement,
    customer_id            number,
    customer_code          string,
    loyalty_id             string,
    first_name             string,
    last_name              string,
    email                  string,
    phone                  string,
    preferred_channel      string,
    marketing_opt_in       boolean,
    status                 string,
    effective_from_ts      timestamp_ntz,
    effective_to_ts        timestamp_ntz,
    is_current             boolean,
    source_batch_id        string,
    source_extract_ts      timestamp_ntz,
    inserted_at            timestamp_ntz default current_timestamp()
);


create or replace table DIM_STORE_SCD2 (
    dim_store_sk           number autoincrement,
    store_id               number,
    store_code             string,
    store_name             string,
    store_type             string,
    channel_type           string,
    city                   string,
    state                  string,
    postal_code            string,
    country_code           string,
    status                 string,
    effective_from_ts      timestamp_ntz,
    effective_to_ts        timestamp_ntz,
    is_current             boolean,
    source_batch_id        string,
    source_extract_ts      timestamp_ntz,
    inserted_at            timestamp_ntz default current_timestamp()
);

create or replace table DIM_PRODUCT_SKU_SCD2 (
    dim_product_sku_sk     number autoincrement,
    sku_id                 number,
    product_id             number,
    sku_code               string,
    barcode                string,
    color                  string,
    size                   string,
    style                  string,
    pack_size              string,
    standard_cost          number(18,4),
    list_price             number(18,4),
    status                 string,
    effective_from_ts      timestamp_ntz,
    effective_to_ts        timestamp_ntz,
    is_current             boolean,
    source_batch_id        string,
    source_extract_ts      timestamp_ntz,
    inserted_at            timestamp_ntz default current_timestamp()
);
select * from fact_sales_order
create or replace table FACT_SALES_ORDER (
    sales_order_id         number,
    order_number           string,
    customer_id            number,
    store_id               number,
    sales_channel          string,
    order_datetime         timestamp_ntz,
    order_status           string,
    currency_code          string,
    subtotal_amount        number(18,4),
    discount_amount        number(18,4),
    tax_amount             number(18,4),
    shipping_amount        number(18,4),
    total_amount           number(18,4),
    batch_id               string,
    extract_ts             timestamp_ntz,
    inserted_at            timestamp_ntz default current_timestamp()
);

create or replace table FACT_SALES_ORDER_LINE (
    sales_order_line_id    number,
    sales_order_id         number,
    line_number            number,
    sku_id                 number,
    promotion_id           number,
    ordered_quantity       number(18,4),
    unit_list_price        number(18,4),
    unit_selling_price     number(18,4),
    line_discount_amount   number(18,4),
    tax_amount             number(18,4),
    line_total_amount      number(18,4),
    fulfillment_store_id   number,
    line_status            string,
    batch_id               string,
    extract_ts             timestamp_ntz,
    inserted_at            timestamp_ntz default current_timestamp()
);

create or replace table FACT_PAYMENT (
    payment_id             number,
    sales_order_id         number,
    payment_reference      string,
    payment_method         string,
    payment_status         string,
    amount                 number(18,4),
    payment_datetime       timestamp_ntz,
    currency_code          string,
    batch_id               string,
    extract_ts             timestamp_ntz,
    inserted_at            timestamp_ntz default current_timestamp()
);

create or replace table FACT_INVENTORY_TRANSACTION (
    inventory_transaction_id number,
    transaction_datetime     timestamp_ntz,
    transaction_type         string,
    store_id                 number,
    sku_id                   number,
    quantity_change          number(18,4),
    reference_type           string,
    reference_id             number,
    unit_cost                number(18,4),
    remarks                  string,
    batch_id                 string,
    extract_ts               timestamp_ntz,
    inserted_at              timestamp_ntz default current_timestamp()
);

