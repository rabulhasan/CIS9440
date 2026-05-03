-- Location dimension shared by 311 and ACE data
{{ config(materialized='table') }}

WITH all_locations AS (
    -- Get locations from 311 requests
    SELECT DISTINCT
        UPPER(TRIM(borough)) AS borough
    FROM {{ ref('stg_nyc_311_illegal_traffic') }}
    WHERE borough IS NOT NULL

    UNION DISTINCT

    -- Get locations from ace violation
    SELECT DISTINCT
        UPPER(TRIM(borough)) AS borough
    FROM {{ ref('stg_mta_ace_violations') }}
    WHERE borough IS NOT NULL
),

location_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['borough']) }} AS location_key,
        borough
    FROM all_locations
)

SELECT * FROM location_dimension