use database RETAIL360_DEMO;

create schema if not exists MART;
use schema MART;


-- 1) SALES DETAIL MART - CURRENT DIMENSION SNAPSHOT
-- Use this when you want current customer/store/product attributes

create or replace view VW_SALES_DETAIL_CURRENT as
select
    so.sales_order_id,
    so.order_number,
    so.customer_id,
    so.store_id,
    sol.sales_order_line_id,
    sol.line_number,
    sol.sku_id,
    sol.promotion_id,
    so.sales_channel,
    so.order_datetime,
    cast(so.order_datetime as date) as order_date,
    year(so.order_datetime) as order_year,
    month(so.order_datetime) as order_month,
    day(so.order_datetime) as order_day,
    date_trunc('month', so.order_datetime) as order_month_start,
    date_trunc('week', so.order_datetime) as order_week_start,
    so.order_status,
    so.currency_code,

    so.subtotal_amount,
    so.discount_amount as order_discount_amount,
    so.tax_amount as order_tax_amount,
    so.shipping_amount,
    so.total_amount as order_total_amount,

    sol.ordered_quantity,
    sol.unit_list_price,
    sol.unit_selling_price,
    sol.line_discount_amount,
    sol.tax_amount as line_tax_amount,
    sol.line_total_amount,
    sol.fulfillment_store_id,
    sol.line_status,

    c.dim_customer_sk,
    c.customer_code,
    c.loyalty_id,
    c.first_name as customer_first_name,
    c.last_name as customer_last_name,
    c.email as customer_email,
    c.phone as customer_phone,
    c.preferred_channel,
    c.marketing_opt_in,
    c.status as customer_status,

    s.dim_store_sk,
    s.store_code,
    s.store_name,
    s.store_type,
    s.channel_type,
    s.city as store_city,
    s.state as store_state,
    s.postal_code as store_postal_code,
    s.country_code as store_country_code,
    s.status as store_status,

    p.dim_product_sku_sk,
    p.product_id,
    p.sku_code,
    p.barcode,
    p.color,
    p.size,
    p.style,
    p.pack_size,
    p.standard_cost,
    p.list_price,
    p.status as sku_status,

    (sol.ordered_quantity * sol.unit_selling_price) as gross_sales_amount,
    (sol.ordered_quantity * (sol.unit_selling_price - p.standard_cost)) as gross_margin_amount,

    so.batch_id,
    so.extract_ts,
    so.inserted_at
from RETAIL360_DEMO.CORE.FACT_SALES_ORDER so
join RETAIL360_DEMO.CORE.FACT_SALES_ORDER_LINE sol
  on so.sales_order_id = sol.sales_order_id
left join RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 c
  on so.customer_id = c.customer_id
 and c.is_current = true
left join RETAIL360_DEMO.CORE.DIM_STORE_SCD2 s
  on so.store_id = s.store_id
 and s.is_current = true
left join RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 p
  on sol.sku_id = p.sku_id
 and p.is_current = true
;


-- 2) SALES DETAIL MART - HISTORICALLY CORRECT SCD2 JOIN
-- Use this for true historical analysis

create or replace view VW_SALES_DETAIL_HISTORICAL as
select
    so.sales_order_id,
    so.order_number,
    so.customer_id,
    so.store_id,
    sol.sales_order_line_id,
    sol.line_number,
    sol.sku_id,
    sol.promotion_id,
    so.sales_channel,
    so.order_datetime,
    cast(so.order_datetime as date) as order_date,
    year(so.order_datetime) as order_year,
    month(so.order_datetime) as order_month,
    day(so.order_datetime) as order_day,
    date_trunc('month', so.order_datetime) as order_month_start,
    date_trunc('week', so.order_datetime) as order_week_start,
    so.order_status,
    so.currency_code,

    so.subtotal_amount,
    so.discount_amount as order_discount_amount,
    so.tax_amount as order_tax_amount,
    so.shipping_amount,
    so.total_amount as order_total_amount,

    sol.ordered_quantity,
    sol.unit_list_price,
    sol.unit_selling_price,
    sol.line_discount_amount,
    sol.tax_amount as line_tax_amount,
    sol.line_total_amount,
    sol.fulfillment_store_id,
    sol.line_status,

    c.dim_customer_sk,
    c.customer_code,
    c.loyalty_id,
    c.first_name as customer_first_name,
    c.last_name as customer_last_name,
    c.email as customer_email,
    c.phone as customer_phone,
    c.preferred_channel,
    c.marketing_opt_in,
    c.status as customer_status,

    s.dim_store_sk,
    s.store_code,
    s.store_name,
    s.store_type,
    s.channel_type,
    s.city as store_city,
    s.state as store_state,
    s.postal_code as store_postal_code,
    s.country_code as store_country_code,
    s.status as store_status,

    p.dim_product_sku_sk,
    p.product_id,
    p.sku_code,
    p.barcode,
    p.color,
    p.size,
    p.style,
    p.pack_size,
    p.standard_cost,
    p.list_price,
    p.status as sku_status,

    (sol.ordered_quantity * sol.unit_selling_price) as gross_sales_amount,
    (sol.ordered_quantity * (sol.unit_selling_price - p.standard_cost)) as gross_margin_amount,

    so.batch_id,
    so.extract_ts,
    so.inserted_at
