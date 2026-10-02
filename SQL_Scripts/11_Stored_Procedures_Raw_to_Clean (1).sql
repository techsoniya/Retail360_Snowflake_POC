use database RETAIL360_DEMO;
use schema CLEAN;


-- STORED PROCEDURES: RAW STREAM -> CLEAN
-- Pattern:
-- 1. Materialize stream rows into a temp table
-- 2. Insert rejects explicitly
-- 3. Write RAW_REJECT_LOG explicitly
-- 4. Merge accepted rows into CLEAN explicitly



-- 1. BRAND



use database RETAIL360_DEMO;
use schema CLEAN;

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_BRAND_STREAM()
returns string
language sql
as
$$
declare
    v_stream_rows integer default 0;
    v_valid_rows  integer default 0;
    v_reject_rows integer default 0;
begin
    create or replace temporary table TMP_BRAND_STREAM as
    select
        brand_id,
        brand_code,
        brand_name,
        status,
        created_at,
        updated_at,
        extract_ts,
        batch_id,
        source_system,
        data_quality_flag,
        src_filename,
        src_row_number,
        load_ts
    from RETAIL360_DEMO.RAW.STRM_BRAND_SRC
    where metadata$action = 'INSERT';

    select count(*) into :v_stream_rows
    from TMP_BRAND_STREAM;

    select count(*) into :v_valid_rows
    from TMP_BRAND_STREAM
    where data_quality_flag = 'GOOD'
      and status in ('ACTIVE','INACTIVE')
      and brand_code is not null
      and brand_name is not null;

    select count(*) into :v_reject_rows
    from TMP_BRAND_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE')
       or brand_code is null
       or brand_name is null;

    insert into RETAIL360_DEMO.CLEAN.BRAND_REJECT (
        brand_id,
        brand_code,
        brand_name,
        status,
        created_at,
        updated_at,
        extract_ts,
        batch_id,
        source_system,
        data_quality_flag,
        src_filename,
        src_row_number,
        load_ts,
        reject_reason,
        rejected_at
    )
    select
        brand_id,
        brand_code,
        brand_name,
        status,
        created_at,
        updated_at,
        extract_ts,
        batch_id,
        source_system,
        data_quality_flag,
        src_filename,
        src_row_number,
        load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE') then 'INVALID_STATUS'
            when brand_code is null then 'NULL_BRAND_CODE'
            when brand_name is null then 'NULL_BRAND_NAME'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_BRAND_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE')
       or brand_code is null
       or brand_name is null;

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id,
        table_name,
        src_filename,
        src_row_number,
        reject_reason,
        raw_payload
    )
    select
        batch_id,
        'BRAND',
        src_filename,
        src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE') then 'INVALID_STATUS'
            when brand_code is null then 'NULL_BRAND_CODE'
            when brand_name is null then 'NULL_BRAND_NAME'
            else 'UNKNOWN'
        end,
        object_construct(
            'brand_id', brand_id,
            'brand_code', brand_code,
            'brand_name', brand_name,
            'status', status,
            'created_at', created_at,
            'updated_at', updated_at,
            'extract_ts', extract_ts,
            'batch_id', batch_id,
            'source_system', source_system,
            'data_quality_flag', data_quality_flag,
            'src_filename', src_filename,
            'src_row_number', src_row_number,
            'load_ts', load_ts
        )
    from TMP_BRAND_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE')
       or brand_code is null
       or brand_name is null;

    merge into RETAIL360_DEMO.CLEAN.BRAND t
    using (
        select *
        from TMP_BRAND_STREAM
        where data_quality_flag = 'GOOD'
          and status in ('ACTIVE','INACTIVE')
          and brand_code is not null
          and brand_name is not null
    ) s
    on t.brand_code = s.brand_code
    when matched then update set
        brand_id = s.brand_id,
        brand_name = s.brand_name,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        brand_id,
        brand_code,
        brand_name,
        status,
        created_at,
        updated_at,
        extract_ts,
        batch_id,
        source_system,
        data_quality_flag,
        src_filename,
        src_row_number,
        load_ts,
        cleaned_at
    )
    values (
        s.brand_id,
        s.brand_code,
        s.brand_name,
        s.status,
        s.created_at,
        s.updated_at,
        s.extract_ts,
        s.batch_id,
        s.source_system,
        s.data_quality_flag,
        s.src_filename,
        s.src_row_number,
        s.load_ts,
        current_timestamp()
    );

    return 'BRAND stream processed. stream_rows=' || v_stream_rows::string ||
           ', valid_rows=' || v_valid_rows::string ||
           ', reject_rows=' || v_reject_rows::string;
end;
$$;

call RETAIL360_DEMO.CLEAN.SP_PROCESS_BRAND_STREAM();

