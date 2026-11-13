-- fct_supplier_parts : table de faits d'approvisionnement / catalogue fournisseur
--
-- Processus métier : Approvisionnement / Disponibilité catalogue fournisseur.
-- Grain : un couple pièce x fournisseur (part_key, supplier_key).
--
-- Deuxième table de faits du projet, aux côtés de fct_order_items (processus
-- « Vente client »). Les deux partagent les mêmes dimensions conformes :
-- dim_parts et dim_suppliers, ce qui permet à un outil de BI de croiser dans
-- un même tableau de bord le chiffre d'affaires vendu et le niveau de stock.
--
-- Ce fait ne porte pas de dimension temporelle : il décrit l'état courant du
-- catalogue fournisseurs (quantité disponible et coût d'achat unitaire par
-- couple pièce x fournisseur), et non un historique d'événements.
--
-- Mesures :
--   available_quantity : semi-additive (quantité en stock)
--   supply_cost        : non additive / unitaire
--   total_stock_value  : additive (available_quantity * supply_cost)
--
-- Les colonnes `comment` de la source ne sont pas publiées ici : elles sont
-- conservées au niveau staging, où la source est représentée fidèlement.

with partsupp as (

    select * from {{ ref('stg_tpch_partsupp') }}

)

select
    -- Clé primaire (surrogate)
    part_supplier_key,

    -- Clés étrangères (dimensions conformes)
    part_key,
    supplier_key,

    -- Mesures
    available_quantity,
    supply_cost,
    round(available_quantity * supply_cost, 2) as total_stock_value

from partsupp
