create or replace procedure SP_LOAD_DIM_CUSTOMER_SCD2()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_CUSTOMER_SRC as
    select
        customer_id,
        customer_code,
        loyalty_id,
        first_name,
        last_name,
        email,
        phone,
        preferred_channel,
        marketing_opt_in,
        status,
        batch_id,
        extract_ts
    from (
        select
            customer_id,
            customer_code,
            loyalty_id,
            first_name,
            last_name,
            email,
            phone,
            preferred_channel,
            marketing_opt_in,
            status,
            batch_id,
            extract_ts,
            row_number() over (
                partition by customer_id
                order by extract_ts desc nulls last, batch_id desc nulls last
            ) as rn
        from RETAIL360_DEMO.CLEAN.CUSTOMER
    )
    where rn = 1;

    create or replace temporary table TMP_CUSTOMER_CURRENT as
    select *
    from (
        select
            t.*,
            row_number() over (
                partition by customer_id
                order by
                    case when is_current then 1 else 0 end desc,
                    effective_from_ts desc,
                    inserted_at desc,
                    dim_customer_sk desc
            ) as rn
        from RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 t
        where is_current = true
    )
    where rn = 1;

    create or replace temporary table TMP_CUSTOMER_NEW as
    select s.*
    from TMP_CUSTOMER_SRC s
    left join TMP_CUSTOMER_CURRENT t
      on s.customer_id = t.customer_id
    where t.customer_id is null;

    create or replace temporary table TMP_CUSTOMER_CHANGES as
    select *
    from (
        select
            s.*,
            row_number() over (
                partition by s.customer_id
                order by s.extract_ts desc nulls last, s.batch_id desc nulls last
            ) as rn
        from TMP_CUSTOMER_SRC s
        join TMP_CUSTOMER_CURRENT t
          on s.customer_id = t.customer_id
        where
            nvl(s.customer_code,'~')         <> nvl(t.customer_code,'~')
            or nvl(s.loyalty_id,'~')         <> nvl(t.loyalty_id,'~')
            or nvl(s.first_name,'~')         <> nvl(t.first_name,'~')
            or nvl(s.last_name,'~')          <> nvl(t.last_name,'~')
            or nvl(s.email,'~')              <> nvl(t.email,'~')
            or nvl(s.phone,'~')              <> nvl(t.phone,'~')
            or nvl(s.preferred_channel,'~')  <> nvl(t.preferred_channel,'~')
            or nvl(s.marketing_opt_in,false) <> nvl(t.marketing_opt_in,false)
            or nvl(s.status,'~')             <> nvl(t.status,'~')
    )
    where rn = 1;

    update RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 t
    set
        effective_to_ts = coalesce(c.extract_ts, current_timestamp()),
        is_current = false
    from TMP_CUSTOMER_CHANGES c
    where t.customer_id = c.customer_id
      and t.is_current = true;

    insert into RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 (
        customer_id,
        customer_code,
        loyalty_id,
        first_name,
        last_name,
        email,
        phone,
        preferred_channel,
        marketing_opt_in,
        status,
        effective_from_ts,
        effective_to_ts,
        is_current,
        source_batch_id,
        source_extract_ts
    )
    select
        n.customer_id,
        n.customer_code,
        n.loyalty_id,
        n.first_name,
        n.last_name,
        n.email,
        n.phone,
        n.preferred_channel,
        n.marketing_opt_in,
        n.status,
        to_timestamp_ntz('1900-01-01 00:00:00'),
        to_timestamp_ntz('9999-12-31 23:59:59'),
        true,
        n.batch_id,
        n.extract_ts
    from TMP_CUSTOMER_NEW n
    where not exists (
        select 1
        from RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 t
        where t.customer_id = n.customer_id
          and t.is_current = true
    );

    insert into RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 (
        customer_id,
        customer_code,
        loyalty_id,
        first_name,
        last_name,
        email,
        phone,
        preferred_channel,
        marketing_opt_in,
        status,
        effective_from_ts,
        effective_to_ts,
        is_current,
        source_batch_id,
        source_extract_ts
    )
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
        c.status,
        coalesce(c.extract_ts, current_timestamp()),
        to_timestamp_ntz('9999-12-31 23:59:59'),
        true,
        c.batch_id,
        c.extract_ts
    from TMP_CUSTOMER_CHANGES c
    where not exists (
        select 1
        from RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 t
        where t.customer_id = c.customer_id
          and t.is_current = true
          and nvl(t.customer_code,'~')         = nvl(c.customer_code,'~')
          and nvl(t.loyalty_id,'~')            = nvl(c.loyalty_id,'~')
          and nvl(t.first_name,'~')            = nvl(c.first_name,'~')
          and nvl(t.last_name,'~')             = nvl(c.last_name,'~')
          and nvl(t.email,'~')                 = nvl(c.email,'~')
          and nvl(t.phone,'~')                 = nvl(c.phone,'~')
          and nvl(t.preferred_channel,'~')     = nvl(c.preferred_channel,'~')
          and nvl(t.marketing_opt_in,false)    = nvl(c.marketing_opt_in,false)
          and nvl(t.status,'~')                = nvl(c.status,'~')
    );

    create or replace temporary table TMP_CUSTOMER_CURRENT_FIX as
    select
        dim_customer_sk,
        row_number() over (
            partition by customer_id
            order by effective_from_ts desc, inserted_at desc, dim_customer_sk desc
        ) as rn
    from RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2
    where is_current = true;

    update RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2 t
    set
        is_current = false,
        effective_to_ts = current_timestamp()
    from TMP_CUSTOMER_CURRENT_FIX f
    where t.dim_customer_sk = f.dim_customer_sk
      and f.rn > 1;

    return 'DIM_CUSTOMER_SCD2 loaded';
