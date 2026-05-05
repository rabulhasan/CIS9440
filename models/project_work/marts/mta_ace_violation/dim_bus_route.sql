-- models/project_work/marts/dimensions/dim_bus_route.sql
{{ config(materialized='table') }}

WITH routes AS (

    SELECT DISTINCT
        route_id AS bus_route_id
    
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE bus_route_id IS NOT NULL

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['bus_route_id']) }} AS route_key,
    bus_route_id
FROM routes