-- toronto shelter occupancy and capacity analysis (2024 + 2025)
-- source: city of toronto open data

-- view the raw 2024 table.
SELECT *
FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_raw`
LIMIT 1000;

-- view the raw 2025 table.
SELECT *
FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2025_raw`
LIMIT 1000;


-- section 2 - profile
-- check rows and date coverage for each year.
WITH all_raw AS (
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_raw`
  UNION ALL
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2025_raw`
)
SELECT
  EXTRACT(YEAR FROM OCCUPANCY_DATE) AS occupancy_year,
  COUNT(*) AS row_count,
  MIN(OCCUPANCY_DATE) AS first_date,
  MAX(OCCUPANCY_DATE) AS last_date,
  COUNT(DISTINCT OCCUPANCY_DATE) AS distinct_days
FROM all_raw
GROUP BY occupancy_year
ORDER BY occupancy_year;

-- programs use either bed columns or room columns, not both.
-- combine them into one set of measures.
WITH all_raw AS (
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_raw`
  UNION ALL
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2025_raw`
)
SELECT
  COUNT(*) AS total_rows,
  COUNTIF(CAPACITY_ACTUAL_BED IS NOT NULL) AS bed_rows,
  COUNTIF(CAPACITY_ACTUAL_ROOM IS NOT NULL) AS room_rows,
  COUNTIF(CAPACITY_ACTUAL_BED IS NOT NULL AND CAPACITY_ACTUAL_ROOM IS NOT NULL) AS both_filled,
  COUNTIF(CAPACITY_ACTUAL_BED IS NULL AND CAPACITY_ACTUAL_ROOM IS NULL) AS neither_filled
FROM all_raw;

-- some confidential programs do not include a city.
-- keep these rows and label the city as unknown.
WITH all_raw AS (
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_raw`
  UNION ALL
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2025_raw`
)
SELECT
  EXTRACT(YEAR FROM OCCUPANCY_DATE) AS occupancy_year,
  COUNTIF(LOCATION_CITY IS NULL OR TRIM(LOCATION_CITY) = '') AS missing_city_rows,
  COUNT(DISTINCT CASE WHEN LOCATION_CITY IS NULL THEN PROGRAM_NAME END) AS affected_programs
FROM all_raw
GROUP BY occupancy_year
ORDER BY occupancy_year;

-- some 2025 rows have no program model, label as unknown for cleaning
WITH all_raw AS (
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_raw`
  UNION ALL
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2025_raw`
)
SELECT
  EXTRACT(YEAR FROM OCCUPANCY_DATE) AS occupancy_year,
  COUNTIF(PROGRAM_MODEL IS NULL) AS null_program_model
FROM all_raw
GROUP BY occupancy_year
ORDER BY occupancy_year;

-- check the occupancy rate range, keep rates above 100 because they show over-capacity nights.
WITH all_raw AS (
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_raw`
  UNION ALL
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2025_raw`
)
SELECT
  MIN(OCCUPANCY_RATE_BEDS) AS min_bed_rate,
  MAX(OCCUPANCY_RATE_BEDS) AS max_bed_rate,
  MIN(OCCUPANCY_RATE_ROOMS) AS min_room_rate,
  MAX(OCCUPANCY_RATE_ROOMS) AS max_room_rate
FROM all_raw;

-- check for duplicate program and date rows, no duplicates means no deduping is needed.
WITH all_raw AS (
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_raw`
  UNION ALL
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2025_raw`
)
SELECT OCCUPANCY_DATE, PROGRAM_ID, COUNT(*) AS records
FROM all_raw
GROUP BY OCCUPANCY_DATE, PROGRAM_ID
HAVING COUNT(*) > 1;


