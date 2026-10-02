
-- 2. WAREHOUSES

create warehouse if not exists RETAIL360_ETL_WH
with
    warehouse_size = 'XSMALL'
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true;

create warehouse if not exists RETAIL360_TASK_WH
with
    warehouse_size = 'XSMALL'
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true;