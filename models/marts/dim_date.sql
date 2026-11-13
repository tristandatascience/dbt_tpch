-- Dimension des dates
--
-- Grain : un jour calendaire.
--
-- Dimension autonome : elle ne dépend d'aucun autre modèle du projet, ce qui
-- permet à n'importe quel fait de la référencer par son `date_key`.
--
-- La plage couverte est paramétrée par les variables `dim_date_start_date` et
-- `dim_date_end_date` (voir dbt_project.yml). Elle doit couvrir l'ensemble des
-- dates présentes dans les faits, sinon les clés étrangères date seraient NULL
-- et le test `not_null` associé échouerait.
--
-- Le nombre de jours est calculé en Jinja (modules.datetime) : la génération de
-- la série ne requiert aucun aller-retour en base au moment du compile.

{%- set start_date = var('dim_date_start_date', '1992-01-01') -%}
{%- set end_date = var('dim_date_end_date', '1999-12-31') -%}
{%- set start = modules.datetime.datetime.strptime(start_date, '%Y-%m-%d').date() -%}
{%- set end = modules.datetime.datetime.strptime(end_date, '%Y-%m-%d').date() -%}
{%- set nb_days = (end - start).days + 1 %}

with date_spine as (

    select dateadd(day, seq4(), date '{{ start_date }}') as date_day
    from table(generator(rowcount => {{ nb_days }}))

),

final as (

    select
        -- Clé primaire surrogate (entier YYYYMMDD)
        date_part(year, date_day) * 10000
            + date_part(month, date_day) * 100
            + date_part(day, date_day) as date_key,

        -- Colonne naturelle : c'est elle qu'on joint avec les dates des faits
        date_day,

        -- Année, trimestre, mois
        date_part(year, date_day) as year_number,
        date_part(quarter, date_day) as quarter_number,
        date_part(month, date_day) as month_number,
        to_char(date_day, 'Month') as month_name,

        -- Jour
        date_part(day, date_day) as day_of_month_number,
        date_part(dayofweek, date_day) as day_of_week_number,
        trim(to_char(date_day, 'Day')) as day_of_week_name,

        -- Position dans l'année
        date_part(dayofyear, date_day) as day_of_year_number,
        date_part(week, date_day) as week_of_year_number,

        -- Indicateurs
        (date_part(dayofweek, date_day) in (0, 6)) as is_weekend,
        (date_part(day, date_day) = 1) as is_month_start,
        (date_day = last_day(date_day)) as is_month_end

    from date_spine

)

select * from final
