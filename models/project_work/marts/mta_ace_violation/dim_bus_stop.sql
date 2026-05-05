-- models/project_work/marts/dimensions/dim_bus_stop.sql
{{ config(materialized='table') }}

WITH base_stops AS (
    SELECT DISTINCT
        stop_id,
        stop_name
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE stop_id IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['stop_id']) }} AS stop_key,
    stop_id,
    stop_name
FROM base_stops