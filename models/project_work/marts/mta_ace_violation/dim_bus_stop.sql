-- models/project_work/marts/dimensions/dim_bus_stop.sql
{{ config(materialized='table') }}

SELECT DISTINCT
    
    stop_id,
    stop_name
FROM {{ ref('stg_mta_ace_violations') }}
WHERE stop_id IS NOT NULL