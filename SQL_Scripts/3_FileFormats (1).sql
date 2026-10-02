use schema INGEST;


-- 3. FILE FORMATS

create or replace file format FF_RETAIL360_CSV
    type = csv
    field_delimiter = ','
    skip_header = 1
    field_optionally_enclosed_by = '"'
    trim_space = true
    empty_field_as_null = true
    null_if = ('', 'NULL', 'null')
    error_on_column_count_mismatch = false
    compression = auto;

create or replace file format FF_RETAIL360_JSON
    type = json
    strip_outer_array = false
    compression = auto;

create or replace file format FF_RETAIL360_PARQUET
    type = parquet
    compression = auto;