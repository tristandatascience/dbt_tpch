with line_items as (
    select * from {{ ref('stg_tpch_line_items') }}
),

orders as (
    select * from {{ ref('stg_tpch_orders') }}
),

part_suppliers as (
    select * from {{ ref('stg_tpch_partsupp') }}
),

final as (
    select
        -- Grain / Clé primaire
        line_items.order_item_key,

        -- Clés étrangères
        line_items.order_key,
        orders.customer_key,
        line_items.supplier_key,
        line_items.part_key,

        -- Dates
        orders.order_date,
        line_items.ship_date,
        line_items.commit_date,
        line_items.receipt_date,

        -- Attributs commande (Degenerate Dimensions)
        orders.order_status,
        orders.order_priority,

        -- Attributs ligne d'article
        line_items.line_number,
        line_items.return_flag,
        line_items.line_status,
        line_items.shipping_mode,
        line_items.shipping_instructions,
        line_items.comment,

        -- Quantités et coûts unitaires
        line_items.quantity,
        part_suppliers.supply_cost,

        -- Métriques de vente brutes et taux
        line_items.gross_item_sales_amount,
        line_items.discount_percentage,
        line_items.tax_rate,

        -- Montants intermédiaires calculés
        round(
            line_items.gross_item_sales_amount * line_items.discount_percentage,
            2
        ) as item_discount_amount,

        round(
            line_items.gross_item_sales_amount * (1 - line_items.discount_percentage),
            2
        ) as net_item_sales_amount,

        round(
            line_items.gross_item_sales_amount * (1 - line_items.discount_percentage) * line_items.tax_rate,
            2
        ) as item_tax_amount,

        round(
            line_items.gross_item_sales_amount * (1 - line_items.discount_percentage) * (1 + line_items.tax_rate),
            2
        ) as total_item_sales_amount_with_tax,

        -- Coûts et marge commerciale
        round(
            line_items.quantity * coalesce(part_suppliers.supply_cost, 0),
            2
        ) as total_cost_amount,

        round(
            (line_items.gross_item_sales_amount * (1 - line_items.discount_percentage))
            - (line_items.quantity * coalesce(part_suppliers.supply_cost, 0)),
            2
        ) as gross_profit_amount

    from line_items
    inner join orders
        on line_items.order_key = orders.order_key
    left join part_suppliers
        on line_items.part_key = part_suppliers.part_key
       and line_items.supplier_key = part_suppliers.supplier_key
)

select * from final