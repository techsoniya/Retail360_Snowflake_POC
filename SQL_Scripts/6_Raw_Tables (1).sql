use database RETAIL360_DEMO;
use schema RAW;


-- RAW LAYER PRINCIPLES
-- 1. Transient tables
-- 2. No PK / FK / CHECK constraints
-- 3. Source-shaped columns from generator output
-- 4. Common ingestion metadata on every table



-- 1. BRAND

create or replace transient table BRAND_SRC (
    brand_id                number,
    brand_code              string,
    brand_name              string,
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 2. CATEGORY
-- =========================================================
create or replace transient table CATEGORY_SRC (
    category_id             number,
    parent_category_id      number,
    category_code           string,
    category_name           string,
    category_level          number,
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 3. SUPPLIER
-- =========================================================
create or replace transient table SUPPLIER_SRC (
    supplier_id             number,
    supplier_code           string,
    supplier_name           string,
    supplier_type           string,
    email                   string,
    phone                   string,
    tax_registration_no     string,
    lead_time_days          number,
    payment_terms_days      number,
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 4. STORE
-- =========================================================
create or replace transient table STORE_SRC (
    store_id                number,
    store_code              string,
    store_name              string,
    store_type              string,
    channel_type            string,
    email                   string,
    phone                   string,
    address_line_1          string,
    address_line_2          string,
    city                    string,
    state                   string,
    postal_code             string,
    country_code            string,
    open_date               date,
    close_date              date,
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 5. EMPLOYEE
-- =========================================================
create or replace transient table EMPLOYEE_SRC (
    employee_id             number,
    employee_code           string,
    first_name              string,
    last_name               string,
    email                   string,
    phone                   string,
    role_name               string,
    store_id                number,
    manager_employee_id     number,
    hire_date               date,
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 6. CUSTOMER
-- =========================================================
create or replace transient table CUSTOMER_SRC (
    customer_id             number,
    customer_code           string,
    loyalty_id              string,
    first_name              string,
    last_name               string,
    email                   string,
    phone                   string,
    date_of_birth           date,
    gender                  string,
    registration_date       date,
    preferred_channel       string,
    marketing_opt_in        boolean,
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 7. CUSTOMER_ADDRESS
-- =========================================================
create or replace transient table CUSTOMER_ADDRESS_SRC (
    customer_address_id     number,
    customer_id             number,
    address_type            string,
    address_line_1          string,
    address_line_2          string,
    city                    string,
    state                   string,
    postal_code             string,
    country_code            string,
    is_default              boolean,
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 8. PRODUCT
-- =========================================================
create or replace transient table PRODUCT_SRC (
    product_id              number,
    product_code            string,
    product_name            string,
    brand_id                number,
    category_id             number,
    description             string,
    unit_of_measure         string,
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 9. PRODUCT_SKU
-- =========================================================
create or replace transient table PRODUCT_SKU_SRC (
    sku_id                  number,
    product_id              number,
    sku_code                string,
    barcode                 string,
    color                   string,
    size                    string,
    style                   string,
    pack_size               string,
    standard_cost           number(18,4),
    list_price              number(18,4),
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 10. PROMOTION
-- =========================================================
create or replace transient table PROMOTION_SRC (
    promotion_id            number,
    promotion_code          string,
    promotion_name          string,
    promotion_type          string,
    discount_type           string,
    discount_value          number(18,4),
    start_datetime          timestamp_ntz,
    end_datetime            timestamp_ntz,
    status                  string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 11. PROMOTION_PRODUCT
-- =========================================================
create or replace transient table PROMOTION_PRODUCT_SRC (
    promotion_id            number,
    sku_id                  number,
    created_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 12. PROMOTION_STORE
-- =========================================================
create or replace transient table PROMOTION_STORE_SRC (
    promotion_id            number,
    store_id                number,
    created_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 13. SALES_ORDER
-- =========================================================
create or replace transient table SALES_ORDER_SRC (
    sales_order_id          number,
    order_number            string,
    customer_id             number,
    store_id                number,
    sales_channel           string,
    order_datetime          timestamp_ntz,
    order_status            string,
    currency_code           string,
    billing_address_id      number,
    shipping_address_id     number,
    cashier_employee_id     number,
    subtotal_amount         number(18,4),
    discount_amount         number(18,4),
    tax_amount              number(18,4),
    shipping_amount         number(18,4),
    total_amount            number(18,4),
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 14. SALES_ORDER_LINE
-- =========================================================
create or replace transient table SALES_ORDER_LINE_SRC (
    sales_order_line_id     number,
    sales_order_id          number,
    line_number             number,
    sku_id                  number,
    promotion_id            number,
    ordered_quantity        number(18,4),
    unit_list_price         number(18,4),
    unit_selling_price      number(18,4),
    line_discount_amount    number(18,4),
    tax_amount              number(18,4),
    line_total_amount       number(18,4),
    fulfillment_store_id    number,
    line_status             string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 15. PAYMENT
-- =========================================================
create or replace transient table PAYMENT_SRC (
    payment_id              number,
    sales_order_id          number,
    payment_reference       string,
    payment_method          string,
    payment_status          string,
    amount                  number(18,4),
    payment_datetime        timestamp_ntz,
    currency_code           string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 16. SHIPMENT
-- =========================================================
create or replace transient table SHIPMENT_SRC (
    shipment_id             number,
    sales_order_id          number,
    shipment_number         string,
    shipping_store_id       number,
    shipment_status         string,
    carrier_name            string,
    tracking_number         string,
    shipped_datetime        timestamp_ntz,
    delivered_datetime      timestamp_ntz,
    shipping_address_id     number,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 17. RETURN_ORDER
-- =========================================================
create or replace transient table RETURN_ORDER_SRC (
    return_order_id         number,
    return_number           string,
    original_sales_order_id number,
    customer_id             number,
    store_id                number,
    return_channel          string,
    return_datetime         timestamp_ntz,
    return_status           string,
    refund_amount           number(18,4),
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 18. RETURN_ORDER_LINE
-- =========================================================
create or replace transient table RETURN_ORDER_LINE_SRC (
    return_order_line_id        number,
    return_order_id             number,
    original_sales_order_line_id number,
    line_number                 number,
    return_reason_code          string,
    returned_quantity           number(18,4),
    refund_amount               number(18,4),
    restockable_flag            boolean,
    line_status                 string,
    created_at                  timestamp_ntz,
    updated_at                  timestamp_ntz,
    extract_ts                  timestamp_ntz,
    batch_id                    string,
    source_system               string,
    data_quality_flag           string,
    src_filename                string,
    src_row_number              number,
    load_ts                     timestamp_ntz
);

-- =========================================================
-- 19. PURCHASE_ORDER
-- =========================================================
create or replace transient table PURCHASE_ORDER_SRC (
    purchase_order_id       number,
    po_number               string,
    supplier_id             number,
    destination_store_id    number,
    order_datetime          timestamp_ntz,
    expected_delivery_date  date,
    po_status               string,
    currency_code           string,
    subtotal_amount         number(18,4),
    tax_amount              number(18,4),
    total_amount            number(18,4),
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 20. PURCHASE_ORDER_LINE
-- =========================================================
create or replace transient table PURCHASE_ORDER_LINE_SRC (
    purchase_order_line_id  number,
    purchase_order_id       number,
    line_number             number,
    sku_id                  number,
    ordered_quantity        number(18,4),
    received_quantity       number(18,4),
    unit_cost               number(18,4),
    tax_amount              number(18,4),
    line_total_amount       number(18,4),
    line_status             string,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 21. INVENTORY_BALANCE
-- =========================================================
create or replace transient table INVENTORY_BALANCE_SRC (
    inventory_balance_id    number,
    store_id                number,
    sku_id                  number,
    on_hand_quantity        number(18,4),
    reserved_quantity       number(18,4),
    available_quantity      number(18,4),
    damaged_quantity        number(18,4),
    reorder_point_quantity  number(18,4),
    safety_stock_quantity   number(18,4),
    last_stock_update_at    timestamp_ntz,
    created_at              timestamp_ntz,
    updated_at              timestamp_ntz,
    extract_ts              timestamp_ntz,
    batch_id                string,
    source_system           string,
    data_quality_flag       string,
    src_filename            string,
    src_row_number          number,
    load_ts                 timestamp_ntz
);

-- =========================================================
-- 22. INVENTORY_TRANSACTION
-- =========================================================
create or replace transient table INVENTORY_TRANSACTION_SRC (
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
    created_at               timestamp_ntz,
    updated_at               timestamp_ntz,
    extract_ts               timestamp_ntz,
    batch_id                 string,
    source_system            string,
    data_quality_flag        string,
    src_filename             string,
    src_row_number           number,
    load_ts                  timestamp_ntz
);

-- =========================================================
-- 23. CDC EVENTS
-- =========================================================
create or replace transient table CDC_EVENTS_SRC (
    event_id                 string,
    source_table             string,
    op                       string,
    change_ts                timestamp_ntz,
    source_pk                string,
    before_payload           variant,
    after_payload            variant,
    batch_id                 string,
    extract_ts               timestamp_ntz,
    source_system            string,
    src_filename             string,
    load_ts                  timestamp_ntz
);



use database RETAIL360_DEMO;
use schema RAW;

create or replace transient table RAW_REJECT_LOG (
    reject_log_id        number autoincrement,
    batch_id             string,
    table_name           string,
    src_filename         string,
    src_row_number       number,
    reject_reason        string,
    raw_payload          variant,
    rejected_at          timestamp_ntz default current_timestamp()
);


-- select * from brand_src;

-- truncate table if exists BRAND_SRC;
-- truncate table if exists CATEGORY_SRC;
-- truncate table if exists SUPPLIER_SRC;
-- truncate table if exists STORE_SRC;
-- truncate table if exists EMPLOYEE_SRC;
-- truncate table if exists CUSTOMER_SRC;
-- truncate table if exists CUSTOMER_ADDRESS_SRC;
-- truncate table if exists PRODUCT_SRC;
-- truncate table if exists PRODUCT_SKU_SRC;
-- truncate table if exists PROMOTION_SRC;
-- truncate table if exists PROMOTION_PRODUCT_SRC;
-- truncate table if exists PROMOTION_STORE_SRC;
-- truncate table if exists SALES_ORDER_SRC;
-- -- truncate table if exists SALES_ORDER_LINE_SRC;
-- -- truncate table if exists PAYMENT_SRC;
-- -- truncate table if exists SHIPMENT_SRC;
-- truncate table if exists RETURN_ORDER_SRC;
-- truncate table if exists RETURN_ORDER_LINE_SRC;
-- truncate table if exists PURCHASE_ORDER_SRC;
-- truncate table if exists PURCHASE_ORDER_LINE_SRC;
-- truncate table if exists INVENTORY_BALANCE_SRC;
-- truncate table if exists INVENTORY_TRANSACTION_SRC;
-- truncate table if exists CDC_EVENTS_SRC;
-- truncate table if exists RAW_REJECT_LOG;

