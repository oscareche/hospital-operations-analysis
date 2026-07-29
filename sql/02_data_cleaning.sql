DROP TABLE IF EXISTS hospital_operations.hospital_operations_clean;

CREATE TABLE hospital_operations.hospital_operations_clean AS
SELECT
    Patient_ID,
    
-- Standardise three date formats found in the raw data:
-- YYYY-MM-DD, DD-MM-YYYY and YYYY/MM/DD.
    
    CASE
    WHEN Visit_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN STR_TO_DATE(Visit_Date, '%Y-%m-%d')
    WHEN Visit_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
        THEN STR_TO_DATE(Visit_Date, '%d-%m-%Y')
    WHEN Visit_Date REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
        THEN STR_TO_DATE(Visit_Date, '%Y/%m/%d')
    ELSE NULL
END AS Visit_Date,
    CAST(Age AS UNSIGNED) AS Age,
    NULLIF(TRIM(Gender), '') AS Gender,
	NULLIF(TRIM(Disease), '') AS Disease,
	NULLIF(TRIM(Severity), '') AS Severity,
	NULLIF(TRIM(Admission_Type), '') AS Admission_Type,
    CAST(NULLIF(TRIM(Length_of_Stay), '') AS UNSIGNED) AS Length_of_Stay,
    Bed_Required,
    ICU_Required,
    Oxygen_Required,
    Ventilator_Required,
    CAST(Total_Beds_Available AS UNSIGNED) AS Total_Beds_Available,
    CAST(Beds_Occupied AS UNSIGNED) AS Beds_Occupied,
    CAST(ICU_Beds_Available AS UNSIGNED) AS ICU_Beds_Available,
    CAST(ICU_Beds_Occupied AS UNSIGNED) AS ICU_Beds_Occupied,
    CAST(NULLIF(TRIM(Oxygen_Units_Used), '') AS UNSIGNED) AS Oxygen_Units_Used,
    NULLIF(TRIM(Month), '') AS Month,
	NULLIF(TRIM(Season), '') AS Season,
	NULLIF(TRIM(Day_of_Week), '') AS Day_of_Week,
	NULLIF(TRIM(Department), '') AS Department,
	NULLIF(TRIM(Readmission_Within_30_Days), '') AS Readmission_Within_30_Days
FROM hospital_operations.hospital_operations_raw;

-- =========================================================
-- VALIDATION
-- Confirm that the cleaned table contains all source records.
-- =========================================================

SELECT COUNT(*) AS total_clean_rows
FROM hospital_operations_clean;

-- Check the data types assigned to the cleaned columns.

DESCRIBE hospital_operations_clean;

-- Validation result:
-- Length_of_Stay and Oxygen_Units_Used were converted from text
-- to numeric fields while preserving blank values as NULL.

SELECT
    SUM(CASE WHEN Length_of_Stay IS NULL THEN 1 ELSE 0 END) AS missing_length_of_stay,
    SUM(CASE WHEN Oxygen_Units_Used IS NULL THEN 1 ELSE 0 END) AS missing_oxygen_units
FROM hospital_operations_clean;

-- Validation result:
-- 50 Length_of_Stay values remain NULL.
-- 100 Oxygen_Units_Used values remain NULL.
-- Missing values were preserved during numeric conversion.

SELECT COUNT(*) AS total_clean_rows
FROM hospital_operations_clean;

-- Final row-count validation:
-- The cleaned table contains all 5,075 source records.
-- No rows were lost during cleaning and type conversion.

SELECT COUNT(*) AS missing_visit_dates
FROM hospital_operations_clean
WHERE Visit_Date IS NULL;

-- Validation result:
-- All 25 previously missing Visit_Date values were recovered
-- after adding support for the YYYY/MM/DD date format.
-- The cleaned table now contains no NULL visit dates.