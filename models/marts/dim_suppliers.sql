with suppliers as (
    select * from {{ ref('stg_tpch_suppliers') }}
),

nations as (
    select * from {{ ref('stg_tpch_nations') }}
),

regions as (
    select * from {{ ref('stg_tpch_regions') }}
),

final as (
    select
        -- Clé primaire
        suppliers.supplier_key,

        -- Attributs fournisseur
        suppliers.supplier_name,
        suppliers.address,
        suppliers.phone_number,
        suppliers.account_balance,

        -- Géographie aplatie
        nations.nation_name as country,
        regions.region_name as continent,

        -- Métadonnées
        suppliers.comment

    from suppliers
    inner join nations
        on suppliers.nation_key = nations.nation_key
    inner join regions
        on nations.region_key = regions.region_key
)

select * from final