end;
$$;


create or replace procedure SP_LOAD_DIM_STORE_SCD2()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_STORE_SRC as
    select
        store_id,
        store_code,
        store_name,
        store_type,
        channel_type,
        city,
        state,
        postal_code,
        country_code,
        status,
        batch_id,
        extract_ts
    from (
        select
            store_id,
            store_code,
            store_name,
            store_type,
            channel_type,
            city,
            state,
            postal_code,
            country_code,
            status,
            batch_id,
            extract_ts,
            row_number() over (
                partition by store_id
                order by extract_ts desc nulls last, batch_id desc nulls last
            ) as rn
        from RETAIL360_DEMO.CLEAN.STORE
    )
    where rn = 1;

    create or replace temporary table TMP_STORE_CURRENT as
    select *
    from (
        select
            t.*,
            row_number() over (
                partition by store_id
                order by
                    case when is_current then 1 else 0 end desc,
                    effective_from_ts desc,
                    inserted_at desc,
                    dim_store_sk desc
            ) as rn
        from RETAIL360_DEMO.CORE.DIM_STORE_SCD2 t
        where is_current = true
    )
    where rn = 1;

    create or replace temporary table TMP_STORE_NEW as
    select s.*
    from TMP_STORE_SRC s
    left join TMP_STORE_CURRENT t
      on s.store_id = t.store_id
    where t.store_id is null;

    create or replace temporary table TMP_STORE_CHANGES as
    select *
    from (
        select
            s.*,
            row_number() over (
                partition by s.store_id
                order by s.extract_ts desc nulls last, s.batch_id desc nulls last
            ) as rn
        from TMP_STORE_SRC s
        join TMP_STORE_CURRENT t
          on s.store_id = t.store_id
        where
            nvl(s.store_code,'~')      <> nvl(t.store_code,'~')
            or nvl(s.store_name,'~')   <> nvl(t.store_name,'~')
            or nvl(s.store_type,'~')   <> nvl(t.store_type,'~')
            or nvl(s.channel_type,'~') <> nvl(t.channel_type,'~')
            or nvl(s.city,'~')         <> nvl(t.city,'~')
            or nvl(s.state,'~')        <> nvl(t.state,'~')
            or nvl(s.postal_code,'~')  <> nvl(t.postal_code,'~')
            or nvl(s.country_code,'~') <> nvl(t.country_code,'~')
            or nvl(s.status,'~')       <> nvl(t.status,'~')
    )
    where rn = 1;

    update RETAIL360_DEMO.CORE.DIM_STORE_SCD2 t
    set
        effective_to_ts = coalesce(c.extract_ts, current_timestamp()),
        is_current = false
    from TMP_STORE_CHANGES c
    where t.store_id = c.store_id
      and t.is_current = true;

    insert into RETAIL360_DEMO.CORE.DIM_STORE_SCD2 (
        store_id, store_code, store_name, store_type, channel_type,
        city, state, postal_code, country_code, status,
        effective_from_ts, effective_to_ts, is_current,
        source_batch_id, source_extract_ts
    )
    select
        n.store_id, n.store_code, n.store_name, n.store_type, n.channel_type,
        n.city, n.state, n.postal_code, n.country_code, n.status,
        to_timestamp_ntz('1900-01-01 00:00:00'),
        to_timestamp_ntz('9999-12-31 23:59:59'),
        true,
        n.batch_id,
        n.extract_ts
    from TMP_STORE_NEW n
    where not exists (
        select 1
        from RETAIL360_DEMO.CORE.DIM_STORE_SCD2 t
        where t.store_id = n.store_id
          and t.is_current = true
    );

    insert into RETAIL360_DEMO.CORE.DIM_STORE_SCD2 (
        store_id, store_code, store_name, store_type, channel_type,
        city, state, postal_code, country_code, status,
        effective_from_ts, effective_to_ts, is_current,
        source_batch_id, source_extract_ts
    )
    select
        c.store_id, c.store_code, c.store_name, c.store_type, c.channel_type,
        c.city, c.state, c.postal_code, c.country_code, c.status,
        coalesce(c.extract_ts, current_timestamp()),
        to_timestamp_ntz('9999-12-31 23:59:59'),
        true,
        c.batch_id,
        c.extract_ts
    from TMP_STORE_CHANGES c
    where not exists (
        select 1
        from RETAIL360_DEMO.CORE.DIM_STORE_SCD2 t
        where t.store_id = c.store_id
          and t.is_current = true
          and nvl(t.store_code,'~')      = nvl(c.store_code,'~')
          and nvl(t.store_name,'~')      = nvl(c.store_name,'~')
          and nvl(t.store_type,'~')      = nvl(c.store_type,'~')
          and nvl(t.channel_type,'~')    = nvl(c.channel_type,'~')
          and nvl(t.city,'~')            = nvl(c.city,'~')
          and nvl(t.state,'~')           = nvl(c.state,'~')
          and nvl(t.postal_code,'~')     = nvl(c.postal_code,'~')
          and nvl(t.country_code,'~')    = nvl(c.country_code,'~')
          and nvl(t.status,'~')          = nvl(c.status,'~')
    );

    create or replace temporary table TMP_STORE_CURRENT_FIX as
    select
        dim_store_sk,
        row_number() over (
            partition by store_id
            order by effective_from_ts desc, inserted_at desc, dim_store_sk desc
        ) as rn
    from RETAIL360_DEMO.CORE.DIM_STORE_SCD2
    where is_current = true;

    update RETAIL360_DEMO.CORE.DIM_STORE_SCD2 t
    set
        is_current = false,
        effective_to_ts = current_timestamp()
    from TMP_STORE_CURRENT_FIX f
    where t.dim_store_sk = f.dim_store_sk
      and f.rn > 1;

    return 'DIM_STORE_SCD2 loaded';
