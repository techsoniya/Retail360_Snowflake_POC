-- Audit tables you should create immediately
-- Before RAW tables, create your audit layer.

use schema AUDIT;


-- 5. AUDIT TABLES

create or replace table FILE_REGISTRY (
    file_registry_id number autoincrement,
    batch_id string,
    phase string,                      -- historical / incremental / cdc
    table_name string,
    file_format string,                -- csv / json / parquet
    stage_name string,
    stage_path string,
    file_name string,
    source_local_path string,
    file_size_bytes number,
    upload_status string,              -- PENDING / PUT_OK / PUT_FAILED
    pipe_name string,
    pipe_submit_status string,         -- SUBMITTED / FAILED / SKIPPED
    load_status string,                -- LOADED / PARTIAL / FAILED / UNKNOWN
    first_seen_at timestamp_ntz default current_timestamp(),
    last_updated_at timestamp_ntz default current_timestamp()
);

create or replace table BATCH_STATUS (
    batch_status_id number autoincrement,
    batch_id string,
    phase string,
    batch_start_ts timestamp_ntz,
    batch_end_ts timestamp_ntz,
    overall_status string,             -- STARTED / COMPLETED / FAILED / PARTIAL
    expected_files number,
    submitted_files number,
    loaded_files number,
    notes string,
    created_at timestamp_ntz default current_timestamp(),
    updated_at timestamp_ntz default current_timestamp()
);

create or replace table LOAD_AUDIT (
    load_audit_id number autoincrement,
    batch_id string,
    table_name string,
    raw_table_name string,
    src_filename string,
    records_loaded number,
    records_rejected number,
    load_started_at timestamp_ntz,
    load_completed_at timestamp_ntz,
    load_status string,
    created_at timestamp_ntz default current_timestamp()
);


-- select * from load_audit;
-- select * from batch_status;
-- select * from file_registry;