from RETAIL360_DEMO.CORE.FACT_SALES_ORDER so
join RETAIL360_DEMO.CORE.FACT_SALES_ORDER_LINE sol
  on so.sales_order_id = sol.sales_order_id
left join RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 c
  on so.customer_id = c.customer_id
 and so.order_datetime >= c.effective_from_ts
 and so.order_datetime <  c.effective_to_ts
left join RETAIL360_DEMO.CORE.DIM_STORE_SCD2 s
  on so.store_id = s.store_id
 and so.order_datetime >= s.effective_from_ts
 and so.order_datetime <  s.effective_to_ts
left join RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 p
  on sol.sku_id = p.sku_id
 and so.order_datetime >= p.effective_from_ts
 and so.order_datetime <  p.effective_to_ts
;


-- 3) DAILY SALES BY STORE
-- Great for trend dashboards

create or replace view VW_SALES_DAILY_STORE as
select
    order_date,
    order_year,
    order_month,
    order_month_start,
    order_week_start,

    store_id,
    store_code,
    store_name,
    store_type,
    channel_type,
    store_city,
    store_state,
    store_country_code,

    sales_channel,
    currency_code,

    count(distinct sales_order_id) as order_count,
    count(distinct customer_id) as customer_count,
    count(distinct sku_id) as sku_count,
    sum(ordered_quantity) as total_quantity,
    sum(gross_sales_amount) as gross_sales_amount,
    sum(line_discount_amount) as line_discount_amount,
    sum(line_tax_amount) as line_tax_amount,
    sum(line_total_amount) as net_sales_amount,
    sum(gross_margin_amount) as gross_margin_amount,
    avg(line_total_amount) as avg_line_amount
from RETAIL360_DEMO.MART.VW_SALES_DETAIL_HISTORICAL
group by
    order_date,
    order_year,
    order_month,
    order_month_start,
    order_week_start,
    store_id,
    store_code,
    store_name,
    store_type,
    channel_type,
    store_city,
    store_state,
    store_country_code,
    sales_channel,
    currency_code
;


-- 4) CUSTOMER 360 MART
-- Great for customer reporting

create or replace view VW_CUSTOMER_360 as
select
    c.customer_id,
    c.customer_code,
    c.loyalty_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.preferred_channel,
    c.marketing_opt_in,
    c.status as customer_status,
    c.effective_from_ts,
    c.effective_to_ts,
    c.is_current,

    min(s.order_date) as first_order_date,
    max(s.order_date) as last_order_date,
    count(distinct s.sales_order_id) as lifetime_orders,
    sum(s.line_total_amount) as lifetime_revenue,
    sum(s.ordered_quantity) as lifetime_units,
    avg(s.line_total_amount) as avg_line_revenue,
    count(distinct s.store_id) as stores_shopped,
    count(distinct s.sku_id) as unique_skus_purchased
from RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 c
left join RETAIL360_DEMO.MART.VW_SALES_DETAIL_HISTORICAL s
  on c.customer_id = s.customer_id
 and s.order_datetime >= c.effective_from_ts
 and s.order_datetime <  c.effective_to_ts
group by
    c.customer_id,
    c.customer_code,
    c.loyalty_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.preferred_channel,
    c.marketing_opt_in,
    c.status,
    c.effective_from_ts,
    c.effective_to_ts,
    c.is_current