-- section 3 - clean
CREATE TABLE `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean` AS
WITH combined AS (
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_raw`
  UNION ALL
  SELECT * FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2025_raw`
)
SELECT
  _id AS record_id,
  OCCUPANCY_DATE AS occupancy_date,
  EXTRACT(YEAR FROM OCCUPANCY_DATE) AS occupancy_year,
  EXTRACT(MONTH FROM OCCUPANCY_DATE) AS occupancy_month,
  FORMAT_DATE('%B', OCCUPANCY_DATE) AS occupancy_month_name,
  FORMAT_DATE('%Y-%m', OCCUPANCY_DATE) AS year_month,
  ORGANIZATION_NAME AS organization_name,
  SHELTER_GROUP AS shelter_group,
  -- trim spaces so the same site is not split into separate values.
  COALESCE(NULLIF(TRIM(LOCATION_NAME), ''), 'Unknown') AS location_name,
  -- use unknown when the city is missing.
  COALESCE(NULLIF(TRIM(LOCATION_CITY), ''), 'Unknown') AS location_city,
  SECTOR AS sector,
  -- use unknown when the program model is missing.
  COALESCE(PROGRAM_MODEL, 'Unknown') AS program_model,
  OVERNIGHT_SERVICE_TYPE AS overnight_service_type,
  PROGRAM_AREA AS program_area,
  PROGRAM_NAME AS program_name,
  CAPACITY_TYPE AS capacity_type,
  SERVICE_USER_COUNT AS service_user_count,
  -- combine the bed and room columns.
  COALESCE(CAPACITY_ACTUAL_BED, CAPACITY_ACTUAL_ROOM) AS capacity_actual,
  COALESCE(OCCUPIED_BEDS, OCCUPIED_ROOMS) AS occupied_spaces,
  ROUND(COALESCE(OCCUPANCY_RATE_BEDS, OCCUPANCY_RATE_ROOMS), 1) AS occupancy_rate,
  -- group each row by capacity level.
  CASE
    WHEN COALESCE(OCCUPANCY_RATE_BEDS, OCCUPANCY_RATE_ROOMS) >= 100 THEN 'At Capacity'
    WHEN COALESCE(OCCUPANCY_RATE_BEDS, OCCUPANCY_RATE_ROOMS) >= 90  THEN 'Near Capacity'
    ELSE 'Available'
  END AS capacity_status
FROM combined;


-- section 4 - validate
-- check row counts and confirm key fields are not null.
SELECT
  COUNT(*) AS cleaned_rows,
  COUNTIF(occupancy_year = 2024) AS rows_2024,
  COUNTIF(occupancy_year = 2025) AS rows_2025,
  COUNTIF(capacity_actual IS NULL) AS null_capacity,
  COUNTIF(occupied_spaces IS NULL) AS null_occupied,
  COUNTIF(occupancy_rate IS NULL) AS null_rate,
  COUNTIF(location_city = 'Unknown') AS unknown_city,
  COUNTIF(program_model = 'Unknown') AS unknown_model
FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`;

-- check the occupancy rate range.
SELECT
  MIN(occupancy_rate) AS min_rate,
  MAX(occupancy_rate) AS max_rate
FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`;

-- check the number of rows in each capacity group.
SELECT capacity_status, COUNT(*) AS program_days
FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`
GROUP BY capacity_status
ORDER BY program_days DESC;


-- section 5 - analyze
-- q1. did overall shelter pressure change from 2024 to 2025?
SELECT
  occupancy_year,
  COUNT(*) AS program_days,
  COUNT(DISTINCT program_name) AS programs,
  ROUND(AVG(occupancy_rate), 1) AS avg_occupancy_rate,
  ROUND(100 * COUNTIF(capacity_status = 'At Capacity') / COUNT(*), 1) AS pct_days_at_capacity,
  SUM(service_user_count) AS total_service_user_days
FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`
GROUP BY occupancy_year
ORDER BY occupancy_year;

-- q2. how did occupancy change by sector?
SELECT
  sector,
  ROUND(AVG(CASE WHEN occupancy_year = 2024 THEN occupancy_rate END), 1) AS avg_rate_2024,
  ROUND(AVG(CASE WHEN occupancy_year = 2025 THEN occupancy_rate END), 1) AS avg_rate_2025,
  SUM(CASE WHEN occupancy_year = 2024 THEN service_user_count ELSE 0 END) AS demand_2024,
  SUM(CASE WHEN occupancy_year = 2025 THEN service_user_count ELSE 0 END) AS demand_2025
FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`
GROUP BY sector
ORDER BY demand_2025 DESC;

-- q3. are emergency programs more full than transitional programs?
SELECT
  program_model,
  ROUND(AVG(CASE WHEN occupancy_year = 2024 THEN occupancy_rate END), 1) AS avg_rate_2024,
  ROUND(AVG(CASE WHEN occupancy_year = 2025 THEN occupancy_rate END), 1) AS avg_rate_2025
FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`
GROUP BY program_model
ORDER BY avg_rate_2025 DESC;

