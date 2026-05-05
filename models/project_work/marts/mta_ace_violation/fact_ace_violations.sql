-- models/project_work/marts/facts/fact_ace_violations.sql
{{ config(materialized='table') }}

WITH source_data AS (
    SELECT
        violation_id,
        CAST(first_occurrence_at AS DATE) AS violation_date,
        first_occurrence_at,
        last_occurrence_at,
        bus_route_id, 
        stop_id,       
        violation_type,
        borough,
        violation_latitude,
        violation_longitude
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE first_occurrence_at IS NOT NULL
),

joined AS (
    SELECT
        -- Fact Primary Key
        {{ dbt_utils.generate_surrogate_key(['s.violation_id']) }} AS violation_key,
        
        -- Dimension Foreign Keys
        d.date_key,
        l.location_key,
        vt.violation_type_key,
        r.route_key,
        bs.stop_key,  -- Pulled from dim_bus_stop join

        -- Measures / Timestamps
        s.violation_id AS natural_violation_id,
        s.first_occurrence_at AS first_occurrence,
        s.last_occurrence_at AS last_occurrence,
        s.violation_latitude,
        s.violation_longitude

    FROM source_data s

    LEFT JOIN {{ ref('dim_date_project') }} d  
        ON s.violation_date = d.full_date

    LEFT JOIN {{ ref('dim_location_project') }} l
       
        ON UPPER(TRIM(s.borough)) = l.borough 

    LEFT JOIN {{ ref('dim_ace_violation_type') }} vt
        ON s.violation_type = vt.violation_type

    LEFT JOIN {{ ref('dim_bus_route') }} r
        ON s.bus_route_id = r.bus_route_id

    LEFT JOIN {{ ref('dim_bus_stop') }} bs
        ON s.stop_id = bs.stop_id

)

SELECT * FROM joined