
alter pipe RETAIL360_DEMO.INGEST.PIPE_CDC_EVENTS_JSON refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_CUSTOMER_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_STORE_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_PRODUCT_SKU_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_SALES_ORDER_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_SALES_ORDER_LINE_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_PAYMENT_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_SHIPMENT_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_PURCHASE_ORDER_LINE_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_RETURN_ORDER_LINE_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_INVENTORY_BALANCE_PARQUET refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_INVENTORY_TRANSACTION_PARQUET refresh;

alter pipe RETAIL360_DEMO.INGEST.PIPE_BRAND_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_CATEGORY_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_SUPPLIER_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_EMPLOYEE_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_CUSTOMER_ADDRESS_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_PRODUCT_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_PROMOTION_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_PROMOTION_PRODUCT_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_PROMOTION_STORE_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_PURCHASE_ORDER_CSV refresh;
alter pipe RETAIL360_DEMO.INGEST.PIPE_RETURN_ORDER_CSV refresh;





-- copy into RETAIL360_DEMO.RAW.BRAND_SRC
-- from (
--     select
--         $1::number,
--         $2::string,
--         $3::string,
--         $4::string,
--         $5::timestamp_ntz,
--         $6::timestamp_ntz,
--         $7::timestamp_ntz,
--         $8::string,
--         $9::string,
--         $10::string,
--         metadata$filename,
--         metadata$file_row_number,
--         current_timestamp()
--     from @RETAIL360_DEMO.INGEST.STG_RETAIL360_CSV
-- )
-- file_format = (format_name = RETAIL360_DEMO.INGEST.FF_RETAIL360_CSV)
-- pattern = '.*brand_historical_.*[.]csv'
-- force = true
-- on_error = 'continue';



use database RETAIL360_DEMO;
use schema INGEST;

-- create or replace pipe PIPE_BRAND_CSV as
-- copy into RAW.BRAND_SRC
-- from (
--     select
--         $1::number, $2::string, $3::string, $4::string,
--         $5::timestamp_ntz, $6::timestamp_ntz,
--         $7::timestamp_ntz, $8::string, $9::string, $10::string,
--         metadata$filename, metadata$file_row_number, current_timestamp()
--     from @INGEST.STG_RETAIL360_CSV
-- )
-- file_format = (format_name = INGEST.FF_RETAIL360_CSV)
-- pattern = '.*brand(_historical|_incremental)?_.*[.]csv'
-- on_error = 'continue';


create or replace pipe RETAIL360_DEMO.INGEST.PIPE_BRAND_CSV as
copy into RETAIL360_DEMO.RAW.BRAND_SRC
from (
    select
        $1::number as brand_id,
        $2::string as brand_code,
        $3::string as brand_name,
        $4::string as status,
        $5::timestamp_ntz as created_at,
        $6::timestamp_ntz as updated_at,
        $7::timestamp_ntz as extract_ts,
        $8::string as batch_id,
        $9::string as source_system,
        coalesce($10::string, 'GOOD') as data_quality_flag,
        metadata$filename as src_filename,
        metadata$file_row_number as src_row_number,
        current_timestamp() as load_ts
    from @RETAIL360_DEMO.INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = RETAIL360_DEMO.INGEST.FF_RETAIL360_CSV)
