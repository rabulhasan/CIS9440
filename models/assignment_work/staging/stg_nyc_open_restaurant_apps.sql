-- Clean and standardize NYC Open Restaurant Application data
-- One row per unique application

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
   SELECT
       -- Standardize all columns except those being transformed below
       * EXCEPT (
           globalid,
           objectid,
           time_of_submission,
           borough,
           zip,
           approved_for_sidewalk_seating,
           approved_for_roadway_seating,
           food_service_establishment,
           roadway_dimensions_area,
           sidewalk_dimensions_area,
           latitude,
           longitude,
           bulding_number,
           restaurant_name,
           doing_business_as_dba           
       ),

       -- Identifiers
       CAST(globalid AS STRING) AS application_id,
       CAST(objectid AS STRING) AS row_id,

       -- Date/Time
       CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,
       
        -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
           WHEN LENGTH(CAST(zip AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zip AS STRING)
           ELSE NULL
       END AS zip,

       -- Building/Street
       CAST(bulding_number AS STRING) AS building_number,
       UPPER(TRIM(street)) AS street_name,

       -- Seating Approvals (Convert 'yes'/'no' strings to Boolean)
       CASE WHEN LOWER(TRIM(approved_for_sidewalk_seating)) = 'yes' THEN TRUE ELSE FALSE END AS is_sidewalk_approved,
       CASE WHEN LOWER(TRIM(approved_for_roadway_seating)) = 'yes' THEN TRUE ELSE FALSE END AS is_roadway_approved,

       -- Business Details
       CAST(food_service_establishment AS STRING) AS permit_number, -- Kept as string due to text entries like 'Not Available'
       UPPER(TRIM(restaurant_name)) AS restaurant_name,
       UPPER(TRIM(doing_business_as_dba)) AS dba_name,

       -- Dimensions (Numeric Cast)
       CAST(roadway_dimensions_area AS DECIMAL) AS roadway_area_sqft,
       CAST(sidewalk_dimensions_area AS DECIMAL) AS sidewalk_area_sqft,

       -- Geolocation
       CAST(latitude AS DECIMAL) AS latitude,
       CAST(longitude AS DECIMAL) AS longitude,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   WHERE globalid IS NOT NULL
     AND time_of_submission IS NOT NULL

   -- Deduplicate: Keep the most recent submission if the same GlobalID appears twice
   QUALIFY ROW_NUMBER() OVER (PARTITION BY globalid ORDER BY time_of_submission DESC) = 1
)

SELECT * FROM cleaned