end;
$$;

create or replace procedure SP_LOAD_DIM_PRODUCT_SKU_SCD2()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PRODUCT_SKU_SRC as
    select
        sku_id,
        product_id,
        sku_code,
        barcode,
        color,
        size,
        style,
        pack_size,
        standard_cost,
        list_price,
        status,
        batch_id,
        extract_ts
    from (
        select
            sku_id,
            product_id,
            sku_code,
            barcode,
            color,
            size,
            style,
            pack_size,
            standard_cost,
            list_price,
            status,
            batch_id,
            extract_ts,
            row_number() over (
                partition by sku_id
                order by extract_ts desc nulls last, batch_id desc nulls last
            ) as rn
        from RETAIL360_DEMO.CLEAN.PRODUCT_SKU
    )
    where rn = 1;

    create or replace temporary table TMP_PRODUCT_SKU_CURRENT as
    select *
    from (
        select
            t.*,
            row_number() over (
                partition by sku_id
                order by
                    case when is_current then 1 else 0 end desc,
                    effective_from_ts desc,
                    inserted_at desc,
                    dim_product_sku_sk desc
            ) as rn
        from RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 t
        where is_current = true
    )
    where rn = 1;

    create or replace temporary table TMP_PRODUCT_SKU_NEW as
    select s.*
    from TMP_PRODUCT_SKU_SRC s
    left join TMP_PRODUCT_SKU_CURRENT t
      on s.sku_id = t.sku_id
    where t.sku_id is null;

    create or replace temporary table TMP_PRODUCT_SKU_CHANGES as
    select *
    from (
        select
            s.*,
            row_number() over (
                partition by s.sku_id
                order by s.extract_ts desc nulls last, s.batch_id desc nulls last
            ) as rn
        from TMP_PRODUCT_SKU_SRC s
        join TMP_PRODUCT_SKU_CURRENT t
          on s.sku_id = t.sku_id
        where
            nvl(s.product_id,-1)       <> nvl(t.product_id,-1)
            or nvl(s.sku_code,'~')     <> nvl(t.sku_code,'~')
            or nvl(s.barcode,'~')      <> nvl(t.barcode,'~')
            or nvl(s.color,'~')        <> nvl(t.color,'~')
            or nvl(s.size,'~')         <> nvl(t.size,'~')
            or nvl(s.style,'~')        <> nvl(t.style,'~')
            or nvl(s.pack_size,'~')    <> nvl(t.pack_size,'~')
            or nvl(s.standard_cost,-1) <> nvl(t.standard_cost,-1)
            or nvl(s.list_price,-1)    <> nvl(t.list_price,-1)
            or nvl(s.status,'~')       <> nvl(t.status,'~')
    )
    where rn = 1;

    update RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 t
    set
        effective_to_ts = coalesce(c.extract_ts, current_timestamp()),
        is_current = false
    from TMP_PRODUCT_SKU_CHANGES c
    where t.sku_id = c.sku_id
      and t.is_current = true;

    insert into RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 (
        sku_id, product_id, sku_code, barcode, color, size, style, pack_size,
        standard_cost, list_price, status,
        effective_from_ts, effective_to_ts, is_current,
        source_batch_id, source_extract_ts
    )
    select
        n.sku_id, n.product_id, n.sku_code, n.barcode, n.color, n.size, n.style, n.pack_size,
        n.standard_cost, n.list_price, n.status,
        to_timestamp_ntz('1900-01-01 00:00:00'),
        to_timestamp_ntz('9999-12-31 23:59:59'),
        true,
        n.batch_id,
        n.extract_ts
    from TMP_PRODUCT_SKU_NEW n
    where not exists (
        select 1
        from RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 t
        where t.sku_id = n.sku_id
          and t.is_current = true
    );

    insert into RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 (
        sku_id, product_id, sku_code, barcode, color, size, style, pack_size,
        standard_cost, list_price, status,
        effective_from_ts, effective_to_ts, is_current,
        source_batch_id, source_extract_ts
    )
    select
        c.sku_id, c.product_id, c.sku_code, c.barcode, c.color, c.size, c.style, c.pack_size,
        c.standard_cost, c.list_price, c.status,
        coalesce(c.extract_ts, current_timestamp()),
        to_timestamp_ntz('9999-12-31 23:59:59'),
        true,
        c.batch_id,
        c.extract_ts
    from TMP_PRODUCT_SKU_CHANGES c
    where not exists (
        select 1
        from RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 t
        where t.sku_id = c.sku_id
          and t.is_current = true
          and nvl(t.product_id,-1)       = nvl(c.product_id,-1)
          and nvl(t.sku_code,'~')        = nvl(c.sku_code,'~')
          and nvl(t.barcode,'~')         = nvl(c.barcode,'~')
          and nvl(t.color,'~')           = nvl(c.color,'~')
          and nvl(t.size,'~')            = nvl(c.size,'~')
          and nvl(t.style,'~')           = nvl(c.style,'~')
          and nvl(t.pack_size,'~')       = nvl(c.pack_size,'~')
          and nvl(t.standard_cost,-1)    = nvl(c.standard_cost,-1)
          and nvl(t.list_price,-1)       = nvl(c.list_price,-1)
          and nvl(t.status,'~')          = nvl(c.status,'~')
    );

    create or replace temporary table TMP_PRODUCT_SKU_CURRENT_FIX as
    select
        dim_product_sku_sk,
        row_number() over (
            partition by sku_id
            order by effective_from_ts desc, inserted_at desc, dim_product_sku_sk desc
        ) as rn
    from RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2
    where is_current = true;

    update RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2 t
    set
        is_current = false,
        effective_to_ts = current_timestamp()
    from TMP_PRODUCT_SKU_CURRENT_FIX f
    where t.dim_product_sku_sk = f.dim_product_sku_sk
      and f.rn > 1;

    return 'DIM_PRODUCT_SKU_SCD2 loaded';
