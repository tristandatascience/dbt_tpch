with customers as (
    select * from {{ ref('stg_tpch_customers') }}
),

nations as (
    select * from {{ ref('stg_tpch_nations') }}
),

regions as (
    select * from {{ ref('stg_tpch_regions') }}
),

final as (
    select
        customers.customer_key,
        customers.customer_name,
        customers.address,
        customers.phone_number,
        customers.account_balance,
        customers.market_segment,
        nations.nation_name as country,
        regions.region_name as continent
    from customers
    left join nations
        on customers.nation_key = nations.nation_key
    left join regions
        on nations.region_key = regions.region_key
)

select * from final