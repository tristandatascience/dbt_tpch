with source as (

    select * from {{ source('tpch', 'partsupp') }}

),

renamed as (

    select
       -- Clé surrogate primaire composite (recommandé dans dbt)
        {{ dbt_utils.generate_surrogate_key(['ps_partkey', 'ps_suppkey']) }} as part_supplier_key,

        -- Clés étrangères
        ps_partkey     as part_key,
        ps_suppkey     as supplier_key,

        -- Métriques de stock et de coût
        ps_availqty    as available_quantity,
        ps_supplycost  as supply_cost,

        -- Métadonnées
        ps_comment     as comment

    from source

)

select * from renamed