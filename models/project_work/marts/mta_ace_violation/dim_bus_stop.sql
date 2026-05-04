-- models/project_work/marts/dimensions/dim_bus_stop.sql
{{ config(materialized='table') }}

SELECT DISTINCT
    bus_stop_id,
    stop_id,
    stop_name
FROM {{ ref('stg_mta_ace_violations') }}
WHERE bus_stop_id IS NOT NULL