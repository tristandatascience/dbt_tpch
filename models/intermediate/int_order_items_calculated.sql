-- Intermediate : lignes de commande enrichies et valorisées
--
-- Grain  : une ligne par ligne de commande (l_orderkey, l_linenumber).
-- Rôle   : porter la logique de calcul métier (remise, TVA, montant net, coût
--          d'achat, marge) et les attributs analytiques dérivés. Le mart
--          `fct_order_items` n'assemble plus que le schéma en étoile publié.
--
-- Le `inner join` sur orders et le `left join` sur part_suppliers sont
-- identiques à ceux du mart : le grain est préservé (1 ligne = 1 ligne de
-- commande). Deux tests le garantissent :
--   - `unique` sur order_item_key  -> détecte tout fan-out du left join
--   - `equal_rowcount` vs stg_tpch_line_items -> détecte toute perte de ligne

with line_items as (

    select * from {{ ref('stg_tpch_line_items') }}

),

orders as (

    select * from {{ ref('stg_tpch_orders') }}

),

part_suppliers as (

    select * from {{ ref('stg_tpch_partsupp') }}

),

joined as (

    select
        -- Grain / clé primaire
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

        -- Attributs de commande (dimensions dégénérées)
        orders.order_status,
        orders.order_priority,

        -- Attributs de ligne
        line_items.line_number,
        line_items.return_flag,
        line_items.line_status,
        line_items.shipping_mode,
        line_items.shipping_instructions,
        line_items.comment,

        -- Quantités et coûts unitaires
        line_items.quantity,
        part_suppliers.supply_cost,

        -- Montants bruts et taux
        line_items.gross_item_sales_amount,
        line_items.discount_percentage,
        line_items.tax_rate

    from line_items

    inner join orders
        on line_items.order_key = orders.order_key

    left join part_suppliers
        on line_items.part_key = part_suppliers.part_key
       and line_items.supplier_key = part_suppliers.supplier_key

),

calculated as (

    select
        *,

        -- Montants calculés ----------------------------------------------------
        round(
            gross_item_sales_amount * discount_percentage,
            2
        ) as item_discount_amount,

        round(
            gross_item_sales_amount * (1 - discount_percentage),
            2
        ) as net_item_sales_amount,

        round(
            gross_item_sales_amount * (1 - discount_percentage) * tax_rate,
            2
        ) as item_tax_amount,

        round(
            gross_item_sales_amount * (1 - discount_percentage) * (1 + tax_rate),
            2
        ) as total_item_sales_amount_with_tax,

        -- Coûts et marge commerciale ------------------------------------------
        round(
            quantity * coalesce(supply_cost, 0),
            2
        ) as total_cost_amount,

        round(
            (gross_item_sales_amount * (1 - discount_percentage))
            - (quantity * coalesce(supply_cost, 0)),
            2
        ) as gross_profit_amount,

        -- Attributs analytiques dérivés ----------------------------------------
        datediff('day', order_date, ship_date) as delivery_delay_days,

        (return_flag = 'R') as is_returned

    from joined

),

final as (

    select
        *,

        -- NULL si le montant net est nul (remise de 100 %) : division impossible
        round(
            gross_profit_amount / nullif(net_item_sales_amount, 0),
            4
        ) as gross_margin_percentage

    from calculated

)

select * from final
