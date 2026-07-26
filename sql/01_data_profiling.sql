/*
Project: Hospital Operations Analysis
Script: 01_data_profiling.sql
Purpose: Inspect the raw hospital dataset and identify data-quality issues.
Source table: hospital_operations_raw
Note: This script does not modify the raw data.
*/

USE hospital_operations;

-- =========================================================
-- 1. IMPORT VALIDATION
-- Confirm that the number of imported rows matches the CSV.
-- Expected result: 5,075 rows.
-- =========================================================

SELECT COUNT(*) AS total_rows
FROM hospital_operations_raw;


-- Preview a small sample to confirm that values are aligned
-- with the correct column headings.

SELECT *
FROM hospital_operations_raw
LIMIT 10;


-- =========================================================
-- 2. MISSING-VALUE PROFILING
-- Count NULL values and blank strings in known problem fields.
-- =========================================================

SELECT
    SUM(
        CASE
            WHEN Length_of_Stay IS NULL
                 OR TRIM(Length_of_Stay) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_length_of_stay,

    SUM(
        CASE
            WHEN Oxygen_Units_Used IS NULL
                 OR TRIM(Oxygen_Units_Used) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_oxygen_units
FROM hospital_operations_raw;


-- Count rows where both fields are missing.
-- This checks the overlap between the two missing-value totals.

SELECT COUNT(*) AS rows_missing_both
FROM hospital_operations_raw
WHERE (Length_of_Stay IS NULL OR TRIM(Length_of_Stay) = '')
  AND (Oxygen_Units_Used IS NULL OR TRIM(Oxygen_Units_Used) = '');

-- Result: 3 rows are missing both Length_of_Stay and Oxygen_Units_Used.
-- Therefore, 147 unique rows are affected by missing values:
-- 50 + 100 - 3 = 147.