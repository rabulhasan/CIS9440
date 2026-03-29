 SELECT
     time_of_submission, objectid, restaurant_name, zip 
 FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
 LIMIT 10