end;
$$;

create or replace procedure SP_LOAD_FACT_SALES_ORDER()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_SALES_ORDER_SRC as
    select
        sales_order_id,
        order_number,
        customer_id,
        store_id,
        sales_channel,
        order_datetime,
        order_status,
        currency_code,
        subtotal_amount,
        discount_amount,
        tax_amount,
        shipping_amount,
        total_amount,
        batch_id,
        extract_ts
    from (
        select
            sales_order_id,
            order_number,
            customer_id,
            store_id,
            sales_channel,
            order_datetime,
            order_status,
            currency_code,
            subtotal_amount,
            discount_amount,
            tax_amount,
            shipping_amount,
            total_amount,
            batch_id,
            extract_ts,
            row_number() over (
                partition by sales_order_id
                order by extract_ts desc nulls last, batch_id desc nulls last
            ) as rn
        from RETAIL360_DEMO.CLEAN.SALES_ORDER
    )
    where rn = 1;

    merge into RETAIL360_DEMO.CORE.FACT_SALES_ORDER t
    using TMP_SALES_ORDER_SRC s
    on t.sales_order_id = s.sales_order_id
    when matched then update set
        order_number = s.order_number,
        customer_id = s.customer_id,
        store_id = s.store_id,
        sales_channel = s.sales_channel,
        order_datetime = s.order_datetime,
        order_status = s.order_status,
        currency_code = s.currency_code,
        subtotal_amount = s.subtotal_amount,
        discount_amount = s.discount_amount,
        tax_amount = s.tax_amount,
        shipping_amount = s.shipping_amount,
        total_amount = s.total_amount,
        batch_id = s.batch_id,
        extract_ts = s.extract_ts
    when not matched then insert (
        sales_order_id,
        order_number,
        customer_id,
        store_id,
        sales_channel,
        order_datetime,
        order_status,
        currency_code,
        subtotal_amount,
        discount_amount,
        tax_amount,
        shipping_amount,
        total_amount,
        batch_id,
        extract_ts
    )
    values (
        s.sales_order_id,
        s.order_number,
        s.customer_id,
        s.store_id,
        s.sales_channel,
        s.order_datetime,
        s.order_status,
        s.currency_code,
        s.subtotal_amount,
        s.discount_amount,
        s.tax_amount,
        s.shipping_amount,
        s.total_amount,
        s.batch_id,
        s.extract_ts
    );

    return 'FACT_SALES_ORDER loaded';
