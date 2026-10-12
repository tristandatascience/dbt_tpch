{% macro generate_model_from_ref(model_name) %}
  {%- set relation = ref(model_name) -%}
  {%- set columns = adapter.get_columns_in_relation(relation) -%}

  {%- if columns | length == 0 -%}
    {{ log("Aucune colonne trouvée. Vérifie que le modèle a bien été exécuté (dbt run).", info=True) }}
  {%- else -%}
    {%- set ref_call = "{{ ref('" ~ model_name ~ "') }}" -%}

    {{ log("with " ~ model_name ~ " as (", info=True) }}
    {{ log("    select * from " ~ ref_call, info=True) }}
    {{ log("),", info=True) }}
    {{ log("", info=True) }}
    {{ log("final as (", info=True) }}
    {{ log("    select", info=True) }}

    {%- for col in columns %}
      {%- if not loop.last %}
        {{ log("        " ~ col.name | lower ~ ",", info=True) }}
      {%- else %}
        {{ log("        " ~ col.name | lower, info=True) }}
      {%- endif %}
    {%- endfor %}

    {{ log("    from " ~ model_name, info=True) }}
    {{ log(")", info=True) }}
    {{ log("", info=True) }}
    {{ log("select * from final", info=True) }}
  {%- endif -%}
{% endmacro %}