pattern = '.*brand(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_CATEGORY_CSV as
copy into RAW.CATEGORY_SRC
from (
    select
        $1::number, $2::number, $3::string, $4::string, $5::number, $6::string,
        $7::timestamp_ntz, $8::timestamp_ntz,
        $9::timestamp_ntz, $10::string, $11::string, $12::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*category(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_SUPPLIER_CSV as
copy into RAW.SUPPLIER_SRC
from (
    select
        $1::number, $2::string, $3::string, $4::string, $5::string, $6::string,
        $7::string, $8::number, $9::number, $10::string,
        $11::timestamp_ntz, $12::timestamp_ntz,
        $13::timestamp_ntz, $14::string, $15::string, $16::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*supplier(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_EMPLOYEE_CSV as
copy into RAW.EMPLOYEE_SRC
from (
    select
        $1::number, $2::string, $3::string, $4::string, $5::string, $6::string,
        $7::string, $8::number, $9::number, $10::date, $11::string,
        $12::timestamp_ntz, $13::timestamp_ntz,
        $14::timestamp_ntz, $15::string, $16::string, $17::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*employee(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_CUSTOMER_ADDRESS_CSV as
copy into RAW.CUSTOMER_ADDRESS_SRC
from (
    select
        $1::number, $2::number, $3::string, $4::string, $5::string, $6::string,
        $7::string, $8::string, $9::string, $10::boolean, $11::string,
        $12::timestamp_ntz, $13::timestamp_ntz,
        $14::timestamp_ntz, $15::string, $16::string, $17::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*customer_address(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_PRODUCT_CSV as
copy into RAW.PRODUCT_SRC
from (
    select
        $1::number, $2::string, $3::string, $4::number, $5::number, $6::string,
        $7::string, $8::string, $9::timestamp_ntz, $10::timestamp_ntz,
        $11::timestamp_ntz, $12::string, $13::string, $14::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*product(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_PROMOTION_CSV as
copy into RAW.PROMOTION_SRC
from (
    select
        $1::number, $2::string, $3::string, $4::string, $5::string,
        $6::number(18,4), $7::timestamp_ntz, $8::timestamp_ntz, $9::string,
        $10::timestamp_ntz, $11::timestamp_ntz,
        $12::timestamp_ntz, $13::string, $14::string, $15::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*promotion(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_PROMOTION_PRODUCT_CSV as
copy into RAW.PROMOTION_PRODUCT_SRC
from (
    select
        $1::number, $2::number, $3::timestamp_ntz,
        $4::timestamp_ntz, $5::string, $6::string, $7::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*promotion_product(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_PROMOTION_STORE_CSV as
copy into RAW.PROMOTION_STORE_SRC
from (
    select
        $1::number, $2::number, $3::timestamp_ntz,
        $4::timestamp_ntz, $5::string, $6::string, $7::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*promotion_store(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_PURCHASE_ORDER_CSV as
copy into RAW.PURCHASE_ORDER_SRC
from (
    select
        $1::number, $2::string, $3::number, $4::number, $5::timestamp_ntz, $6::date,
        $7::string, $8::string, $9::number(18,4), $10::number(18,4), $11::number(18,4),
        $12::timestamp_ntz, $13::timestamp_ntz,
        $14::timestamp_ntz, $15::string, $16::string, $17::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*purchase_order(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';

create or replace pipe PIPE_RETURN_ORDER_CSV as
copy into RAW.RETURN_ORDER_SRC
from (
    select
        $1::number, $2::string, $3::number, $4::number, $5::number, $6::string,
        $7::timestamp_ntz, $8::string, $9::number(18,4),
        $10::timestamp_ntz, $11::timestamp_ntz,
        $12::timestamp_ntz, $13::string, $14::string, $15::string,
        metadata$filename, metadata$file_row_number, current_timestamp()
    from @INGEST.STG_RETAIL360_CSV
)
file_format = (format_name = INGEST.FF_RETAIL360_CSV)
pattern = '.*return_order(_historical|_incremental)?_.*[.]csv'
on_error = 'continue';


use database RETAIL360_DEMO;
use schema INGEST;

create or replace pipe PIPE_CUSTOMER_PARQUET as
copy into RAW.CUSTOMER_SRC
from (
    select
        $1:customer_id::number,
        $1:customer_code::string,
        $1:loyalty_id::string,
        $1:first_name::string,
        $1:last_name::string,
        $1:email::string,
        $1:phone::string,
        $1:date_of_birth::date,
        $1:gender::string,
        $1:registration_date::date,
        $1:preferred_channel::string,
        $1:marketing_opt_in::boolean,
        $1:status::string,
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*customer(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';

create or replace pipe PIPE_STORE_PARQUET as
copy into RAW.STORE_SRC
from (
    select
        $1:store_id::number,
        $1:store_code::string,
        $1:store_name::string,
        $1:store_type::string,
        $1:channel_type::string,
        $1:email::string,
        $1:phone::string,
        $1:address_line_1::string,
        $1:address_line_2::string,
        $1:city::string,
        $1:state::string,
        $1:postal_code::string,
        $1:country_code::string,
        $1:open_date::date,
        $1:close_date::date,
        $1:status::string,
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*store(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';



create or replace pipe PIPE_PRODUCT_SKU_PARQUET as
copy into RAW.PRODUCT_SKU_SRC
from (
    select
        $1:sku_id::number,
        $1:product_id::number,
        $1:sku_code::string,
        $1:barcode::string,
        $1:color::string,
        $1:size::string,
        $1:style::string,
        $1:pack_size::string,
        $1:standard_cost::number(18,4),
        $1:list_price::number(18,4),
        $1:status::string,
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*product_sku(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';

create or replace pipe PIPE_SALES_ORDER_PARQUET as
copy into RAW.SALES_ORDER_SRC
from (
    select
        $1:sales_order_id::number,
        $1:order_number::string,
        $1:customer_id::number,
        $1:store_id::number,
        $1:sales_channel::string,
        to_timestamp_ntz($1:order_datetime::number, 6),
        $1:order_status::string,
        $1:currency_code::string,
        $1:billing_address_id::number,
        $1:shipping_address_id::number,
        $1:cashier_employee_id::number,
        $1:subtotal_amount::number(18,4),
        $1:discount_amount::number(18,4),
        $1:tax_amount::number(18,4),
        $1:shipping_amount::number(18,4),
        $1:total_amount::number(18,4),
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*sales_order(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';

create or replace pipe PIPE_SALES_ORDER_LINE_PARQUET as
copy into RAW.SALES_ORDER_LINE_SRC
from (
    select
        $1:sales_order_line_id::number,
        $1:sales_order_id::number,
        $1:line_number::number,
        $1:sku_id::number,
        $1:promotion_id::number,
        $1:ordered_quantity::number(18,4),
        $1:unit_list_price::number(18,4),
        $1:unit_selling_price::number(18,4),
        $1:line_discount_amount::number(18,4),
        $1:tax_amount::number(18,4),
        $1:line_total_amount::number(18,4),
        $1:fulfillment_store_id::number,
        $1:line_status::string,
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*sales_order_line(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';

create or replace pipe PIPE_PAYMENT_PARQUET as
copy into RAW.PAYMENT_SRC
from (
    select
        $1:payment_id::number,
        $1:sales_order_id::number,
        $1:payment_reference::string,
        $1:payment_method::string,
        $1:payment_status::string,
        $1:amount::number(18,4),
        to_timestamp_ntz($1:payment_datetime::number, 6),
        $1:currency_code::string,
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*payment(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';

create or replace pipe PIPE_SHIPMENT_PARQUET as
copy into RAW.SHIPMENT_SRC
from (
    select
        $1:shipment_id::number,
        $1:sales_order_id::number,
        $1:shipment_number::string,
        $1:shipping_store_id::number,
        $1:shipment_status::string,
        $1:carrier_name::string,
        $1:tracking_number::string,
        to_timestamp_ntz($1:shipped_datetime::number, 6),
        to_timestamp_ntz($1:delivered_datetime::number, 6),
        $1:shipping_address_id::number,
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*shipment(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';

create or replace pipe PIPE_PURCHASE_ORDER_LINE_PARQUET as
copy into RAW.PURCHASE_ORDER_LINE_SRC
from (
    select
        $1:purchase_order_line_id::number,
        $1:purchase_order_id::number,
        $1:line_number::number,
        $1:sku_id::number,
        $1:ordered_quantity::number(18,4),
        $1:received_quantity::number(18,4),
        $1:unit_cost::number(18,4),
        $1:tax_amount::number(18,4),
        $1:line_total_amount::number(18,4),
        $1:line_status::string,
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*purchase_order_line(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';

create or replace pipe PIPE_RETURN_ORDER_LINE_PARQUET as
copy into RAW.RETURN_ORDER_LINE_SRC
from (
    select
        $1:return_order_line_id::number,
        $1:return_order_id::number,
        $1:original_sales_order_line_id::number,
        $1:line_number::number,
        $1:return_reason_code::string,
        $1:returned_quantity::number(18,4),
        $1:refund_amount::number(18,4),
        $1:restockable_flag::boolean,
        $1:line_status::string,
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*return_order_line(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';

create or replace pipe PIPE_INVENTORY_BALANCE_PARQUET as
copy into RAW.INVENTORY_BALANCE_SRC
from (
    select
        $1:inventory_balance_id::number,
        $1:store_id::number,
        $1:sku_id::number,
        $1:on_hand_quantity::number(18,4),
        $1:reserved_quantity::number(18,4),
        $1:available_quantity::number(18,4),
        $1:damaged_quantity::number(18,4),
        $1:reorder_point_quantity::number(18,4),
        $1:safety_stock_quantity::number(18,4),
        to_timestamp_ntz($1:last_stock_update_at::number, 6),
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*inventory_balance(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';

create or replace pipe PIPE_INVENTORY_TRANSACTION_PARQUET as
copy into RAW.INVENTORY_TRANSACTION_SRC
from (
    select
        $1:inventory_transaction_id::number,
        to_timestamp_ntz($1:transaction_datetime::number, 6),
        $1:transaction_type::string,
        $1:store_id::number,
        $1:sku_id::number,
        $1:quantity_change::number(18,4),
        $1:reference_type::string,
        $1:reference_id::number,
        $1:unit_cost::number(18,4),
        $1:remarks::string,
        to_timestamp_ntz($1:created_at::number, 6),
        to_timestamp_ntz($1:updated_at::number, 6),
        to_timestamp_ntz($1:extract_ts::number, 6),
        $1:batch_id::string,
        $1:source_system::string,
        $1:data_quality_flag::string,
        metadata$filename,
        metadata$file_row_number,
        current_timestamp()
    from @INGEST.STG_RETAIL360_PARQUET
)
file_format = (format_name = INGEST.FF_RETAIL360_PARQUET)
pattern = '.*inventory_transaction(_historical|_incremental)?_.*[.]parquet'
on_error = 'continue';


create or replace pipe PIPE_CDC_EVENTS_JSON as
copy into RAW.CDC_EVENTS_SRC
from (
    select
        $1:event_id::string,
        $1:source_table::string,
        $1:op::string,
        try_to_timestamp_ntz($1:change_ts::string),
        $1:source_pk::string,
        $1:before,
        $1:after,
        $1:batch_id::string,
        try_to_timestamp_ntz($1:extract_ts::string),
        $1:source_system::string,
        metadata$filename,
        current_timestamp()
    from @INGEST.STG_RETAIL360_JSON
)
file_format = (format_name = INGEST.FF_RETAIL360_JSON)
pattern = '.*cdc_events_.*[.]json'
on_error = 'continue';


-- -- use database RETAIL360_DEMO;

-- with raw_tables as (
--     select 'BRAND_SRC' as object_name, 'RAW_TABLE' as object_type, (select count(*) from RETAIL360_DEMO.RAW.BRAND_SRC) as row_count
--     union all select 'CATEGORY_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.CATEGORY_SRC)
--     union all select 'SUPPLIER_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.SUPPLIER_SRC)
--     union all select 'STORE_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.STORE_SRC)
--     union all select 'EMPLOYEE_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.EMPLOYEE_SRC)
--     union all select 'CUSTOMER_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.CUSTOMER_SRC)
--     union all select 'CUSTOMER_ADDRESS_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.CUSTOMER_ADDRESS_SRC)
--     union all select 'PRODUCT_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.PRODUCT_SRC)
--     union all select 'PRODUCT_SKU_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.PRODUCT_SKU_SRC)
--     union all select 'PROMOTION_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.PROMOTION_SRC)
--     union all select 'PROMOTION_PRODUCT_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.PROMOTION_PRODUCT_SRC)
--     union all select 'PROMOTION_STORE_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.PROMOTION_STORE_SRC)
--     union all select 'SALES_ORDER_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.SALES_ORDER_SRC)
--     union all select 'SALES_ORDER_LINE_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.SALES_ORDER_LINE_SRC)
--     union all select 'PAYMENT_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.PAYMENT_SRC)
--     union all select 'SHIPMENT_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.SHIPMENT_SRC)
--     union all select 'RETURN_ORDER_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.RETURN_ORDER_SRC)
--     union all select 'RETURN_ORDER_LINE_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.RETURN_ORDER_LINE_SRC)
--     union all select 'PURCHASE_ORDER_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.PURCHASE_ORDER_SRC)
--     union all select 'PURCHASE_ORDER_LINE_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.PURCHASE_ORDER_LINE_SRC)
--     union all select 'INVENTORY_BALANCE_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.INVENTORY_BALANCE_SRC)
--     union all select 'INVENTORY_TRANSACTION_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.INVENTORY_TRANSACTION_SRC)
--     union all select 'CDC_EVENTS_SRC', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.CDC_EVENTS_SRC)
--     union all select 'RAW_REJECT_LOG', 'RAW_TABLE', (select count(*) from RETAIL360_DEMO.RAW.RAW_REJECT_LOG)
-- ),
-- raw_streams as (
--     select 'STRM_BRAND_SRC' as object_name, 'STREAM' as object_type, (select count(*) from RETAIL360_DEMO.RAW.STRM_BRAND_SRC) as row_count
--     union all select 'STRM_CATEGORY_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_CATEGORY_SRC)
--     union all select 'STRM_SUPPLIER_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_SUPPLIER_SRC)
--     union all select 'STRM_STORE_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_STORE_SRC)
--     union all select 'STRM_EMPLOYEE_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_EMPLOYEE_SRC)
--     union all select 'STRM_CUSTOMER_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_CUSTOMER_SRC)
--     union all select 'STRM_CUSTOMER_ADDRESS_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_CUSTOMER_ADDRESS_SRC)
--     union all select 'STRM_PRODUCT_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_PRODUCT_SRC)
--     union all select 'STRM_PRODUCT_SKU_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_PRODUCT_SKU_SRC)
--     union all select 'STRM_PROMOTION_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_PROMOTION_SRC)
--     union all select 'STRM_PROMOTION_PRODUCT_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_PROMOTION_PRODUCT_SRC)
--     union all select 'STRM_PROMOTION_STORE_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_PROMOTION_STORE_SRC)
--     union all select 'STRM_SALES_ORDER_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_SALES_ORDER_SRC)
--     union all select 'STRM_SALES_ORDER_LINE_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_SALES_ORDER_LINE_SRC)
--     union all select 'STRM_PAYMENT_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_PAYMENT_SRC)
--     union all select 'STRM_SHIPMENT_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_SHIPMENT_SRC)
--     union all select 'STRM_RETURN_ORDER_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_RETURN_ORDER_SRC)
--     union all select 'STRM_RETURN_ORDER_LINE_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_RETURN_ORDER_LINE_SRC)
--     union all select 'STRM_PURCHASE_ORDER_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_PURCHASE_ORDER_SRC)
--     union all select 'STRM_PURCHASE_ORDER_LINE_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_PURCHASE_ORDER_LINE_SRC)
--     union all select 'STRM_INVENTORY_BALANCE_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_INVENTORY_BALANCE_SRC)
--     union all select 'STRM_INVENTORY_TRANSACTION_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_INVENTORY_TRANSACTION_SRC)
--     union all select 'STRM_CDC_EVENTS_SRC', 'STREAM', (select count(*) from RETAIL360_DEMO.RAW.STRM_CDC_EVENTS_SRC)
-- )
-- select *
-- from raw_tables
-- union all
-- select *
-- from raw_streams
-- order by object_type, object_name;