-- q4. what is the monthly occupancy trend? how does each month compare with the same month last year?
WITH monthly AS (
  SELECT
    year_month,
    occupancy_month,
    occupancy_year,
    ROUND(AVG(occupancy_rate), 1) AS avg_occupancy_rate
  FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`
  GROUP BY year_month, occupancy_month, occupancy_year
)
SELECT
  year_month,
  avg_occupancy_rate,
  LAG(avg_occupancy_rate) OVER (
    PARTITION BY occupancy_month ORDER BY occupancy_year
  ) AS same_month_prior_year,
  ROUND(
    avg_occupancy_rate - LAG(avg_occupancy_rate) OVER (
      PARTITION BY occupancy_month ORDER BY occupancy_year
    ), 1
  ) AS yoy_change
FROM monthly
ORDER BY year_month;

-- q5. which service types had the highest occupancy?
SELECT
  overnight_service_type,
  COUNTIF(occupancy_year = 2024) AS program_days_2024,
  COUNTIF(occupancy_year = 2025) AS program_days_2025,
  ROUND(AVG(CASE WHEN occupancy_year = 2024 THEN occupancy_rate END), 1) AS avg_rate_2024,
  ROUND(AVG(CASE WHEN occupancy_year = 2025 THEN occupancy_rate END), 1) AS avg_rate_2025
FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`
GROUP BY overnight_service_type
ORDER BY avg_rate_2025 DESC;

-- q6. which organizations had the most demand? 24-25 year's total for comparison.
WITH org_totals AS (
  SELECT
    organization_name,
    SUM(service_user_count) AS total_user_days,
    SUM(CASE WHEN occupancy_year = 2024 THEN service_user_count ELSE 0 END) AS user_days_2024,
    SUM(CASE WHEN occupancy_year = 2025 THEN service_user_count ELSE 0 END) AS user_days_2025
  FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`
  GROUP BY organization_name
)
SELECT
  DENSE_RANK() OVER (ORDER BY total_user_days DESC) AS demand_rank,
  organization_name,
  total_user_days,
  user_days_2024,
  user_days_2025
FROM org_totals
ORDER BY demand_rank
LIMIT 10;

-- q7. which programs had a higher rate than their sector average? compared each program with its sector average for the same year.
WITH program_stats AS (
  SELECT
    occupancy_year,
    sector,
    program_name,
    ROUND(AVG(occupancy_rate), 1) AS program_avg_rate,
    ROUND(AVG(AVG(occupancy_rate)) OVER (PARTITION BY occupancy_year, sector), 1) AS sector_avg_rate
  FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`
  GROUP BY occupancy_year, sector, program_name
)
SELECT
  occupancy_year,
  sector,
  program_name,
  program_avg_rate,
  sector_avg_rate,
  ROUND(program_avg_rate - sector_avg_rate, 1) AS points_above_sector
FROM program_stats
WHERE program_avg_rate > sector_avg_rate
ORDER BY points_above_sector DESC
LIMIT 15;

-- q8. how was demand split by program area, and did it change?
WITH area_year AS (
  SELECT
    program_area,
    occupancy_year,
    SUM(service_user_count) AS user_days
  FROM `toronto-shelter-analytics24-25.shelter_data.shelter_occupancy_2024_2025_clean`
  GROUP BY program_area, occupancy_year
)
SELECT
  program_area,
  ROUND(100 * SUM(CASE WHEN occupancy_year = 2024 THEN user_days ELSE 0 END)
        / SUM(SUM(CASE WHEN occupancy_year = 2024 THEN user_days ELSE 0 END)) OVER (), 1) AS demand_share_2024,
  ROUND(100 * SUM(CASE WHEN occupancy_year = 2025 THEN user_days ELSE 0 END)
        / SUM(SUM(CASE WHEN occupancy_year = 2025 THEN user_days ELSE 0 END)) OVER (), 1) AS demand_share_2025
FROM area_year
GROUP BY program_area
ORDER BY demand_share_2025 DESC;