end;
$$;


create or replace procedure SP_LOAD_FACT_SALES_ORDER_LINE()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_SALES_ORDER_LINE_SRC as
    select
        sales_order_line_id,
        sales_order_id,
        line_number,
        sku_id,
        promotion_id,
        ordered_quantity,
        unit_list_price,
        unit_selling_price,
        line_discount_amount,
        tax_amount,
        line_total_amount,
        fulfillment_store_id,
        line_status,
        batch_id,
        extract_ts
    from (
        select
            sales_order_line_id,
            sales_order_id,
            line_number,
            sku_id,
            promotion_id,
            ordered_quantity,
            unit_list_price,
            unit_selling_price,
            line_discount_amount,
            tax_amount,
            line_total_amount,
            fulfillment_store_id,
            line_status,
            batch_id,
            extract_ts,
            row_number() over (
                partition by sales_order_line_id
                order by extract_ts desc nulls last, batch_id desc nulls last
            ) as rn
        from RETAIL360_DEMO.CLEAN.SALES_ORDER_LINE
    )
    where rn = 1;

    merge into RETAIL360_DEMO.CORE.FACT_SALES_ORDER_LINE t
    using TMP_SALES_ORDER_LINE_SRC s
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
        batch_id = s.batch_id,
        extract_ts = s.extract_ts
    when not matched then insert (
        sales_order_line_id,
        sales_order_id,
        line_number,
        sku_id,
        promotion_id,
        ordered_quantity,
        unit_list_price,
        unit_selling_price,
        line_discount_amount,
        tax_amount,
        line_total_amount,
        fulfillment_store_id,
        line_status,
        batch_id,
        extract_ts
    )
    values (
        s.sales_order_line_id,
        s.sales_order_id,
        s.line_number,
        s.sku_id,
        s.promotion_id,
        s.ordered_quantity,
        s.unit_list_price,
        s.unit_selling_price,
        s.line_discount_amount,
        s.tax_amount,
        s.line_total_amount,
        s.fulfillment_store_id,
        s.line_status,
        s.batch_id,
        s.extract_ts
    );

    return 'FACT_SALES_ORDER_LINE loaded';
