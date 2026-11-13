-- fct_order_items : table de faits des ventes
--
-- Grain : une ligne par article au sein d'une commande.
--
-- La logique de calcul métier (remise, TVA, montant net, coût d'achat, marge)
-- et les attributs dérivés sont isolés dans `int_order_items_calculated`.
-- Ce mart se contente d'assembler le schéma en étoile publié.
--
-- Les 4 dates du fait référencent la même dimension `dim_date` : c'est le
-- pattern de la dimension à rôle multiple (role-playing dimension). Chaque
-- alias produit une clé étrangère distincte vers dim_date.date_key.

with order_items as (

    select * from {{ ref('int_order_items_calculated') }}

),

dim_date as (

    select * from {{ ref('dim_date') }}

)

select
    -- Grain / clé primaire
    order_items.order_item_key,

    -- Clés étrangères
    order_items.order_key,
    order_items.customer_key,
    order_items.supplier_key,
    order_items.part_key,

    -- Dates
    order_items.order_date,
    order_items.ship_date,
    order_items.commit_date,
    order_items.receipt_date,

    -- Attributs commande (dimensions dégénérées)
    order_items.order_status,
    order_items.order_priority,

    -- Attributs ligne d'article
    order_items.line_number,
    order_items.return_flag,
    order_items.line_status,
    order_items.shipping_mode,
    order_items.shipping_instructions,

    -- Quantités et coûts unitaires
    order_items.quantity,
    order_items.supply_cost,

    -- Métriques de vente brutes et taux
    order_items.gross_item_sales_amount,
    order_items.discount_percentage,
    order_items.tax_rate,

    -- Montants calculés (issus de int_order_items_calculated)
    order_items.item_discount_amount,
    order_items.net_item_sales_amount,
    order_items.item_tax_amount,
    order_items.total_item_sales_amount_with_tax,
    order_items.total_cost_amount,
    order_items.gross_profit_amount,

    -- Attributs analytiques dérivés
    order_items.delivery_delay_days,
    order_items.is_returned,
    order_items.gross_margin_percentage,

    -- Clés étrangères date (dimension à rôle multiple -> dim_date)
    order_dates.date_key as order_date_key,
    ship_dates.date_key as ship_date_key,
    commit_dates.date_key as commit_date_key,
    receipt_dates.date_key as receipt_date_key

from order_items

left join dim_date as order_dates
    on order_items.order_date = order_dates.date_day

left join dim_date as ship_dates
    on order_items.ship_date = ship_dates.date_day

left join dim_date as commit_dates
    on order_items.commit_date = commit_dates.date_day

left join dim_date as receipt_dates
    on order_items.receipt_date = receipt_dates.date_day
