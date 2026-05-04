-- models/project_work/marts/facts/fact_ace_violations.sql
{{ config(materialized='table') }}

WITH source_data AS (

    SELECT
        violation_id,
        CAST(first_occurrence_at AS DATE) AS violation_date,
        first_occurrence_at,
        last_occurrence_at,
        route_id,
        bus_stop_id,
        violation_latitude,
        violation_longitude,
        violation_type,
        borough,
        zip_code
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE first_occurrence_at IS NOT NULL

),

joined AS (

    SELECT
        s.violation_id,
        d.date_key,
        l.location_key,
        vt.violation_type_key,
        r.route_key,
        bs.bus_stop_id,
        s.violation_latitude,
        s.violation_longitude,
        s.first_occurrence_at AS first_occurrence,
        s.last_occurrence_at AS last_occurrence

    FROM source_data s

    LEFT JOIN {{ ref('dim_date') }} d
        ON s.violation_date = d.full_date

    LEFT JOIN {{ ref('dim_location') }} l
        ON s.borough = l.borough
        AND s.zip_code = l.zip_code

    LEFT JOIN {{ ref('dim_ace_violation_type') }} vt
        ON s.violation_type = vt.violation_type

    LEFT JOIN {{ ref('dim_bus_route') }} r
        ON s.route_id = r.bus_route_id

    LEFT JOIN {{ ref('dim_bus_stop') }} bs
        ON s.bus_stop_id = bs.bus_stop_id

)

SELECT *
FROM joined