end;
$$;


create or replace procedure SP_LOAD_FACT_PAYMENT()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_PAYMENT_SRC as
    select
        payment_id,
        sales_order_id,
        payment_reference,
        payment_method,
        payment_status,
        amount,
        payment_datetime,
        currency_code,
        batch_id,
        extract_ts
    from (
        select
            payment_id,
            sales_order_id,
            payment_reference,
            payment_method,
            payment_status,
            amount,
            payment_datetime,
            currency_code,
            batch_id,
            extract_ts,
            row_number() over (
                partition by payment_id
                order by extract_ts desc nulls last, batch_id desc nulls last
            ) as rn
        from RETAIL360_DEMO.CLEAN.PAYMENT
    )
    where rn = 1;

    merge into RETAIL360_DEMO.CORE.FACT_PAYMENT t
    using TMP_PAYMENT_SRC s
    on t.payment_id = s.payment_id
    when matched then update set
        sales_order_id = s.sales_order_id,
        payment_reference = s.payment_reference,
        payment_method = s.payment_method,
        payment_status = s.payment_status,
        amount = s.amount,
        payment_datetime = s.payment_datetime,
        currency_code = s.currency_code,
        batch_id = s.batch_id,
        extract_ts = s.extract_ts
    when not matched then insert (
        payment_id,
        sales_order_id,
        payment_reference,
        payment_method,
        payment_status,
        amount,
        payment_datetime,
        currency_code,
        batch_id,
        extract_ts
    )
    values (
        s.payment_id,
        s.sales_order_id,
        s.payment_reference,
        s.payment_method,
        s.payment_status,
        s.amount,
        s.payment_datetime,
        s.currency_code,
        s.batch_id,
        s.extract_ts
    );

    return 'FACT_PAYMENT loaded';
