-- Clean and standardize MTA Bus Route Segment data
-- Grain: One row per route segment per time aggregation

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_MTA_Bus_Route_Segment') }}
),

cleaned AS (
    SELECT
        -- Get all columns except ones being explicitly cast or transformed below
        * EXCEPT (
            average_road_speed,
            average_travel_time,
            bus_trip_count,
            day_of_week,
            direction,
            hour_of_day,
            month,
            next_timepoint_stop_id,
            next_timepoint_stop_latitude,
            next_timepoint_stop_longitude,
            next_timepoint_stop_name,
            road_distance,
            route_id,
            route_type,
            stop_order,
            timepoint_stop_id,
            timepoint_stop_latitude,
            timepoint_stop_longitude,
            timepoint_stop_name,
            timestamp,
            year,
            borough
        ),

        -- Identifiers & Dimensions
        CAST(route_id AS STRING) AS route_id,
        CAST(stop_order AS INT64) AS stop_order,
        UPPER(TRIM(direction)) AS direction,
        CAST(route_type AS STRING) AS route_type,

        -- Temporal Data (Crucial to cast from STRING)
        CAST(timestamp AS TIMESTAMP) AS timestamp,
        CAST(year AS INT64) AS year,
        CAST(month AS INT64) AS month,
        CAST(day_of_week AS STRING) AS day_of_week,
        CAST(hour_of_day AS INT64) AS hour_of_day,

        -- Origin Stop Details
        CAST(timepoint_stop_id AS STRING) AS timepoint_stop_id,
        CAST(timepoint_stop_name AS STRING) AS timepoint_stop_name,
        CAST(timepoint_stop_latitude AS FLOAT64) AS timepoint_stop_latitude,
        CAST(timepoint_stop_longitude AS FLOAT64) AS timepoint_stop_longitude,

        -- Destination Stop Details
        CAST(next_timepoint_stop_id AS STRING) AS next_timepoint_stop_id,
        CAST(next_timepoint_stop_name AS STRING) AS next_timepoint_stop_name,
        CAST(next_timepoint_stop_latitude AS FLOAT64) AS next_timepoint_stop_latitude,
        CAST(next_timepoint_stop_longitude AS FLOAT64) AS next_timepoint_stop_longitude,

        -- Metrics (Convert strings to numbers for calculation)
        CAST(average_road_speed AS FLOAT64) AS average_road_speed,
        CAST(average_travel_time AS FLOAT64) AS average_travel_time,
        CAST(bus_trip_count AS INT64) AS bus_trip_count,
        CAST(road_distance AS FLOAT64) AS road_distance,

        -- Location Standardized
        CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filter out rows with null essential keys or zero-speed noise
    WHERE route_id IS NOT NULL 
    AND timestamp IS NOT NULL
    AND SAFE_CAST(average_road_speed AS FLOAT64) > 0

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY route_id, direction, stop_order, timestamp 
        ORDER BY timestamp DESC
    ) = 1
)

SELECT * FROM cleaned