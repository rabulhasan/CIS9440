-- models/project_work/marts/dimensions/dim_311_problem.sql
{{ config(materialized='table') }}

WITH base AS (

    SELECT DISTINCT
        agency,
        complaint_type,
        descriptor AS problem_detail
    FROM {{ ref('stg_nyc_311_illegal_traffic') }}
    WHERE complaint_type IS NOT NULL

)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'agency',
        'complaint_type',
        'problem_detail'
    ]) }} AS problem_key,
    agency,
    complaint_type,
    problem_detail
FROM base