-- 2. CATEGORY

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_CATEGORY_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_CATEGORY_STREAM as
    select
        category_id, parent_category_id, category_code, category_name, category_level, status,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_CATEGORY_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.CATEGORY_REJECT (
        category_id, parent_category_id, category_code, category_name, category_level, status,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        category_id, parent_category_id, category_code, category_name, category_level, status,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE') then 'INVALID_STATUS'
            when category_level not in (0,1,2) then 'INVALID_CATEGORY_LEVEL'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_CATEGORY_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE')
       or category_level not in (0,1,2);

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'CATEGORY', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE') then 'INVALID_STATUS'
            when category_level not in (0,1,2) then 'INVALID_CATEGORY_LEVEL'
            else 'UNKNOWN'
        end,
        object_construct(
            'category_id', category_id, 'parent_category_id', parent_category_id,
            'category_code', category_code, 'category_name', category_name,
            'category_level', category_level, 'status', status,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system,
            'data_quality_flag', data_quality_flag, 'src_filename', src_filename,
            'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_CATEGORY_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE')
       or category_level not in (0,1,2);

    merge into RETAIL360_DEMO.CLEAN.CATEGORY t
    using (
        select *
        from TMP_CATEGORY_STREAM
        where data_quality_flag = 'GOOD'
          and status in ('ACTIVE','INACTIVE')
          and category_level in (0,1,2)
    ) s
    on t.category_code = s.category_code
    when matched then update set
        category_id = s.category_id,
        parent_category_id = s.parent_category_id,
        category_name = s.category_name,
        category_level = s.category_level,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        category_id, parent_category_id, category_code, category_name, category_level, status,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.category_id, s.parent_category_id, s.category_code, s.category_name, s.category_level, s.status,
        s.created_at, s.updated_at, s.extract_ts, s.batch_id, s.source_system, s.data_quality_flag,
        s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'CATEGORY stream processed';
end;
$$;


-- 3. SUPPLIER

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_SUPPLIER_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_SUPPLIER_STREAM as
    select
        supplier_id, supplier_code, supplier_name, supplier_type, email, phone, tax_registration_no,
        lead_time_days, payment_terms_days, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_SUPPLIER_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.SUPPLIER_REJECT (
        supplier_id, supplier_code, supplier_name, supplier_type, email, phone, tax_registration_no,
        lead_time_days, payment_terms_days, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        supplier_id, supplier_code, supplier_name, supplier_type, email, phone, tax_registration_no,
        lead_time_days, payment_terms_days, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE','BLOCKED') then 'INVALID_STATUS'
            when email not like '%@%' then 'INVALID_EMAIL'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_SUPPLIER_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE','BLOCKED')
       or email not like '%@%';

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'SUPPLIER', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE','BLOCKED') then 'INVALID_STATUS'
            when email not like '%@%' then 'INVALID_EMAIL'
            else 'UNKNOWN'
        end,
        object_construct(
            'supplier_id', supplier_id, 'supplier_code', supplier_code, 'supplier_name', supplier_name,
            'supplier_type', supplier_type, 'email', email, 'phone', phone,
            'tax_registration_no', tax_registration_no, 'lead_time_days', lead_time_days,
            'payment_terms_days', payment_terms_days, 'status', status,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_SUPPLIER_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE','BLOCKED')
       or email not like '%@%';

    merge into RETAIL360_DEMO.CLEAN.SUPPLIER t
    using (
        select *
        from TMP_SUPPLIER_STREAM
        where data_quality_flag = 'GOOD'
          and status in ('ACTIVE','INACTIVE','BLOCKED')
          and email like '%@%'
    ) s
    on t.supplier_code = s.supplier_code
    when matched then update set
        supplier_id = s.supplier_id,
        supplier_name = s.supplier_name,
        supplier_type = s.supplier_type,
        email = s.email,
        phone = s.phone,
        tax_registration_no = s.tax_registration_no,
        lead_time_days = s.lead_time_days,
        payment_terms_days = s.payment_terms_days,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        supplier_id, supplier_code, supplier_name, supplier_type, email, phone, tax_registration_no,
        lead_time_days, payment_terms_days, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.supplier_id, s.supplier_code, s.supplier_name, s.supplier_type, s.email, s.phone, s.tax_registration_no,
        s.lead_time_days, s.payment_terms_days, s.status, s.created_at, s.updated_at,
        s.extract_ts, s.batch_id, s.source_system, s.data_quality_flag,
        s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'SUPPLIER stream processed';
end;
$$;


-- 4. STORE

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_STORE_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_STORE_STREAM as
    select
        store_id, store_code, store_name, store_type, channel_type, email, phone,
        address_line_1, address_line_2, city, state, postal_code, country_code,
        open_date, close_date, status, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_STORE_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.STORE_REJECT (
        store_id, store_code, store_name, store_type, channel_type, email, phone,
        address_line_1, address_line_2, city, state, postal_code, country_code,
        open_date, close_date, status, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        reject_reason, rejected_at
    )
    select
        store_id, store_code, store_name, store_type, channel_type, email, phone,
        address_line_1, address_line_2, city, state, postal_code, country_code,
        open_date, close_date, status, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when channel_type not in ('STORE','ONLINE','OMNI') then 'INVALID_CHANNEL_TYPE'
            when store_type not in ('RETAIL','WAREHOUSE','DARK_STORE','FULFILLMENT_CENTER') then 'INVALID_STORE_TYPE'
            when status not in ('ACTIVE','INACTIVE','CLOSED') then 'INVALID_STATUS'
            when postal_code = '###BAD###' then 'INVALID_POSTAL_CODE'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_STORE_STREAM
    where data_quality_flag <> 'GOOD'
       or channel_type not in ('STORE','ONLINE','OMNI')
       or store_type not in ('RETAIL','WAREHOUSE','DARK_STORE','FULFILLMENT_CENTER')
       or status not in ('ACTIVE','INACTIVE','CLOSED')
       or postal_code = '###BAD###';

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'STORE', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when channel_type not in ('STORE','ONLINE','OMNI') then 'INVALID_CHANNEL_TYPE'
            when store_type not in ('RETAIL','WAREHOUSE','DARK_STORE','FULFILLMENT_CENTER') then 'INVALID_STORE_TYPE'
            when status not in ('ACTIVE','INACTIVE','CLOSED') then 'INVALID_STATUS'
            when postal_code = '###BAD###' then 'INVALID_POSTAL_CODE'
            else 'UNKNOWN'
        end,
        object_construct(
            'store_id', store_id, 'store_code', store_code, 'store_name', store_name,
            'store_type', store_type, 'channel_type', channel_type, 'email', email, 'phone', phone,
            'address_line_1', address_line_1, 'address_line_2', address_line_2,
            'city', city, 'state', state, 'postal_code', postal_code, 'country_code', country_code,
            'open_date', open_date, 'close_date', close_date, 'status', status,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_STORE_STREAM
    where data_quality_flag <> 'GOOD'
       or channel_type not in ('STORE','ONLINE','OMNI')
       or store_type not in ('RETAIL','WAREHOUSE','DARK_STORE','FULFILLMENT_CENTER')
       or status not in ('ACTIVE','INACTIVE','CLOSED')
       or postal_code = '###BAD###';

    merge into RETAIL360_DEMO.CLEAN.STORE t
    using (
        select *
        from TMP_STORE_STREAM
        where data_quality_flag = 'GOOD'
          and channel_type in ('STORE','ONLINE','OMNI')
          and store_type in ('RETAIL','WAREHOUSE','DARK_STORE','FULFILLMENT_CENTER')
          and status in ('ACTIVE','INACTIVE','CLOSED')
          and postal_code <> '###BAD###'
    ) s
    on t.store_code = s.store_code
    when matched then update set
        store_id = s.store_id,
        store_name = s.store_name,
        store_type = s.store_type,
        channel_type = s.channel_type,
        email = s.email,
        phone = s.phone,
        address_line_1 = s.address_line_1,
        address_line_2 = s.address_line_2,
        city = s.city,
        state = s.state,
        postal_code = s.postal_code,
        country_code = s.country_code,
        open_date = s.open_date,
        close_date = s.close_date,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        store_id, store_code, store_name, store_type, channel_type, email, phone,
        address_line_1, address_line_2, city, state, postal_code, country_code,
        open_date, close_date, status, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.store_id, s.store_code, s.store_name, s.store_type, s.channel_type, s.email, s.phone,
        s.address_line_1, s.address_line_2, s.city, s.state, s.postal_code, s.country_code,
        s.open_date, s.close_date, s.status, s.created_at, s.updated_at, s.extract_ts, s.batch_id,
        s.source_system, s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'STORE stream processed';
end;
$$;


-- 5. EMPLOYEE

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_EMPLOYEE_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_EMPLOYEE_STREAM as
    select
        employee_id, employee_code, first_name, last_name, email, phone, role_name,
        store_id, manager_employee_id, hire_date, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_EMPLOYEE_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.EMPLOYEE_REJECT (
        employee_id, employee_code, first_name, last_name, email, phone, role_name,
        store_id, manager_employee_id, hire_date, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        reject_reason, rejected_at
    )
    select
        employee_id, employee_code, first_name, last_name, email, phone, role_name,
        store_id, manager_employee_id, hire_date, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE','TERMINATED') then 'INVALID_STATUS'
            when email not like '%@%' then 'INVALID_EMAIL'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_EMPLOYEE_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE','TERMINATED')
       or email not like '%@%';

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'EMPLOYEE', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE','TERMINATED') then 'INVALID_STATUS'
            when email not like '%@%' then 'INVALID_EMAIL'
            else 'UNKNOWN'
        end,
        object_construct(
            'employee_id', employee_id, 'employee_code', employee_code, 'first_name', first_name,
            'last_name', last_name, 'email', email, 'phone', phone, 'role_name', role_name,
            'store_id', store_id, 'manager_employee_id', manager_employee_id, 'hire_date', hire_date,
            'status', status, 'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_EMPLOYEE_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE','TERMINATED')
       or email not like '%@%';

    merge into RETAIL360_DEMO.CLEAN.EMPLOYEE t
    using (
        select *
        from TMP_EMPLOYEE_STREAM
        where data_quality_flag = 'GOOD'
          and status in ('ACTIVE','INACTIVE','TERMINATED')
          and email like '%@%'
    ) s
    on t.employee_code = s.employee_code
    when matched then update set
        employee_id = s.employee_id,
        first_name = s.first_name,
        last_name = s.last_name,
        email = s.email,
        phone = s.phone,
        role_name = s.role_name,
        store_id = s.store_id,
        manager_employee_id = s.manager_employee_id,
        hire_date = s.hire_date,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        employee_id, employee_code, first_name, last_name, email, phone, role_name,
        store_id, manager_employee_id, hire_date, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.employee_id, s.employee_code, s.first_name, s.last_name, s.email, s.phone, s.role_name,
        s.store_id, s.manager_employee_id, s.hire_date, s.status, s.created_at, s.updated_at,
        s.extract_ts, s.batch_id, s.source_system, s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'EMPLOYEE stream processed';
end;
$$;

-- 6. CUSTOMER

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_CUSTOMER_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_CUSTOMER_STREAM as
    select
        customer_id, customer_code, loyalty_id, first_name, last_name, email, phone,
        date_of_birth, gender, registration_date, preferred_channel, marketing_opt_in,
        status, created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_CUSTOMER_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.CUSTOMER_REJECT (
        customer_id, customer_code, loyalty_id, first_name, last_name, email, phone,
        date_of_birth, gender, registration_date, preferred_channel, marketing_opt_in,
        status, created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        customer_id, customer_code, loyalty_id, first_name, last_name, email, phone,
        date_of_birth, gender, registration_date, preferred_channel, marketing_opt_in,
        status, created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE','BLOCKED') then 'INVALID_STATUS'
            when email not like '%@%' then 'INVALID_EMAIL'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_CUSTOMER_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE','BLOCKED')
       or email not like '%@%';

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'CUSTOMER', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE','BLOCKED') then 'INVALID_STATUS'
            when email not like '%@%' then 'INVALID_EMAIL'
            else 'UNKNOWN'
        end,
        object_construct(
            'customer_id', customer_id, 'customer_code', customer_code, 'loyalty_id', loyalty_id,
            'first_name', first_name, 'last_name', last_name, 'email', email, 'phone', phone,
            'date_of_birth', date_of_birth, 'gender', gender, 'registration_date', registration_date,
            'preferred_channel', preferred_channel, 'marketing_opt_in', marketing_opt_in,
            'status', status, 'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_CUSTOMER_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE','BLOCKED')
       or email not like '%@%';

    merge into RETAIL360_DEMO.CLEAN.CUSTOMER t
    using (
        select *
        from TMP_CUSTOMER_STREAM
        where data_quality_flag = 'GOOD'
          and status in ('ACTIVE','INACTIVE','BLOCKED')
          and email like '%@%'
    ) s
    on t.customer_code = s.customer_code
    when matched then update set
        customer_id = s.customer_id,
        loyalty_id = s.loyalty_id,
        first_name = s.first_name,
        last_name = s.last_name,
        email = s.email,
        phone = s.phone,
        date_of_birth = s.date_of_birth,
        gender = s.gender,
        registration_date = s.registration_date,
        preferred_channel = s.preferred_channel,
        marketing_opt_in = s.marketing_opt_in,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        customer_id, customer_code, loyalty_id, first_name, last_name, email, phone,
        date_of_birth, gender, registration_date, preferred_channel, marketing_opt_in,
        status, created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.customer_id, s.customer_code, s.loyalty_id, s.first_name, s.last_name, s.email, s.phone,
        s.date_of_birth, s.gender, s.registration_date, s.preferred_channel, s.marketing_opt_in,
        s.status, s.created_at, s.updated_at, s.extract_ts, s.batch_id, s.source_system,
        s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'CUSTOMER stream processed';
end;
$$;


-- 7. CUSTOMER_ADDRESS

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_CUSTOMER_ADDRESS_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_CUSTOMER_ADDRESS_STREAM as
    select
        customer_address_id, customer_id, address_type, address_line_1, address_line_2,
        city, state, postal_code, country_code, is_default, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_CUSTOMER_ADDRESS_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.CUSTOMER_ADDRESS_REJECT (
        customer_address_id, customer_id, address_type, address_line_1, address_line_2,
        city, state, postal_code, country_code, is_default, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        reject_reason, rejected_at
    )
    select
        customer_address_id, customer_id, address_type, address_line_1, address_line_2,
        city, state, postal_code, country_code, is_default, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when address_type not in ('BILLING','SHIPPING','HOME','OFFICE') then 'INVALID_ADDRESS_TYPE'
            when status not in ('ACTIVE','INACTIVE') then 'INVALID_STATUS'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_CUSTOMER_ADDRESS_STREAM
    where data_quality_flag <> 'GOOD'
       or address_type not in ('BILLING','SHIPPING','HOME','OFFICE')
       or status not in ('ACTIVE','INACTIVE');

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'CUSTOMER_ADDRESS', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when address_type not in ('BILLING','SHIPPING','HOME','OFFICE') then 'INVALID_ADDRESS_TYPE'
            when status not in ('ACTIVE','INACTIVE') then 'INVALID_STATUS'
            else 'UNKNOWN'
        end,
        object_construct(
            'customer_address_id', customer_address_id, 'customer_id', customer_id,
            'address_type', address_type, 'address_line_1', address_line_1, 'address_line_2', address_line_2,
            'city', city, 'state', state, 'postal_code', postal_code, 'country_code', country_code,
            'is_default', is_default, 'status', status, 'created_at', created_at, 'updated_at', updated_at,
            'extract_ts', extract_ts, 'batch_id', batch_id, 'source_system', source_system,
            'data_quality_flag', data_quality_flag, 'src_filename', src_filename,
            'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_CUSTOMER_ADDRESS_STREAM
    where data_quality_flag <> 'GOOD'
       or address_type not in ('BILLING','SHIPPING','HOME','OFFICE')
       or status not in ('ACTIVE','INACTIVE');

    merge into RETAIL360_DEMO.CLEAN.CUSTOMER_ADDRESS t
    using (
        select *
        from TMP_CUSTOMER_ADDRESS_STREAM
        where data_quality_flag = 'GOOD'
          and address_type in ('BILLING','SHIPPING','HOME','OFFICE')
          and status in ('ACTIVE','INACTIVE')
    ) s
    on t.customer_address_id = s.customer_address_id
    when matched then update set
        customer_id = s.customer_id,
        address_type = s.address_type,
        address_line_1 = s.address_line_1,
        address_line_2 = s.address_line_2,
        city = s.city,
        state = s.state,
        postal_code = s.postal_code,
        country_code = s.country_code,
        is_default = s.is_default,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        customer_address_id, customer_id, address_type, address_line_1, address_line_2,
        city, state, postal_code, country_code, is_default, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.customer_address_id, s.customer_id, s.address_type, s.address_line_1, s.address_line_2,
        s.city, s.state, s.postal_code, s.country_code, s.is_default, s.status, s.created_at, s.updated_at,
        s.extract_ts, s.batch_id, s.source_system, s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'CUSTOMER_ADDRESS stream processed';
end;
$$;


-- 8. PRODUCT

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_PRODUCT_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PRODUCT_STREAM as
    select
        product_id, product_code, product_name, brand_id, category_id, description,
        unit_of_measure, status, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_PRODUCT_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.PRODUCT_REJECT (
        product_id, product_code, product_name, brand_id, category_id, description,
        unit_of_measure, status, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        reject_reason, rejected_at
    )
    select
        product_id, product_code, product_name, brand_id, category_id, description,
        unit_of_measure, status, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE','DISCONTINUED') then 'INVALID_STATUS'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_PRODUCT_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE','DISCONTINUED');

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'PRODUCT', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when status not in ('ACTIVE','INACTIVE','DISCONTINUED') then 'INVALID_STATUS'
            else 'UNKNOWN'
        end,
        object_construct(
            'product_id', product_id, 'product_code', product_code, 'product_name', product_name,
            'brand_id', brand_id, 'category_id', category_id, 'description', description,
            'unit_of_measure', unit_of_measure, 'status', status, 'created_at', created_at,
            'updated_at', updated_at, 'extract_ts', extract_ts, 'batch_id', batch_id,
            'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_PRODUCT_STREAM
    where data_quality_flag <> 'GOOD'
       or status not in ('ACTIVE','INACTIVE','DISCONTINUED');

    merge into RETAIL360_DEMO.CLEAN.PRODUCT t
    using (
        select *
        from TMP_PRODUCT_STREAM
        where data_quality_flag = 'GOOD'
          and status in ('ACTIVE','INACTIVE','DISCONTINUED')
    ) s
    on t.product_code = s.product_code
    when matched then update set
        product_id = s.product_id,
        product_name = s.product_name,
        brand_id = s.brand_id,
        category_id = s.category_id,
        description = s.description,
        unit_of_measure = s.unit_of_measure,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        product_id, product_code, product_name, brand_id, category_id, description,
        unit_of_measure, status, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.product_id, s.product_code, s.product_name, s.brand_id, s.category_id, s.description,
        s.unit_of_measure, s.status, s.created_at, s.updated_at, s.extract_ts, s.batch_id,
        s.source_system, s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'PRODUCT stream processed';
end;
$$;


-- 9. PRODUCT_SKU

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_PRODUCT_SKU_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PRODUCT_SKU_STREAM as
    select
        sku_id, product_id, sku_code, barcode, color, size, style, pack_size,
        standard_cost, list_price, status, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_PRODUCT_SKU_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.PRODUCT_SKU_REJECT (
        sku_id, product_id, sku_code, barcode, color, size, style, pack_size,
        standard_cost, list_price, status, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        reject_reason, rejected_at
    )
    select
        sku_id, product_id, sku_code, barcode, color, size, style, pack_size,
        standard_cost, list_price, status, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when standard_cost < 0 then 'NEGATIVE_STANDARD_COST'
            when list_price < 0 then 'NEGATIVE_LIST_PRICE'
            when status not in ('ACTIVE','INACTIVE','DISCONTINUED') then 'INVALID_STATUS'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_PRODUCT_SKU_STREAM
    where data_quality_flag <> 'GOOD'
       or standard_cost < 0
       or list_price < 0
       or status not in ('ACTIVE','INACTIVE','DISCONTINUED');

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'PRODUCT_SKU', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when standard_cost < 0 then 'NEGATIVE_STANDARD_COST'
            when list_price < 0 then 'NEGATIVE_LIST_PRICE'
            when status not in ('ACTIVE','INACTIVE','DISCONTINUED') then 'INVALID_STATUS'
            else 'UNKNOWN'
        end,
        object_construct(
            'sku_id', sku_id, 'product_id', product_id, 'sku_code', sku_code, 'barcode', barcode,
            'color', color, 'size', size, 'style', style, 'pack_size', pack_size,
            'standard_cost', standard_cost, 'list_price', list_price, 'status', status,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_PRODUCT_SKU_STREAM
    where data_quality_flag <> 'GOOD'
       or standard_cost < 0
       or list_price < 0
       or status not in ('ACTIVE','INACTIVE','DISCONTINUED');

    merge into RETAIL360_DEMO.CLEAN.PRODUCT_SKU t
    using (
        select *
        from TMP_PRODUCT_SKU_STREAM
        where data_quality_flag = 'GOOD'
          and standard_cost >= 0
          and list_price >= 0
          and status in ('ACTIVE','INACTIVE','DISCONTINUED')
    ) s
    on t.sku_code = s.sku_code
    when matched then update set
        sku_id = s.sku_id,
        product_id = s.product_id,
        barcode = s.barcode,
        color = s.color,
        size = s.size,
        style = s.style,
        pack_size = s.pack_size,
        standard_cost = s.standard_cost,
        list_price = s.list_price,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        sku_id, product_id, sku_code, barcode, color, size, style, pack_size,
        standard_cost, list_price, status, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.sku_id, s.product_id, s.sku_code, s.barcode, s.color, s.size, s.style, s.pack_size,
        s.standard_cost, s.list_price, s.status, s.created_at, s.updated_at, s.extract_ts,
        s.batch_id, s.source_system, s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'PRODUCT_SKU stream processed';
end;
$$;


-- 10. PROMOTION

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_PROMOTION_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PROMOTION_STREAM as
    select
        promotion_id, promotion_code, promotion_name, promotion_type, discount_type,
        discount_value, start_datetime, end_datetime, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_PROMOTION_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.PROMOTION_REJECT (
        promotion_id, promotion_code, promotion_name, promotion_type, discount_type,
        discount_value, start_datetime, end_datetime, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        reject_reason, rejected_at
    )
    select
        promotion_id, promotion_code, promotion_name, promotion_type, discount_type,
        discount_value, start_datetime, end_datetime, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when promotion_type not in ('ORDER','LINE','COUPON','SEASONAL','LOYALTY') then 'INVALID_PROMOTION_TYPE'
            when discount_type not in ('PERCENT','AMOUNT') then 'INVALID_DISCOUNT_TYPE'
            when discount_value < 0 then 'NEGATIVE_DISCOUNT_VALUE'
            when status not in ('ACTIVE','INACTIVE','EXPIRED') then 'INVALID_STATUS'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_PROMOTION_STREAM
    where data_quality_flag <> 'GOOD'
       or promotion_type not in ('ORDER','LINE','COUPON','SEASONAL','LOYALTY')
       or discount_type not in ('PERCENT','AMOUNT')
       or discount_value < 0
       or status not in ('ACTIVE','INACTIVE','EXPIRED');

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'PROMOTION', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when promotion_type not in ('ORDER','LINE','COUPON','SEASONAL','LOYALTY') then 'INVALID_PROMOTION_TYPE'
            when discount_type not in ('PERCENT','AMOUNT') then 'INVALID_DISCOUNT_TYPE'
            when discount_value < 0 then 'NEGATIVE_DISCOUNT_VALUE'
            when status not in ('ACTIVE','INACTIVE','EXPIRED') then 'INVALID_STATUS'
            else 'UNKNOWN'
        end,
        object_construct(
            'promotion_id', promotion_id, 'promotion_code', promotion_code, 'promotion_name', promotion_name,
            'promotion_type', promotion_type, 'discount_type', discount_type, 'discount_value', discount_value,
            'start_datetime', start_datetime, 'end_datetime', end_datetime, 'status', status,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_PROMOTION_STREAM
    where data_quality_flag <> 'GOOD'
       or promotion_type not in ('ORDER','LINE','COUPON','SEASONAL','LOYALTY')
       or discount_type not in ('PERCENT','AMOUNT')
       or discount_value < 0
       or status not in ('ACTIVE','INACTIVE','EXPIRED');

    merge into RETAIL360_DEMO.CLEAN.PROMOTION t
    using (
        select *
        from TMP_PROMOTION_STREAM
        where data_quality_flag = 'GOOD'
          and promotion_type in ('ORDER','LINE','COUPON','SEASONAL','LOYALTY')
          and discount_type in ('PERCENT','AMOUNT')
          and discount_value >= 0
          and status in ('ACTIVE','INACTIVE','EXPIRED')
    ) s
    on t.promotion_code = s.promotion_code
    when matched then update set
        promotion_id = s.promotion_id,
        promotion_name = s.promotion_name,
        promotion_type = s.promotion_type,
        discount_type = s.discount_type,
        discount_value = s.discount_value,
        start_datetime = s.start_datetime,
        end_datetime = s.end_datetime,
        status = s.status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        promotion_id, promotion_code, promotion_name, promotion_type, discount_type,
        discount_value, start_datetime, end_datetime, status, created_at, updated_at,
        extract_ts, batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.promotion_id, s.promotion_code, s.promotion_name, s.promotion_type, s.discount_type,
        s.discount_value, s.start_datetime, s.end_datetime, s.status, s.created_at, s.updated_at,
        s.extract_ts, s.batch_id, s.source_system, s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'PROMOTION stream processed';
end;
$$;


-- 11. PROMOTION_PRODUCT

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_PROMOTION_PRODUCT_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PROMOTION_PRODUCT_STREAM as
    select
        promotion_id, sku_id, created_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_PROMOTION_PRODUCT_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.PROMOTION_PRODUCT_REJECT (
        promotion_id, sku_id, created_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        promotion_id, sku_id, created_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_PROMOTION_PRODUCT_STREAM
    where data_quality_flag <> 'GOOD';

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'PROMOTION_PRODUCT', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            else 'UNKNOWN'
        end,
        object_construct(
            'promotion_id', promotion_id, 'sku_id', sku_id, 'created_at', created_at,
            'extract_ts', extract_ts, 'batch_id', batch_id, 'source_system', source_system,
            'data_quality_flag', data_quality_flag, 'src_filename', src_filename,
            'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_PROMOTION_PRODUCT_STREAM
    where data_quality_flag <> 'GOOD';

    merge into RETAIL360_DEMO.CLEAN.PROMOTION_PRODUCT t
    using (
        select *
        from TMP_PROMOTION_PRODUCT_STREAM
        where data_quality_flag = 'GOOD'
    ) s
    on t.promotion_id = s.promotion_id and t.sku_id = s.sku_id
    when matched then update set
        created_at = s.created_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        promotion_id, sku_id, created_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.promotion_id, s.sku_id, s.created_at, s.extract_ts, s.batch_id, s.source_system,
        s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'PROMOTION_PRODUCT stream processed';
end;
$$;


-- 12. PROMOTION_STORE

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_PROMOTION_STORE_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PROMOTION_STORE_STREAM as
    select
        promotion_id, store_id, created_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_PROMOTION_STORE_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.PROMOTION_STORE_REJECT (
        promotion_id, store_id, created_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        promotion_id, store_id, created_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_PROMOTION_STORE_STREAM
    where data_quality_flag <> 'GOOD';

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'PROMOTION_STORE', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            else 'UNKNOWN'
        end,
        object_construct(
            'promotion_id', promotion_id, 'store_id', store_id, 'created_at', created_at,
            'extract_ts', extract_ts, 'batch_id', batch_id, 'source_system', source_system,
            'data_quality_flag', data_quality_flag, 'src_filename', src_filename,
            'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_PROMOTION_STORE_STREAM
    where data_quality_flag <> 'GOOD';

    merge into RETAIL360_DEMO.CLEAN.PROMOTION_STORE t
    using (
        select *
        from TMP_PROMOTION_STORE_STREAM
        where data_quality_flag = 'GOOD'
    ) s
    on t.promotion_id = s.promotion_id and t.store_id = s.store_id
    when matched then update set
        created_at = s.created_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        promotion_id, store_id, created_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.promotion_id, s.store_id, s.created_at, s.extract_ts, s.batch_id, s.source_system,
        s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'PROMOTION_STORE stream processed';
end;
$$;


-- 13. SALES_ORDER

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_SALES_ORDER_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_SALES_ORDER_STREAM as
    select
        sales_order_id, order_number, customer_id, store_id, sales_channel, order_datetime,
        order_status, currency_code, billing_address_id, shipping_address_id, cashier_employee_id,
        subtotal_amount, discount_amount, tax_amount, shipping_amount, total_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_SALES_ORDER_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.SALES_ORDER_REJECT (
        sales_order_id, order_number, customer_id, store_id, sales_channel, order_datetime,
        order_status, currency_code, billing_address_id, shipping_address_id, cashier_employee_id,
        subtotal_amount, discount_amount, tax_amount, shipping_amount, total_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        sales_order_id, order_number, customer_id, store_id, sales_channel, order_datetime,
        order_status, currency_code, billing_address_id, shipping_address_id, cashier_employee_id,
        subtotal_amount, discount_amount, tax_amount, shipping_amount, total_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts,
        case
            when data_quality_flag is null then 'MISSING_DATA_QUALITY_FLAG'
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when sales_channel is null then 'MISSING_SALES_CHANNEL'
            when sales_channel not in ('STORE','WEB','APP','MARKETPLACE') then 'INVALID_SALES_CHANNEL'
            when order_status is null then 'MISSING_ORDER_STATUS'
            when order_status not in ('CREATED','CONFIRMED','PAID','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED') then 'INVALID_ORDER_STATUS'
            when total_amount is null then 'MISSING_TOTAL_AMOUNT'
            when total_amount < 0 then 'NEGATIVE_TOTAL_AMOUNT'
            when store_id is null then 'MISSING_STORE_ID'
            when store_id = 99999999 then 'INVALID_STORE_ID'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_SALES_ORDER_STREAM
    where data_quality_flag is null
       or data_quality_flag <> 'GOOD'
       or sales_channel is null
       or sales_channel not in ('STORE','WEB','APP','MARKETPLACE')
       or order_status is null
       or order_status not in ('CREATED','CONFIRMED','PAID','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED')
       or total_amount is null
       or total_amount < 0
       or store_id is null
       or store_id = 99999999;

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'SALES_ORDER', src_filename, src_row_number,
        case
            when data_quality_flag is null then 'MISSING_DATA_QUALITY_FLAG'
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when sales_channel is null then 'MISSING_SALES_CHANNEL'
            when sales_channel not in ('STORE','WEB','APP','MARKETPLACE') then 'INVALID_SALES_CHANNEL'
            when order_status is null then 'MISSING_ORDER_STATUS'
            when order_status not in ('CREATED','CONFIRMED','PAID','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED') then 'INVALID_ORDER_STATUS'
            when total_amount is null then 'MISSING_TOTAL_AMOUNT'
            when total_amount < 0 then 'NEGATIVE_TOTAL_AMOUNT'
            when store_id is null then 'MISSING_STORE_ID'
            when store_id = 99999999 then 'INVALID_STORE_ID'
            else 'UNKNOWN'
        end,
        object_construct(
            'sales_order_id', sales_order_id,
            'order_number', order_number,
            'customer_id', customer_id,
            'store_id', store_id,
            'sales_channel', sales_channel,
            'order_datetime', order_datetime,
            'order_status', order_status,
            'currency_code', currency_code,
            'billing_address_id', billing_address_id,
            'shipping_address_id', shipping_address_id,
            'cashier_employee_id', cashier_employee_id,
            'subtotal_amount', subtotal_amount,
            'discount_amount', discount_amount,
            'tax_amount', tax_amount,
            'shipping_amount', shipping_amount,
            'total_amount', total_amount,
            'created_at', created_at,
            'updated_at', updated_at,
            'extract_ts', extract_ts,
            'batch_id', batch_id,
            'source_system', source_system,
            'data_quality_flag', data_quality_flag,
            'src_filename', src_filename,
            'src_row_number', src_row_number,
            'load_ts', load_ts
        )
    from TMP_SALES_ORDER_STREAM
    where data_quality_flag is null
       or data_quality_flag <> 'GOOD'
       or sales_channel is null
       or sales_channel not in ('STORE','WEB','APP','MARKETPLACE')
       or order_status is null
       or order_status not in ('CREATED','CONFIRMED','PAID','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED')
       or total_amount is null
       or total_amount < 0
       or store_id is null
       or store_id = 99999999;

    merge into RETAIL360_DEMO.CLEAN.SALES_ORDER t
    using (
        select *
        from TMP_SALES_ORDER_STREAM
        where data_quality_flag = 'GOOD'
          and sales_channel is not null
          and sales_channel in ('STORE','WEB','APP','MARKETPLACE')
          and order_status is not null
          and order_status in ('CREATED','CONFIRMED','PAID','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED')
          and total_amount is not null
          and total_amount >= 0
          and store_id is not null
          and store_id <> 99999999
    ) s
    on t.order_number = s.order_number
    when matched then update set
        sales_order_id = s.sales_order_id,
        customer_id = s.customer_id,
        store_id = s.store_id,
        sales_channel = s.sales_channel,
        order_datetime = s.order_datetime,
        order_status = s.order_status,
        currency_code = s.currency_code,
        billing_address_id = s.billing_address_id,
        shipping_address_id = s.shipping_address_id,
        cashier_employee_id = s.cashier_employee_id,
        subtotal_amount = s.subtotal_amount,
        discount_amount = s.discount_amount,
        tax_amount = s.tax_amount,
        shipping_amount = s.shipping_amount,
        total_amount = s.total_amount,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        sales_order_id, order_number, customer_id, store_id, sales_channel, order_datetime,
        order_status, currency_code, billing_address_id, shipping_address_id, cashier_employee_id,
        subtotal_amount, discount_amount, tax_amount, shipping_amount, total_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.sales_order_id, s.order_number, s.customer_id, s.store_id, s.sales_channel, s.order_datetime,
        s.order_status, s.currency_code, s.billing_address_id, s.shipping_address_id, s.cashier_employee_id,
        s.subtotal_amount, s.discount_amount, s.tax_amount, s.shipping_amount, s.total_amount,
        s.created_at, s.updated_at, s.extract_ts, s.batch_id, s.source_system, s.data_quality_flag,
        s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'SALES_ORDER stream processed';
end;
$$;


-- 14. SALES_ORDER_LINE

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_SALES_ORDER_LINE_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_SALES_ORDER_LINE_STREAM as
    select
        sales_order_line_id, sales_order_id, line_number, sku_id, promotion_id,
        ordered_quantity, unit_list_price, unit_selling_price, line_discount_amount,
        tax_amount, line_total_amount, fulfillment_store_id, line_status,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_SALES_ORDER_LINE_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.SALES_ORDER_LINE_REJECT (
        sales_order_line_id, sales_order_id, line_number, sku_id, promotion_id,
        ordered_quantity, unit_list_price, unit_selling_price, line_discount_amount,
        tax_amount, line_total_amount, fulfillment_store_id, line_status,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        sales_order_line_id, sales_order_id, line_number, sku_id, promotion_id,
        ordered_quantity, unit_list_price, unit_selling_price, line_discount_amount,
        tax_amount, line_total_amount, fulfillment_store_id, line_status,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when ordered_quantity <= 0 then 'INVALID_ORDERED_QUANTITY'
            when sku_id = 99999999 then 'INVALID_SKU_ID'
            when line_status not in ('CREATED','ALLOCATED','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED') then 'INVALID_LINE_STATUS'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_SALES_ORDER_LINE_STREAM
    where data_quality_flag <> 'GOOD'
       or ordered_quantity <= 0
       or sku_id = 99999999
       or line_status not in ('CREATED','ALLOCATED','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED');

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'SALES_ORDER_LINE', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when ordered_quantity <= 0 then 'INVALID_ORDERED_QUANTITY'
            when sku_id = 99999999 then 'INVALID_SKU_ID'
            when line_status not in ('CREATED','ALLOCATED','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED') then 'INVALID_LINE_STATUS'
            else 'UNKNOWN'
        end,
        object_construct(
            'sales_order_line_id', sales_order_line_id, 'sales_order_id', sales_order_id,
            'line_number', line_number, 'sku_id', sku_id, 'promotion_id', promotion_id,
            'ordered_quantity', ordered_quantity, 'unit_list_price', unit_list_price,
            'unit_selling_price', unit_selling_price, 'line_discount_amount', line_discount_amount,
            'tax_amount', tax_amount, 'line_total_amount', line_total_amount,
            'fulfillment_store_id', fulfillment_store_id, 'line_status', line_status,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_SALES_ORDER_LINE_STREAM
    where data_quality_flag <> 'GOOD'
       or ordered_quantity <= 0
       or sku_id = 99999999
       or line_status not in ('CREATED','ALLOCATED','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED');

    merge into RETAIL360_DEMO.CLEAN.SALES_ORDER_LINE t
    using (
        select *
        from TMP_SALES_ORDER_LINE_STREAM
        where data_quality_flag = 'GOOD'
          and ordered_quantity > 0
          and sku_id <> 99999999
          and line_status in ('CREATED','ALLOCATED','FULFILLED','CANCELLED','RETURNED','PARTIALLY_RETURNED')
    ) s
    on t.sales_order_line_id = s.sales_order_line_id
    when matched then update set
        sales_order_id = s.sales_order_id,
        line_number = s.line_number,
        sku_id = s.sku_id,
        promotion_id = s.promotion_id,
        ordered_quantity = s.ordered_quantity,
        unit_list_price = s.unit_list_price,
        unit_selling_price = s.unit_selling_price,
        line_discount_amount = s.line_discount_amount,
        tax_amount = s.tax_amount,
        line_total_amount = s.line_total_amount,
        fulfillment_store_id = s.fulfillment_store_id,
        line_status = s.line_status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        sales_order_line_id, sales_order_id, line_number, sku_id, promotion_id,
        ordered_quantity, unit_list_price, unit_selling_price, line_discount_amount,
        tax_amount, line_total_amount, fulfillment_store_id, line_status,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.sales_order_line_id, s.sales_order_id, s.line_number, s.sku_id, s.promotion_id,
        s.ordered_quantity, s.unit_list_price, s.unit_selling_price, s.line_discount_amount,
        s.tax_amount, s.line_total_amount, s.fulfillment_store_id, s.line_status,
        s.created_at, s.updated_at, s.extract_ts, s.batch_id, s.source_system,
        s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'SALES_ORDER_LINE stream processed';
end;
$$;


-- 15. PAYMENT

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_PAYMENT_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PAYMENT_STREAM as
    select
        payment_id, sales_order_id, payment_reference, payment_method, payment_status,
        amount, payment_datetime, currency_code, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_PAYMENT_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.PAYMENT_REJECT (
        payment_id, sales_order_id, payment_reference, payment_method, payment_status,
        amount, payment_datetime, currency_code, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        reject_reason, rejected_at
    )
    select
        payment_id, sales_order_id, payment_reference, payment_method, payment_status,
        amount, payment_datetime, currency_code, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when payment_method not in ('CASH','CARD','UPI','NETBANKING','WALLET','GIFT_CARD') then 'INVALID_PAYMENT_METHOD'
            when payment_status not in ('INITIATED','AUTHORIZED','CAPTURED','FAILED','REFUNDED','PARTIALLY_REFUNDED') then 'INVALID_PAYMENT_STATUS'
            when amount < 0 then 'NEGATIVE_AMOUNT'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_PAYMENT_STREAM
    where data_quality_flag <> 'GOOD'
       or payment_method not in ('CASH','CARD','UPI','NETBANKING','WALLET','GIFT_CARD')
       or payment_status not in ('INITIATED','AUTHORIZED','CAPTURED','FAILED','REFUNDED','PARTIALLY_REFUNDED')
       or amount < 0;

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'PAYMENT', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when payment_method not in ('CASH','CARD','UPI','NETBANKING','WALLET','GIFT_CARD') then 'INVALID_PAYMENT_METHOD'
            when payment_status not in ('INITIATED','AUTHORIZED','CAPTURED','FAILED','REFUNDED','PARTIALLY_REFUNDED') then 'INVALID_PAYMENT_STATUS'
            when amount < 0 then 'NEGATIVE_AMOUNT'
            else 'UNKNOWN'
        end,
        object_construct(
            'payment_id', payment_id, 'sales_order_id', sales_order_id, 'payment_reference', payment_reference,
            'payment_method', payment_method, 'payment_status', payment_status, 'amount', amount,
            'payment_datetime', payment_datetime, 'currency_code', currency_code,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_PAYMENT_STREAM
    where data_quality_flag <> 'GOOD'
       or payment_method not in ('CASH','CARD','UPI','NETBANKING','WALLET','GIFT_CARD')
       or payment_status not in ('INITIATED','AUTHORIZED','CAPTURED','FAILED','REFUNDED','PARTIALLY_REFUNDED')
       or amount < 0;

    merge into RETAIL360_DEMO.CLEAN.PAYMENT t
    using (
        select *
        from TMP_PAYMENT_STREAM
        where data_quality_flag = 'GOOD'
          and payment_method in ('CASH','CARD','UPI','NETBANKING','WALLET','GIFT_CARD')
          and payment_status in ('INITIATED','AUTHORIZED','CAPTURED','FAILED','REFUNDED','PARTIALLY_REFUNDED')
          and amount >= 0
    ) s
    on t.payment_reference = s.payment_reference
    when matched then update set
        payment_id = s.payment_id,
        sales_order_id = s.sales_order_id,
        payment_method = s.payment_method,
        payment_status = s.payment_status,
        amount = s.amount,
        payment_datetime = s.payment_datetime,
        currency_code = s.currency_code,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        payment_id, sales_order_id, payment_reference, payment_method, payment_status,
        amount, payment_datetime, currency_code, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.payment_id, s.sales_order_id, s.payment_reference, s.payment_method, s.payment_status,
        s.amount, s.payment_datetime, s.currency_code, s.created_at, s.updated_at, s.extract_ts,
        s.batch_id, s.source_system, s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'PAYMENT stream processed';
end;
$$;


-- 16. SHIPMENT

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_SHIPMENT_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_SHIPMENT_STREAM as
    select
        shipment_id, sales_order_id, shipment_number, shipping_store_id, shipment_status,
        carrier_name, tracking_number, shipped_datetime, delivered_datetime, shipping_address_id,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_SHIPMENT_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.SHIPMENT_REJECT (
        shipment_id, sales_order_id, shipment_number, shipping_store_id, shipment_status,
        carrier_name, tracking_number, shipped_datetime, delivered_datetime, shipping_address_id,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        shipment_id, sales_order_id, shipment_number, shipping_store_id, shipment_status,
        carrier_name, tracking_number, shipped_datetime, delivered_datetime, shipping_address_id,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when shipment_status not in ('CREATED','PACKED','SHIPPED','DELIVERED','CANCELLED','RETURN_IN_TRANSIT') then 'INVALID_SHIPMENT_STATUS'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_SHIPMENT_STREAM
    where data_quality_flag <> 'GOOD'
       or shipment_status not in ('CREATED','PACKED','SHIPPED','DELIVERED','CANCELLED','RETURN_IN_TRANSIT');

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'SHIPMENT', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when shipment_status not in ('CREATED','PACKED','SHIPPED','DELIVERED','CANCELLED','RETURN_IN_TRANSIT') then 'INVALID_SHIPMENT_STATUS'
            else 'UNKNOWN'
        end,
        object_construct(
            'shipment_id', shipment_id, 'sales_order_id', sales_order_id, 'shipment_number', shipment_number,
            'shipping_store_id', shipping_store_id, 'shipment_status', shipment_status,
            'carrier_name', carrier_name, 'tracking_number', tracking_number,
            'shipped_datetime', shipped_datetime, 'delivered_datetime', delivered_datetime,
            'shipping_address_id', shipping_address_id, 'created_at', created_at, 'updated_at', updated_at,
            'extract_ts', extract_ts, 'batch_id', batch_id, 'source_system', source_system,
            'data_quality_flag', data_quality_flag, 'src_filename', src_filename,
            'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_SHIPMENT_STREAM
    where data_quality_flag <> 'GOOD'
       or shipment_status not in ('CREATED','PACKED','SHIPPED','DELIVERED','CANCELLED','RETURN_IN_TRANSIT');

    merge into RETAIL360_DEMO.CLEAN.SHIPMENT t
    using (
        select *
        from TMP_SHIPMENT_STREAM
        where data_quality_flag = 'GOOD'
          and shipment_status in ('CREATED','PACKED','SHIPPED','DELIVERED','CANCELLED','RETURN_IN_TRANSIT')
    ) s
    on t.shipment_number = s.shipment_number
    when matched then update set
        shipment_id = s.shipment_id,
        sales_order_id = s.sales_order_id,
        shipping_store_id = s.shipping_store_id,
        shipment_status = s.shipment_status,
        carrier_name = s.carrier_name,
        tracking_number = s.tracking_number,
        shipped_datetime = s.shipped_datetime,
        delivered_datetime = s.delivered_datetime,
        shipping_address_id = s.shipping_address_id,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        shipment_id, sales_order_id, shipment_number, shipping_store_id, shipment_status,
        carrier_name, tracking_number, shipped_datetime, delivered_datetime, shipping_address_id,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.shipment_id, s.sales_order_id, s.shipment_number, s.shipping_store_id, s.shipment_status,
        s.carrier_name, s.tracking_number, s.shipped_datetime, s.delivered_datetime, s.shipping_address_id,
        s.created_at, s.updated_at, s.extract_ts, s.batch_id, s.source_system, s.data_quality_flag,
        s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'SHIPMENT stream processed';
end;
$$;


-- 17. RETURN_ORDER

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_RETURN_ORDER_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_RETURN_ORDER_STREAM as
    select
        return_order_id, return_number, original_sales_order_id, customer_id, store_id,
        return_channel, return_datetime, return_status, refund_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_RETURN_ORDER_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.RETURN_ORDER_REJECT (
        return_order_id, return_number, original_sales_order_id, customer_id, store_id,
        return_channel, return_datetime, return_status, refund_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        return_order_id, return_number, original_sales_order_id, customer_id, store_id,
        return_channel, return_datetime, return_status, refund_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts,
        case
            when data_quality_flag is null then 'MISSING_DATA_QUALITY_FLAG'
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when return_channel is null then 'MISSING_RETURN_CHANNEL'
            when return_channel not in ('STORE','WEB','APP','MARKETPLACE') then 'INVALID_RETURN_CHANNEL'
            when return_status is null then 'MISSING_RETURN_STATUS'
            when return_status not in ('CREATED','APPROVED','REJECTED','COMPLETED') then 'INVALID_RETURN_STATUS'
            when refund_amount is null then 'MISSING_REFUND_AMOUNT'
            when refund_amount < 0 then 'NEGATIVE_REFUND_AMOUNT'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_RETURN_ORDER_STREAM
    where data_quality_flag is null
       or data_quality_flag <> 'GOOD'
       or return_channel is null
       or return_channel not in ('STORE','WEB','APP','MARKETPLACE')
       or return_status is null
       or return_status not in ('CREATED','APPROVED','REJECTED','COMPLETED')
       or refund_amount is null
       or refund_amount < 0;

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'RETURN_ORDER', src_filename, src_row_number,
        case
            when data_quality_flag is null then 'MISSING_DATA_QUALITY_FLAG'
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when return_channel is null then 'MISSING_RETURN_CHANNEL'
            when return_channel not in ('STORE','WEB','APP','MARKETPLACE') then 'INVALID_RETURN_CHANNEL'
            when return_status is null then 'MISSING_RETURN_STATUS'
            when return_status not in ('CREATED','APPROVED','REJECTED','COMPLETED') then 'INVALID_RETURN_STATUS'
            when refund_amount is null then 'MISSING_REFUND_AMOUNT'
            when refund_amount < 0 then 'NEGATIVE_REFUND_AMOUNT'
            else 'UNKNOWN'
        end,
        object_construct(
            'return_order_id', return_order_id,
            'return_number', return_number,
            'original_sales_order_id', original_sales_order_id,
            'customer_id', customer_id,
            'store_id', store_id,
            'return_channel', return_channel,
            'return_datetime', return_datetime,
            'return_status', return_status,
            'refund_amount', refund_amount,
            'created_at', created_at,
            'updated_at', updated_at,
            'extract_ts', extract_ts,
            'batch_id', batch_id,
            'source_system', source_system,
            'data_quality_flag', data_quality_flag,
            'src_filename', src_filename,
            'src_row_number', src_row_number,
            'load_ts', load_ts
        )
    from TMP_RETURN_ORDER_STREAM
    where data_quality_flag is null
       or data_quality_flag <> 'GOOD'
       or return_channel is null
       or return_channel not in ('STORE','WEB','APP','MARKETPLACE')
       or return_status is null
       or return_status not in ('CREATED','APPROVED','REJECTED','COMPLETED')
       or refund_amount is null
       or refund_amount < 0;

    merge into RETAIL360_DEMO.CLEAN.RETURN_ORDER t
    using (
        select *
        from TMP_RETURN_ORDER_STREAM
        where data_quality_flag = 'GOOD'
          and return_channel is not null
          and return_channel in ('STORE','WEB','APP','MARKETPLACE')
          and return_status is not null
          and return_status in ('CREATED','APPROVED','REJECTED','COMPLETED')
          and refund_amount is not null
          and refund_amount >= 0
    ) s
    on t.return_number = s.return_number
    when matched then update set
        return_order_id = s.return_order_id,
        original_sales_order_id = s.original_sales_order_id,
        customer_id = s.customer_id,
        store_id = s.store_id,
        return_channel = s.return_channel,
        return_datetime = s.return_datetime,
        return_status = s.return_status,
        refund_amount = s.refund_amount,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        return_order_id, return_number, original_sales_order_id, customer_id, store_id,
        return_channel, return_datetime, return_status, refund_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.return_order_id, s.return_number, s.original_sales_order_id, s.customer_id, s.store_id,
        s.return_channel, s.return_datetime, s.return_status, s.refund_amount,
        s.created_at, s.updated_at, s.extract_ts, s.batch_id, s.source_system, s.data_quality_flag,
        s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'RETURN_ORDER stream processed';
end;
$$;


-- 18. RETURN_ORDER_LINE

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_RETURN_ORDER_LINE_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_RETURN_ORDER_LINE_STREAM as
    select
        return_order_line_id, return_order_id, original_sales_order_line_id,
        line_number, return_reason_code, returned_quantity, refund_amount,
        restockable_flag, line_status, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_RETURN_ORDER_LINE_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.RETURN_ORDER_LINE_REJECT (
        return_order_line_id, return_order_id, original_sales_order_line_id,
        line_number, return_reason_code, returned_quantity, refund_amount,
        restockable_flag, line_status, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        reject_reason, rejected_at
    )
    select
        return_order_line_id, return_order_id, original_sales_order_line_id,
        line_number, return_reason_code, returned_quantity, refund_amount,
        restockable_flag, line_status, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when returned_quantity <= 0 then 'INVALID_RETURNED_QUANTITY'
            when refund_amount < 0 then 'NEGATIVE_REFUND_AMOUNT'
            when line_status not in ('CREATED','APPROVED','REJECTED','RESTOCKED','SCRAPPED','COMPLETED') then 'INVALID_LINE_STATUS'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_RETURN_ORDER_LINE_STREAM
    where data_quality_flag <> 'GOOD'
       or returned_quantity <= 0
       or refund_amount < 0
       or line_status not in ('CREATED','APPROVED','REJECTED','RESTOCKED','SCRAPPED','COMPLETED');

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'RETURN_ORDER_LINE', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when returned_quantity <= 0 then 'INVALID_RETURNED_QUANTITY'
            when refund_amount < 0 then 'NEGATIVE_REFUND_AMOUNT'
            when line_status not in ('CREATED','APPROVED','REJECTED','RESTOCKED','SCRAPPED','COMPLETED') then 'INVALID_LINE_STATUS'
            else 'UNKNOWN'
        end,
        object_construct(
            'return_order_line_id', return_order_line_id, 'return_order_id', return_order_id,
            'original_sales_order_line_id', original_sales_order_line_id, 'line_number', line_number,
            'return_reason_code', return_reason_code, 'returned_quantity', returned_quantity,
            'refund_amount', refund_amount, 'restockable_flag', restockable_flag, 'line_status', line_status,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_RETURN_ORDER_LINE_STREAM
    where data_quality_flag <> 'GOOD'
       or returned_quantity <= 0
       or refund_amount < 0
       or line_status not in ('CREATED','APPROVED','REJECTED','RESTOCKED','SCRAPPED','COMPLETED');

    merge into RETAIL360_DEMO.CLEAN.RETURN_ORDER_LINE t
    using (
        select *
        from TMP_RETURN_ORDER_LINE_STREAM
        where data_quality_flag = 'GOOD'
          and returned_quantity > 0
          and refund_amount >= 0
          and line_status in ('CREATED','APPROVED','REJECTED','RESTOCKED','SCRAPPED','COMPLETED')
    ) s
    on t.return_order_line_id = s.return_order_line_id
    when matched then update set
        return_order_id = s.return_order_id,
        original_sales_order_line_id = s.original_sales_order_line_id,
        line_number = s.line_number,
        return_reason_code = s.return_reason_code,
        returned_quantity = s.returned_quantity,
        refund_amount = s.refund_amount,
        restockable_flag = s.restockable_flag,
        line_status = s.line_status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        return_order_line_id, return_order_id, original_sales_order_line_id,
        line_number, return_reason_code, returned_quantity, refund_amount,
        restockable_flag, line_status, created_at, updated_at, extract_ts,
        batch_id, source_system, data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.return_order_line_id, s.return_order_id, s.original_sales_order_line_id,
        s.line_number, s.return_reason_code, s.returned_quantity, s.refund_amount,
        s.restockable_flag, s.line_status, s.created_at, s.updated_at, s.extract_ts,
        s.batch_id, s.source_system, s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'RETURN_ORDER_LINE stream processed';
end;
$$;


-- 19. PURCHASE_ORDER

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_PURCHASE_ORDER_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PURCHASE_ORDER_STREAM as
    select
        purchase_order_id, po_number, supplier_id, destination_store_id, order_datetime,
        expected_delivery_date, po_status, currency_code, subtotal_amount, tax_amount, total_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_PURCHASE_ORDER_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.PURCHASE_ORDER_REJECT (
        purchase_order_id, po_number, supplier_id, destination_store_id, order_datetime,
        expected_delivery_date, po_status, currency_code, subtotal_amount, tax_amount, total_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        purchase_order_id, po_number, supplier_id, destination_store_id, order_datetime,
        expected_delivery_date, po_status, currency_code, subtotal_amount, tax_amount, total_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when po_status not in ('CREATED','APPROVED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED') then 'INVALID_PO_STATUS'
            when subtotal_amount < 0 or tax_amount < 0 or total_amount < 0 then 'NEGATIVE_AMOUNT'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_PURCHASE_ORDER_STREAM
    where data_quality_flag <> 'GOOD'
       or po_status not in ('CREATED','APPROVED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED')
       or subtotal_amount < 0 or tax_amount < 0 or total_amount < 0;

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'PURCHASE_ORDER', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when po_status not in ('CREATED','APPROVED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED') then 'INVALID_PO_STATUS'
            when subtotal_amount < 0 or tax_amount < 0 or total_amount < 0 then 'NEGATIVE_AMOUNT'
            else 'UNKNOWN'
        end,
        object_construct(
            'purchase_order_id', purchase_order_id, 'po_number', po_number, 'supplier_id', supplier_id,
            'destination_store_id', destination_store_id, 'order_datetime', order_datetime,
            'expected_delivery_date', expected_delivery_date, 'po_status', po_status,
            'currency_code', currency_code, 'subtotal_amount', subtotal_amount,
            'tax_amount', tax_amount, 'total_amount', total_amount,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_PURCHASE_ORDER_STREAM
    where data_quality_flag <> 'GOOD'
       or po_status not in ('CREATED','APPROVED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED')
       or subtotal_amount < 0 or tax_amount < 0 or total_amount < 0;

    merge into RETAIL360_DEMO.CLEAN.PURCHASE_ORDER t
    using (
        select *
        from TMP_PURCHASE_ORDER_STREAM
        where data_quality_flag = 'GOOD'
          and po_status in ('CREATED','APPROVED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED')
          and subtotal_amount >= 0 and tax_amount >= 0 and total_amount >= 0
    ) s
    on t.po_number = s.po_number
    when matched then update set
        purchase_order_id = s.purchase_order_id,
        supplier_id = s.supplier_id,
        destination_store_id = s.destination_store_id,
        order_datetime = s.order_datetime,
        expected_delivery_date = s.expected_delivery_date,
        po_status = s.po_status,
        currency_code = s.currency_code,
        subtotal_amount = s.subtotal_amount,
        tax_amount = s.tax_amount,
        total_amount = s.total_amount,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        purchase_order_id, po_number, supplier_id, destination_store_id, order_datetime,
        expected_delivery_date, po_status, currency_code, subtotal_amount, tax_amount, total_amount,
        created_at, updated_at, extract_ts, batch_id, source_system, data_quality_flag,
        src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.purchase_order_id, s.po_number, s.supplier_id, s.destination_store_id, s.order_datetime,
        s.expected_delivery_date, s.po_status, s.currency_code, s.subtotal_amount, s.tax_amount, s.total_amount,
        s.created_at, s.updated_at, s.extract_ts, s.batch_id, s.source_system, s.data_quality_flag,
        s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'PURCHASE_ORDER stream processed';
end;
$$;


-- 20. PURCHASE_ORDER_LINE

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_PURCHASE_ORDER_LINE_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PURCHASE_ORDER_LINE_STREAM as
    select
        purchase_order_line_id, purchase_order_id, line_number, sku_id, ordered_quantity,
        received_quantity, unit_cost, tax_amount, line_total_amount, line_status,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_PURCHASE_ORDER_LINE_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.PURCHASE_ORDER_LINE_REJECT (
        purchase_order_line_id, purchase_order_id, line_number, sku_id, ordered_quantity,
        received_quantity, unit_cost, tax_amount, line_total_amount, line_status,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        purchase_order_line_id, purchase_order_id, line_number, sku_id, ordered_quantity,
        received_quantity, unit_cost, tax_amount, line_total_amount, line_status,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when ordered_quantity <= 0 then 'INVALID_ORDERED_QUANTITY'
            when received_quantity < 0 then 'NEGATIVE_RECEIVED_QUANTITY'
            when unit_cost < 0 or tax_amount < 0 or line_total_amount < 0 then 'NEGATIVE_AMOUNT'
            when line_status not in ('CREATED','OPEN','PARTIALLY_RECEIVED','RECEIVED','CANCELLED') then 'INVALID_LINE_STATUS'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_PURCHASE_ORDER_LINE_STREAM
    where data_quality_flag <> 'GOOD'
       or ordered_quantity <= 0
       or received_quantity < 0
       or unit_cost < 0 or tax_amount < 0 or line_total_amount < 0
       or line_status not in ('CREATED','OPEN','PARTIALLY_RECEIVED','RECEIVED','CANCELLED');

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'PURCHASE_ORDER_LINE', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when ordered_quantity <= 0 then 'INVALID_ORDERED_QUANTITY'
            when received_quantity < 0 then 'NEGATIVE_RECEIVED_QUANTITY'
            when unit_cost < 0 or tax_amount < 0 or line_total_amount < 0 then 'NEGATIVE_AMOUNT'
            when line_status not in ('CREATED','OPEN','PARTIALLY_RECEIVED','RECEIVED','CANCELLED') then 'INVALID_LINE_STATUS'
            else 'UNKNOWN'
        end,
        object_construct(
            'purchase_order_line_id', purchase_order_line_id, 'purchase_order_id', purchase_order_id,
            'line_number', line_number, 'sku_id', sku_id, 'ordered_quantity', ordered_quantity,
            'received_quantity', received_quantity, 'unit_cost', unit_cost, 'tax_amount', tax_amount,
            'line_total_amount', line_total_amount, 'line_status', line_status,
            'created_at', created_at, 'updated_at', updated_at, 'extract_ts', extract_ts,
            'batch_id', batch_id, 'source_system', source_system, 'data_quality_flag', data_quality_flag,
            'src_filename', src_filename, 'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_PURCHASE_ORDER_LINE_STREAM
    where data_quality_flag <> 'GOOD'
       or ordered_quantity <= 0
       or received_quantity < 0
       or unit_cost < 0 or tax_amount < 0 or line_total_amount < 0
       or line_status not in ('CREATED','OPEN','PARTIALLY_RECEIVED','RECEIVED','CANCELLED');

    merge into RETAIL360_DEMO.CLEAN.PURCHASE_ORDER_LINE t
    using (
        select *
        from TMP_PURCHASE_ORDER_LINE_STREAM
        where data_quality_flag = 'GOOD'
          and ordered_quantity > 0
          and received_quantity >= 0
          and unit_cost >= 0 and tax_amount >= 0 and line_total_amount >= 0
          and line_status in ('CREATED','OPEN','PARTIALLY_RECEIVED','RECEIVED','CANCELLED')
    ) s
    on t.purchase_order_line_id = s.purchase_order_line_id
    when matched then update set
        purchase_order_id = s.purchase_order_id,
        line_number = s.line_number,
        sku_id = s.sku_id,
        ordered_quantity = s.ordered_quantity,
        received_quantity = s.received_quantity,
        unit_cost = s.unit_cost,
        tax_amount = s.tax_amount,
        line_total_amount = s.line_total_amount,
        line_status = s.line_status,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        purchase_order_line_id, purchase_order_id, line_number, sku_id, ordered_quantity,
        received_quantity, unit_cost, tax_amount, line_total_amount, line_status,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.purchase_order_line_id, s.purchase_order_id, s.line_number, s.sku_id, s.ordered_quantity,
        s.received_quantity, s.unit_cost, s.tax_amount, s.line_total_amount, s.line_status,
        s.created_at, s.updated_at, s.extract_ts, s.batch_id, s.source_system,
        s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'PURCHASE_ORDER_LINE stream processed';
end;
$$;


-- 21. INVENTORY_BALANCE

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_INVENTORY_BALANCE_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_INVENTORY_BALANCE_STREAM as
    select
        inventory_balance_id, store_id, sku_id, on_hand_quantity, reserved_quantity,
        available_quantity, damaged_quantity, reorder_point_quantity, safety_stock_quantity,
        last_stock_update_at, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_INVENTORY_BALANCE_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.INVENTORY_BALANCE_REJECT (
        inventory_balance_id, store_id, sku_id, on_hand_quantity, reserved_quantity,
        available_quantity, damaged_quantity, reorder_point_quantity, safety_stock_quantity,
        last_stock_update_at, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        reject_reason, rejected_at
    )
    select
        inventory_balance_id, store_id, sku_id, on_hand_quantity, reserved_quantity,
        available_quantity, damaged_quantity, reorder_point_quantity, safety_stock_quantity,
        last_stock_update_at, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when on_hand_quantity < 0 or reserved_quantity < 0 or available_quantity < 0
              or damaged_quantity < 0 or reorder_point_quantity < 0 or safety_stock_quantity < 0
              then 'NEGATIVE_QUANTITY'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_INVENTORY_BALANCE_STREAM
    where data_quality_flag <> 'GOOD'
       or on_hand_quantity < 0 or reserved_quantity < 0 or available_quantity < 0
       or damaged_quantity < 0 or reorder_point_quantity < 0 or safety_stock_quantity < 0;

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'INVENTORY_BALANCE', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when on_hand_quantity < 0 or reserved_quantity < 0 or available_quantity < 0
              or damaged_quantity < 0 or reorder_point_quantity < 0 or safety_stock_quantity < 0
              then 'NEGATIVE_QUANTITY'
            else 'UNKNOWN'
        end,
        object_construct(
            'inventory_balance_id', inventory_balance_id, 'store_id', store_id, 'sku_id', sku_id,
            'on_hand_quantity', on_hand_quantity, 'reserved_quantity', reserved_quantity,
            'available_quantity', available_quantity, 'damaged_quantity', damaged_quantity,
            'reorder_point_quantity', reorder_point_quantity, 'safety_stock_quantity', safety_stock_quantity,
            'last_stock_update_at', last_stock_update_at, 'created_at', created_at, 'updated_at', updated_at,
            'extract_ts', extract_ts, 'batch_id', batch_id, 'source_system', source_system,
            'data_quality_flag', data_quality_flag, 'src_filename', src_filename,
            'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_INVENTORY_BALANCE_STREAM
    where data_quality_flag <> 'GOOD'
       or on_hand_quantity < 0 or reserved_quantity < 0 or available_quantity < 0
       or damaged_quantity < 0 or reorder_point_quantity < 0 or safety_stock_quantity < 0;

    merge into RETAIL360_DEMO.CLEAN.INVENTORY_BALANCE t
    using (
        select *
        from TMP_INVENTORY_BALANCE_STREAM
        where data_quality_flag = 'GOOD'
          and on_hand_quantity >= 0 and reserved_quantity >= 0 and available_quantity >= 0
          and damaged_quantity >= 0 and reorder_point_quantity >= 0 and safety_stock_quantity >= 0
    ) s
    on t.inventory_balance_id = s.inventory_balance_id
    when matched then update set
        store_id = s.store_id,
        sku_id = s.sku_id,
        on_hand_quantity = s.on_hand_quantity,
        reserved_quantity = s.reserved_quantity,
        available_quantity = s.available_quantity,
        damaged_quantity = s.damaged_quantity,
        reorder_point_quantity = s.reorder_point_quantity,
        safety_stock_quantity = s.safety_stock_quantity,
        last_stock_update_at = s.last_stock_update_at,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        inventory_balance_id, store_id, sku_id, on_hand_quantity, reserved_quantity,
        available_quantity, damaged_quantity, reorder_point_quantity, safety_stock_quantity,
        last_stock_update_at, created_at, updated_at, extract_ts, batch_id,
        source_system, data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.inventory_balance_id, s.store_id, s.sku_id, s.on_hand_quantity, s.reserved_quantity,
        s.available_quantity, s.damaged_quantity, s.reorder_point_quantity, s.safety_stock_quantity,
        s.last_stock_update_at, s.created_at, s.updated_at, s.extract_ts, s.batch_id,
        s.source_system, s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'INVENTORY_BALANCE stream processed';
end;
$$;


-- 22. INVENTORY_TRANSACTION

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_INVENTORY_TRANSACTION_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_INVENTORY_TRANSACTION_STREAM as
    select
        inventory_transaction_id, transaction_datetime, transaction_type, store_id, sku_id,
        quantity_change, reference_type, reference_id, unit_cost, remarks,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts
    from RETAIL360_DEMO.RAW.STRM_INVENTORY_TRANSACTION_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.INVENTORY_TRANSACTION_REJECT (
        inventory_transaction_id, transaction_datetime, transaction_type, store_id, sku_id,
        quantity_change, reference_type, reference_id, unit_cost, remarks,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, reject_reason, rejected_at
    )
    select
        inventory_transaction_id, transaction_datetime, transaction_type, store_id, sku_id,
        quantity_change, reference_type, reference_id, unit_cost, remarks,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when transaction_type not in (
                'PURCHASE_RECEIPT','SALE','SALE_CANCEL','CUSTOMER_RETURN','SUPPLIER_RETURN',
                'TRANSFER_IN','TRANSFER_OUT','ADJUSTMENT_POSITIVE','ADJUSTMENT_NEGATIVE',
                'DAMAGE','RESERVATION','RESERVATION_RELEASE'
            ) then 'INVALID_TRANSACTION_TYPE'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_INVENTORY_TRANSACTION_STREAM
    where data_quality_flag <> 'GOOD'
       or transaction_type not in (
            'PURCHASE_RECEIPT','SALE','SALE_CANCEL','CUSTOMER_RETURN','SUPPLIER_RETURN',
            'TRANSFER_IN','TRANSFER_OUT','ADJUSTMENT_POSITIVE','ADJUSTMENT_NEGATIVE',
            'DAMAGE','RESERVATION','RESERVATION_RELEASE'
       );

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'INVENTORY_TRANSACTION', src_filename, src_row_number,
        case
            when data_quality_flag <> 'GOOD' then 'DATA_QUALITY_FLAG_BAD'
            when transaction_type not in (
                'PURCHASE_RECEIPT','SALE','SALE_CANCEL','CUSTOMER_RETURN','SUPPLIER_RETURN',
                'TRANSFER_IN','TRANSFER_OUT','ADJUSTMENT_POSITIVE','ADJUSTMENT_NEGATIVE',
                'DAMAGE','RESERVATION','RESERVATION_RELEASE'
            ) then 'INVALID_TRANSACTION_TYPE'
            else 'UNKNOWN'
        end,
        object_construct(
            'inventory_transaction_id', inventory_transaction_id, 'transaction_datetime', transaction_datetime,
            'transaction_type', transaction_type, 'store_id', store_id, 'sku_id', sku_id,
            'quantity_change', quantity_change, 'reference_type', reference_type, 'reference_id', reference_id,
            'unit_cost', unit_cost, 'remarks', remarks, 'created_at', created_at, 'updated_at', updated_at,
            'extract_ts', extract_ts, 'batch_id', batch_id, 'source_system', source_system,
            'data_quality_flag', data_quality_flag, 'src_filename', src_filename,
            'src_row_number', src_row_number, 'load_ts', load_ts
        )
    from TMP_INVENTORY_TRANSACTION_STREAM
    where data_quality_flag <> 'GOOD'
       or transaction_type not in (
            'PURCHASE_RECEIPT','SALE','SALE_CANCEL','CUSTOMER_RETURN','SUPPLIER_RETURN',
            'TRANSFER_IN','TRANSFER_OUT','ADJUSTMENT_POSITIVE','ADJUSTMENT_NEGATIVE',
            'DAMAGE','RESERVATION','RESERVATION_RELEASE'
       );

    merge into RETAIL360_DEMO.CLEAN.INVENTORY_TRANSACTION t
    using (
        select *
        from TMP_INVENTORY_TRANSACTION_STREAM
        where data_quality_flag = 'GOOD'
          and transaction_type in (
            'PURCHASE_RECEIPT','SALE','SALE_CANCEL','CUSTOMER_RETURN','SUPPLIER_RETURN',
            'TRANSFER_IN','TRANSFER_OUT','ADJUSTMENT_POSITIVE','ADJUSTMENT_NEGATIVE',
            'DAMAGE','RESERVATION','RESERVATION_RELEASE'
          )
    ) s
    on t.inventory_transaction_id = s.inventory_transaction_id
    when matched then update set
        transaction_datetime = s.transaction_datetime,
        transaction_type = s.transaction_type,
        store_id = s.store_id,
        sku_id = s.sku_id,
        quantity_change = s.quantity_change,
        reference_type = s.reference_type,
        reference_id = s.reference_id,
        unit_cost = s.unit_cost,
        remarks = s.remarks,
        created_at = s.created_at,
        updated_at = s.updated_at,
        extract_ts = s.extract_ts,
        batch_id = s.batch_id,
        source_system = s.source_system,
        data_quality_flag = s.data_quality_flag,
        src_filename = s.src_filename,
        src_row_number = s.src_row_number,
        load_ts = s.load_ts,
        cleaned_at = current_timestamp()
    when not matched then insert (
        inventory_transaction_id, transaction_datetime, transaction_type, store_id, sku_id,
        quantity_change, reference_type, reference_id, unit_cost, remarks,
        created_at, updated_at, extract_ts, batch_id, source_system,
        data_quality_flag, src_filename, src_row_number, load_ts, cleaned_at
    )
    values (
        s.inventory_transaction_id, s.transaction_datetime, s.transaction_type, s.store_id, s.sku_id,
        s.quantity_change, s.reference_type, s.reference_id, s.unit_cost, s.remarks,
        s.created_at, s.updated_at, s.extract_ts, s.batch_id, s.source_system,
        s.data_quality_flag, s.src_filename, s.src_row_number, s.load_ts, current_timestamp()
    );

    return 'INVENTORY_TRANSACTION stream processed';
end;
$$;


-- 23. CDC EVENTS

create or replace procedure RETAIL360_DEMO.CLEAN.SP_PROCESS_CDC_EVENTS_STREAM()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_CDC_EVENTS_STREAM as
    select
        event_id, source_table, op, change_ts, source_pk, before_payload, after_payload,
        batch_id, extract_ts, source_system, src_filename, load_ts
    from RETAIL360_DEMO.RAW.STRM_CDC_EVENTS_SRC
    where metadata$action = 'INSERT';

    insert into RETAIL360_DEMO.CLEAN.CDC_EVENTS_REJECT (
        event_id, source_table, op, change_ts, source_pk, before_payload, after_payload,
        batch_id, extract_ts, source_system, src_filename, load_ts, reject_reason, rejected_at
    )
    select
        event_id, source_table, op, change_ts, source_pk, before_payload, after_payload,
        batch_id, extract_ts, source_system, src_filename, load_ts,
        case
            when op not in ('I','U','D') then 'INVALID_CDC_OP'
            else 'UNKNOWN'
        end,
        current_timestamp()
    from TMP_CDC_EVENTS_STREAM
    where op not in ('I','U','D');

    insert into RETAIL360_DEMO.RAW.RAW_REJECT_LOG (
        batch_id, table_name, src_filename, src_row_number, reject_reason, raw_payload
    )
    select
        batch_id, 'CDC_EVENTS', src_filename, null,
        case
            when op not in ('I','U','D') then 'INVALID_CDC_OP'
            else 'UNKNOWN'
        end,
        object_construct(
            'event_id', event_id, 'source_table', source_table, 'op', op,
            'change_ts', change_ts, 'source_pk', source_pk,
            'before_payload', before_payload, 'after_payload', after_payload,
            'batch_id', batch_id, 'extract_ts', extract_ts,
            'source_system', source_system, 'src_filename', src_filename, 'load_ts', load_ts
        )
    from TMP_CDC_EVENTS_STREAM
    where op not in ('I','U','D');

    merge into RETAIL360_DEMO.CLEAN.CDC_EVENTS t
    using (
        select *
        from TMP_CDC_EVENTS_STREAM
        where op in ('I','U','D')
    ) s
    on t.event_id = s.event_id
    when not matched then insert (
        event_id, source_table, op, change_ts, source_pk, before_payload, after_payload,
        batch_id, extract_ts, source_system, src_filename, load_ts, cleaned_at
    )
    values (
        s.event_id, s.source_table, s.op, s.change_ts, s.source_pk, s.before_payload, s.after_payload,
        s.batch_id, s.extract_ts, s.source_system, s.src_filename, s.load_ts, current_timestamp()
    );

    return 'CDC_EVENTS stream processed';
end;
$$;

