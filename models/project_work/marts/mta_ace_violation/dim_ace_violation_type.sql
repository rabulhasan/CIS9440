-- models/project_work/marts/dimensions/dim_ace_violation_type.sql
{{ config(materialized='table') }}

WITH base AS (

    SELECT DISTINCT
        violation_type
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE violation_type IS NOT NULL

),

mapped AS (

    SELECT
        violation_type,

        CASE
            WHEN LOWER(violation_type) LIKE '%bus lane%' THEN 'Bus Lane'
            WHEN LOWER(violation_type) LIKE '%bus stop%' THEN 'Bus Stop'
            WHEN LOWER(violation_type) LIKE '%double park%' THEN 'Double Parking'
            ELSE 'Other'
        END AS violation_category,

        'Issued' AS violation_status

    FROM base

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['violation_type']) }} AS violation_type_key,
    violation_type,
    violation_category,
    violation_status
FROM mapped