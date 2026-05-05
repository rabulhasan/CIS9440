-- models/project_work/marts/facts/fact_311_complaints.sql
{{ config(materialized='table') }}

WITH source_data AS (

    SELECT
        CAST(created_date AS DATE) AS complaint_date,
        created_date,
        latitude,
        longitude,
        status,
        agency,
        complaint_type,
        descriptor AS problem_detail,
        borough,
        incident_zip 
    FROM {{ ref('stg_nyc_311_illegal_traffic') }}
    WHERE created_date IS NOT NULL

),

joined AS (

    SELECT
        d.date_key,
        l.location_key,
        p.problem_key,
        s.latitude,
        s.longitude,
        s.status,
        s.created_date AS create_date

    FROM source_data s

    LEFT JOIN {{ ref('dim_date_project') }} d 
        ON s.complaint_date = d.full_date

    LEFT JOIN {{ ref('dim_location_project') }} l
       
        ON UPPER(TRIM(s.borough)) = l.borough 

    LEFT JOIN {{ ref('dim_311_problem') }} p
        ON s.agency = p.agency
        AND s.complaint_type = p.complaint_type
        AND s.problem_detail = p.problem_detail

)

SELECT *
FROM joined