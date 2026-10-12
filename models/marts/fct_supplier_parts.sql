with partsupp as (

    select * from {{ ref('stg_tpch_partsupp') }}

),

final as (

    select
        -- surrogate primary key
        part_supplier_key,

        -- foreign keys (conformed dimensions)
        part_key,
        supplier_key,

        -- metrics
        available_quantity,
        supply_cost,
        round(available_quantity * supply_cost, 2) as total_stock_value,

        -- metadata
        comment

    from partsupp

)

select * from final