with parts as (
    select * from {{ ref('stg_tpch_part') }}
),
final as (

select
    part_key,
    part_name,
    manufacturer,
    brand,
    part_type,
    part_size,
    container,
    retail_price,
    comment
from parts
)

select * from final