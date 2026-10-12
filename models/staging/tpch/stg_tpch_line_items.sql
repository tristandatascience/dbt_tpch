with source as (

    select * from {{ source('tpch', 'lineitem') }}

),

renamed as (

    select
        -- surrogate primary key
        md5(cast(l_orderkey as varchar) || '-' || cast(l_linenumber as varchar)) as order_item_key,

        -- foreign keys
        l_orderkey as order_key,
        l_partkey as part_key,
        l_suppkey as supplier_key,

        -- line details
        l_linenumber as line_number,
        l_quantity as quantity,
        l_extendedprice as gross_item_sales_amount,
        l_discount as discount_percentage,
        l_tax as tax_rate,

        -- statuses & flags
        l_returnflag as return_flag,
        l_linestatus as line_status,

        -- dates
        l_shipdate as ship_date,
        l_commitdate as commit_date,
        l_receiptdate as receipt_date,

        -- metadata & context
        l_shipinstruct as shipping_instructions,
        l_shipmode as shipping_mode,
        l_comment as comment

    from source

)

select * from renamed