;


-- 5) PRODUCT SKU 360 MART
-- Great for SKU performance and margin analysis

create or replace view VW_PRODUCT_SKU_360 as
select
    p.sku_id,
    p.product_id,
    p.sku_code,
    p.barcode,
    p.color,
    p.size,
    p.style,
    p.pack_size,
    p.standard_cost,
    p.list_price,
    p.status as sku_status,
    p.effective_from_ts,
    p.effective_to_ts,
    p.is_current,

    min(s.order_date) as first_sale_date,
    max(s.order_date) as last_sale_date,
    count(distinct s.sales_order_id) as order_count,
    count(distinct s.customer_id) as customer_count,
    sum(s.ordered_quantity) as total_units_sold,
    sum(s.gross_sales_amount) as gross_sales_amount,
    sum(s.line_discount_amount) as total_discount_amount,
    sum(s.line_total_amount) as net_sales_amount,
    sum(s.gross_margin_amount) as gross_margin_amount
from RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 p
left join RETAIL360_DEMO.MART.VW_SALES_DETAIL_HISTORICAL s
  on p.sku_id = s.sku_id
 and s.order_datetime >= p.effective_from_ts
 and s.order_datetime <  p.effective_to_ts
group by
    p.sku_id,
    p.product_id,
    p.sku_code,
    p.barcode,
    p.color,
    p.size,
    p.style,
    p.pack_size,
    p.standard_cost,
    p.list_price,
    p.status,
    p.effective_from_ts,
    p.effective_to_ts,
    p.is_current
;

-- 6) STORE 360 MART
-- Great for store performance dashboards

create or replace view VW_STORE_360 as
select
    s.store_id,
    s.store_code,
    s.store_name,
    s.store_type,
    s.channel_type,
    s.city,
    s.state,
    s.postal_code,
    s.country_code,
    s.status as store_status,
    s.effective_from_ts,
    s.effective_to_ts,
    s.is_current,

    min(d.order_date) as first_order_date,
    max(d.order_date) as last_order_date,
    count(distinct d.sales_order_id) as total_orders,
    count(distinct d.customer_id) as total_customers,
    count(distinct d.sku_id) as total_skus_sold,
    sum(d.ordered_quantity) as total_units_sold,
    sum(d.gross_sales_amount) as gross_sales_amount,
    sum(d.line_total_amount) as net_sales_amount,
    sum(d.gross_margin_amount) as gross_margin_amount
from RETAIL360_DEMO.CORE.DIM_STORE_SCD2 s
left join RETAIL360_DEMO.MART.VW_SALES_DETAIL_HISTORICAL d
  on s.store_id = d.store_id
 and d.order_datetime >= s.effective_from_ts
 and d.order_datetime <  s.effective_to_ts
group by
    s.store_id,
    s.store_code,
    s.store_name,
    s.store_type,
    s.channel_type,
    s.city,
    s.state,
    s.postal_code,
    s.country_code,
    s.status,
    s.effective_from_ts,
    s.effective_to_ts,
    s.is_current
;


-- 7) PAYMENT SUMMARY MART
-- Great for payment mix and payment status tracking

create or replace view VW_PAYMENT_SUMMARY as
select
    cast(p.payment_datetime as date) as payment_date,
    date_trunc('month', p.payment_datetime) as payment_month_start,
    year(p.payment_datetime) as payment_year,
    month(p.payment_datetime) as payment_month,

    p.payment_method,
    p.payment_status,
    p.currency_code,

    so.store_id,
    s.store_code,
    s.store_name,
    s.store_type,
    s.channel_type,
    s.city as store_city,
    s.state as store_state,

    count(distinct p.payment_id) as payment_count,
    count(distinct p.sales_order_id) as order_count,
    sum(p.amount) as total_payment_amount,
    avg(p.amount) as avg_payment_amount
from RETAIL360_DEMO.CORE.FACT_PAYMENT p
left join RETAIL360_DEMO.CORE.FACT_SALES_ORDER so
  on p.sales_order_id = so.sales_order_id
left join RETAIL360_DEMO.CORE.DIM_STORE_SCD2 s
  on so.store_id = s.store_id
 and p.payment_datetime >= s.effective_from_ts
 and p.payment_datetime <  s.effective_to_ts