end;
$$;


create or replace procedure SP_LOAD_FACT_INVENTORY_TRANSACTION()
returns string
language sql
as
$$
begin
    create or replace temporary table TMP_INVENTORY_TRANSACTION_SRC as
    select
        inventory_transaction_id,
        transaction_datetime,
        transaction_type,
        store_id,
        sku_id,
        quantity_change,
        reference_type,
        reference_id,
        unit_cost,
        remarks,
        batch_id,
        extract_ts
    from (
        select
            inventory_transaction_id,
            transaction_datetime,
            transaction_type,
            store_id,
            sku_id,
            quantity_change,
            reference_type,
            reference_id,
            unit_cost,
            remarks,
            batch_id,
            extract_ts,
            row_number() over (
                partition by inventory_transaction_id
                order by extract_ts desc nulls last, batch_id desc nulls last
            ) as rn
        from RETAIL360_DEMO.CLEAN.INVENTORY_TRANSACTION
    )
    where rn = 1;

    merge into RETAIL360_DEMO.CORE.FACT_INVENTORY_TRANSACTION t
    using TMP_INVENTORY_TRANSACTION_SRC s
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
        batch_id = s.batch_id,
        extract_ts = s.extract_ts
    when not matched then insert (
        inventory_transaction_id,
        transaction_datetime,
        transaction_type,
        store_id,
        sku_id,
        quantity_change,
        reference_type,
        reference_id,
        unit_cost,
        remarks,
        batch_id,
        extract_ts
    )
    values (
        s.inventory_transaction_id,
        s.transaction_datetime,
        s.transaction_type,
        s.store_id,
        s.sku_id,
        s.quantity_change,
        s.reference_type,
        s.reference_id,
        s.unit_cost,
        s.remarks,
        s.batch_id,
        s.extract_ts
    );

    return 'FACT_INVENTORY_TRANSACTION loaded';
end;
$$;

create or replace procedure SP_LOAD_CORE_ALL()
returns string
language sql
as
$$
begin
    call RETAIL360_DEMO.CORE.SP_LOAD_DIM_CUSTOMER_SCD2();
    call RETAIL360_DEMO.CORE.SP_LOAD_DIM_STORE_SCD2();
    call RETAIL360_DEMO.CORE.SP_LOAD_DIM_PRODUCT_SKU_SCD2();

    call RETAIL360_DEMO.CORE.SP_LOAD_FACT_SALES_ORDER();
    call RETAIL360_DEMO.CORE.SP_LOAD_FACT_SALES_ORDER_LINE();
    call RETAIL360_DEMO.CORE.SP_LOAD_FACT_PAYMENT();
    call RETAIL360_DEMO.CORE.SP_LOAD_FACT_INVENTORY_TRANSACTION();

    return 'CORE load completed';
end;
$$;




create or replace procedure SP_REBUILD_CORE_ALL()
returns string
language sql
as
$$
begin
    truncate table RETAIL360_DEMO.CORE.DIM_CUSTOMER_SCD2;
    truncate table RETAIL360_DEMO.CORE.DIM_STORE_SCD2;
    truncate table RETAIL360_DEMO.CORE.DIM_PRODUCT_SKU_SCD2;

    truncate table RETAIL360_DEMO.CORE.FACT_SALES_ORDER;
    truncate table RETAIL360_DEMO.CORE.FACT_SALES_ORDER_LINE;
    truncate table RETAIL360_DEMO.CORE.FACT_PAYMENT;
    truncate table RETAIL360_DEMO.CORE.FACT_INVENTORY_TRANSACTION;

    call RETAIL360_DEMO.CORE.SP_LOAD_CORE_ALL();

    return 'CORE rebuild completed';
end;
$$;


-- call RETAIL360_DEMO.CORE.SP_REBUILD_CORE_ALL();





























