-- 6) Validation queries

select count(*) as current_customer_rows
from RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2
where is_current = true;

select count(*) as current_store_rows
from RETAIL360_DEMO.CORE.DIM_STORE_SCD2
where is_current = true;

select count(*) as current_product_sku_rows
from RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2
where is_current = true;

select count(*) as sales_order_rows
from RETAIL360_DEMO.CORE.FACT_SALES_ORDER;

select count(*) as sales_order_line_rows
from RETAIL360_DEMO.CORE.FACT_SALES_ORDER_LINE;

select count(*) as payment_rows
from RETAIL360_DEMO.CORE.FACT_PAYMENT;

select count(*) as inventory_transaction_rows
from RETAIL360_DEMO.CORE.FACT_INVENTORY_TRANSACTION;

-- Next checks you should do now
-- 1. Check SCD2 integrity

-- For each dimension, make sure there is only one current row per business key.

select customer_id, count(*) as cnt
from RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2
where is_current = true
group by customer_id
having count(*) > 1;

select store_id, count(*) as cnt
from RETAIL360_DEMO.CORE.DIM_STORE_SCD2
where is_current = true
group by store_id
having count(*) > 1;

select sku_id, count(*) as cnt
from RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2
where is_current = true
group by sku_id
having count(*) > 1;

-- Expected: 0 rows returned.


-- 2. Check fact key uniqueness

-- Make sure your fact tables do not have duplicate transaction keys.

select sales_order_id, count(*) as cnt
from RETAIL360_DEMO.CORE.FACT_SALES_ORDER
group by sales_order_id
having count(*) > 1;

select sales_order_line_id, count(*) as cnt
from RETAIL360_DEMO.CORE.FACT_SALES_ORDER_LINE
group by sales_order_line_id
having count(*) > 1;

select payment_id, count(*) as cnt
from RETAIL360_DEMO.CORE.FACT_PAYMENT
group by payment_id
having count(*) > 1;

select inventory_transaction_id, count(*) as cnt
from RETAIL360_DEMO.CORE.FACT_INVENTORY_TRANSACTION
group by inventory_transaction_id
having count(*) > 1;

-- Expected: 0 rows returned.

-- 3. Check basic referential consistency

-- Even if Snowflake does not enforce FK constraints, you should test them logically.

-- Sales orders should map to current customer and store
select count(*) as orphan_customer_rows
from RETAIL360_DEMO.CORE.FACT_SALES_ORDER f
left join RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 d
  on f.customer_id = d.customer_id
 and d.is_current = true
where d.customer_id is null;
--0
select count(*) as orphan_store_rows
from RETAIL360_DEMO.CORE.FACT_SALES_ORDER f
left join RETAIL360_DEMO.CORE.DIM_STORE_SCD2 d
  on f.store_id = d.store_id
 and d.is_current = true
where d.store_id is null;
--0

-- Sales order lines should map to SKU
select count(*) as orphan_sku_rows
from RETAIL360_DEMO.CORE.FACT_SALES_ORDER_LINE f
left join RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 d
  on f.sku_id = d.sku_id
 and d.is_current = true
where d.sku_id is null;
--0
-- Expected: ideally 0.


-- Perfect — these results are exactly what you want.

-- What your checks confirm
-- 1. SCD2 integrity is good

-- Since those queries returned no rows:

-- DIM_CUSTOMER_SCD2 has only one current row per customer_id
-- DIM_STORE_SCD2 has only one current row per store_id
-- DIM_PRODUCT_SKU_SCD2 has only one current row per sku_id

-- That means your SCD2 logic is behaving correctly for the current load.

-- 2. Fact key uniqueness is good

-- Since those duplicate-key checks returned no rows:

-- FACT_SALES_ORDER has no duplicate sales_order_id
-- FACT_SALES_ORDER_LINE has no duplicate sales_order_line_id
-- FACT_PAYMENT has no duplicate payment_id
-- FACT_INVENTORY_TRANSACTION has no duplicate inventory_transaction_id

-- So your fact merges are idempotent and clean.

-- 3. Referential consistency is good

-- Your orphan checks are all 0:

-- sales orders map to customer dimension
-- sales orders map to store dimension
-- sales order lines map to product sku dimension

-- So CORE is internally consistent.