group by
    cast(p.payment_datetime as date),
    date_trunc('month', p.payment_datetime),
    year(p.payment_datetime),
    month(p.payment_datetime),
    p.payment_method,
    p.payment_status,
    p.currency_code,
    so.store_id,
    s.store_code,
    s.store_name,
    s.store_type,
    s.channel_type,
    s.city,
    s.state
;


-- 8) INVENTORY MOVEMENT DAILY MART
-- Great for inventory movement analysis

create or replace view VW_INVENTORY_MOVEMENT_DAILY as
select
    cast(i.transaction_datetime as date) as transaction_date,
    date_trunc('month', i.transaction_datetime) as transaction_month_start,
    year(i.transaction_datetime) as transaction_year,
    month(i.transaction_datetime) as transaction_month,

    i.transaction_type,
    i.reference_type,

    i.store_id,
    s.store_code,
    s.store_name,
    s.store_type,
    s.channel_type,
    s.city as store_city,
    s.state as store_state,

    i.sku_id,
    p.product_id,
    p.sku_code,
    p.barcode,
    p.color,
    p.size,
    p.style,
    p.pack_size,

    count(*) as txn_count,
    sum(i.quantity_change) as net_quantity_change,
    sum(case when i.quantity_change > 0 then i.quantity_change else 0 end) as positive_quantity_change,
    sum(case when i.quantity_change < 0 then abs(i.quantity_change) else 0 end) as negative_quantity_change,
    avg(i.unit_cost) as avg_unit_cost
from RETAIL360_DEMO.CORE.FACT_INVENTORY_TRANSACTION i
left join RETAIL360_DEMO.CORE.DIM_STORE_SCD2 s
  on i.store_id = s.store_id
 and i.transaction_datetime >= s.effective_from_ts
 and i.transaction_datetime <  s.effective_to_ts
left join RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 p
  on i.sku_id = p.sku_id
 and i.transaction_datetime >= p.effective_from_ts
 and i.transaction_datetime <  p.effective_to_ts
group by
    cast(i.transaction_datetime as date),
    date_trunc('month', i.transaction_datetime),
    year(i.transaction_datetime),
    month(i.transaction_datetime),
    i.transaction_type,
    i.reference_type,
    i.store_id,
    s.store_code,
    s.store_name,
    s.store_type,
    s.channel_type,
    s.city,
    s.state,
    i.sku_id,
    p.product_id,
    p.sku_code,
    p.barcode,
    p.color,
    p.size,
    p.style,
    p.pack_size
;


-- 9) EXECUTIVE KPI MART
-- One-row summary snapshot for KPI cards

create or replace view VW_EXECUTIVE_KPI as
select
    current_timestamp() as mart_generated_ts,
    count(distinct sales_order_id) as total_orders,
    count(distinct customer_id) as total_customers,
    count(distinct sku_id) as total_skus_sold,
    sum(ordered_quantity) as total_units_sold,
    sum(gross_sales_amount) as gross_sales_amount,
    sum(line_discount_amount) as total_discount_amount,
    sum(line_total_amount) as net_sales_amount,
    sum(gross_margin_amount) as gross_margin_amount,
    avg(line_total_amount) as avg_line_sales_amount
from RETAIL360_DEMO.MART.VW_SALES_DETAIL_HISTORICAL
;


select * from RETAIL360_DEMO.MART.VW_CUSTOMER_360
LIMIT 20;

select * from RETAIL360_DEMO.MART.VW_EXECUTIVE_KPI
LIMIT 20;

select * from RETAIL360_DEMO.MART.VW_INVENTORY_MOVEMENT_DAILY
LIMIT 20;

select * from RETAIL360_DEMO.MART.VW_PAYMENT_SUMMARY
LIMIT 20;

select * from RETAIL360_DEMO.MART.VW_PRODUCT_SKU_360
LIMIT 20;

select * from RETAIL360_DEMO.MART.VW_SALES_DAILY_STORE
LIMIT 20;

select * from RETAIL360_DEMO.MART.VW_SALES_DETAIL_CURRENT
LIMIT 20;

select * from RETAIL360_DEMO.MART.VW_SALES_DETAIL_HISTORICAL
LIMIT 20;

select * from RETAIL360_DEMO.MART.VW_STORE_360
LIMIT 20;







