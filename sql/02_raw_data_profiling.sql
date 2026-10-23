-- =====================================================
-- HOSPITAL OPERATIONS ANALYSIS
-- 02 - RAW DATA PROFILING
-- =====================================================

USE hospital_operations;

-- Confirm the imported row count.

SELECT COUNT(*) as raw_row_count
FROM hospital_operations_raw;

-- Count repeated nonblank Patient_ID values. Repeated IDs are not assumed to
-- represent duplicate visits.

SELECT COUNT(*) AS repeated_patient_id_values
FROM (
    SELECT TRIM(Patient_ID) AS Patient_ID
    FROM hospital_operations_raw
    WHERE Patient_ID IS NOT NULL AND TRIM(Patient_ID) <> ''
    GROUP BY TRIM(Patient_ID)
    HAVING COUNT(*) > 1
) AS repeated_ids;

SELECT
    DATABASE() AS active_schema,
    COUNT(*) AS raw_rows,
    COUNT(DISTINCT NULLIF(TRIM(Patient_ID), '')) AS distinct_nonblank_patient_ids
FROM hospital_operations.hospital_operations_raw;

SELECT TRIM(Patient_ID) AS patient_id, COUNT(*) AS row_count
FROM hospital_operations.hospital_operations_raw
WHERE Patient_ID IS NOT NULL AND TRIM(Patient_ID) <> ''
GROUP BY TRIM(Patient_ID)
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 10;

-- Inspect all rows associated with repeated nonblank Patient_ID values.

SELECT
    raw.Patient_ID,
    raw.Visit_Date,
    raw.Age,
    raw.Gender,
    raw.Disease,
    raw.Severity,
    raw.Admission_Type,
    raw.Length_of_Stay,
    raw.Bed_Required,
    raw.ICU_Required,
    raw.Oxygen_Required,
    raw.Ventilator_Required,
    raw.Total_Beds_Available,
    raw.Beds_Occupied,
    raw.ICU_Beds_Available,
    raw.ICU_Beds_Occupied,
    raw.Oxygen_Units_Used,
    raw.Month,
    raw.Season,
    raw.Day_of_Week,
    raw.Department,
    raw.Readmission_Within_30_Days
FROM hospital_operations_raw AS raw
JOIN (
    SELECT TRIM(Patient_ID) AS Patient_ID
    FROM hospital_operations_raw
    WHERE Patient_ID IS NOT NULL AND TRIM(Patient_ID) <> ''
    GROUP BY TRIM(Patient_ID)
    HAVING COUNT(*) > 1
) AS repeated_ids
    ON TRIM(raw.Patient_ID) = repeated_ids.Patient_ID
ORDER BY TRIM(raw.Patient_ID), raw.Visit_Date;

-- Count exact repeated rows separately from repeated patient identifiers.

SELECT
    COUNT(*) AS exact_duplicate_groups,
    COALESCE(SUM(occurrences - 1), 0) AS excess_exact_duplicate_rows
FROM (
    SELECT COUNT(*) AS occurrences
    FROM hospital_operations_raw
    GROUP BY
        Patient_ID,
        Visit_Date,
        Age,
        Gender,
        Disease,
        Severity,
        Admission_Type,
        Length_of_Stay,
        Bed_Required,
        ICU_Required,
        Oxygen_Required,
        Ventilator_Required,
        Total_Beds_Available,
        Beds_Occupied,
        ICU_Beds_Available,
        ICU_Beds_Occupied,
        Oxygen_Units_Used,
        Month,
        Season,
        Day_of_Week,
        Department,
        Readmission_Within_30_Days
    HAVING COUNT(*) > 1
) AS exact_duplicate_groups;

-- Profile NULL and blank text values across all raw fields.

SELECT
    SUM(Patient_ID IS NULL OR TRIM(Patient_ID) = '') AS missing_patient_id,
    SUM(Visit_Date IS NULL OR TRIM(Visit_Date) = '') AS missing_visit_date,
    SUM(Age IS NULL OR TRIM(Age) = '') AS missing_age,
    SUM(Gender IS NULL OR TRIM(Gender) = '') AS missing_gender,
    SUM(Disease IS NULL OR TRIM(Disease) = '') AS missing_disease,
    SUM(Severity IS NULL OR TRIM(Severity) = '') AS missing_severity,
    SUM(Admission_Type IS NULL OR TRIM(Admission_Type) = '') AS missing_admission_type,
    SUM(Length_of_Stay IS NULL OR TRIM(Length_of_Stay) = '') AS missing_length_of_stay,
    SUM(Bed_Required IS NULL OR TRIM(Bed_Required) = '') AS missing_bed_required,
    SUM(ICU_Required IS NULL OR TRIM(ICU_Required) = '') AS missing_icu_required,
    SUM(Oxygen_Required IS NULL OR TRIM(Oxygen_Required) = '') AS missing_oxygen_required,
    SUM(Ventilator_Required IS NULL OR TRIM(Ventilator_Required) = '') AS missing_ventilator_required,
    SUM(Total_Beds_Available IS NULL OR TRIM(Total_Beds_Available) = '') AS missing_total_beds_available,
    SUM(Beds_Occupied IS NULL OR TRIM(Beds_Occupied) = '') AS missing_beds_occupied,
    SUM(ICU_Beds_Available IS NULL OR TRIM(ICU_Beds_Available) = '') AS missing_icu_beds_available,
    SUM(ICU_Beds_Occupied IS NULL OR TRIM(ICU_Beds_Occupied) = '') AS missing_icu_beds_occupied,
    SUM(Oxygen_Units_Used IS NULL OR TRIM(Oxygen_Units_Used) = '') AS missing_oxygen_units_used,
    SUM(Month IS NULL OR TRIM(Month) = '') AS missing_month,
    SUM(Season IS NULL OR TRIM(Season) = '') AS missing_season,
    SUM(Day_of_Week IS NULL OR TRIM(Day_of_Week) = '') AS missing_day_of_week,
    SUM(Department IS NULL OR TRIM(Department) = '') AS missing_department,
    SUM(Readmission_Within_30_Days IS NULL OR TRIM(Readmission_Within_30_Days) = '') AS missing_readmission_flag
FROM hospital_operations_raw;

-- Profile raw category values to identify inconsistent labels, casing and whitespace.

SELECT 'Gender' AS field_name, Gender AS raw_value, COUNT(*) AS row_count
FROM hospital_operations_raw
GROUP BY Gender
UNION ALL
SELECT 'Disease', Disease, COUNT(*)
FROM hospital_operations_raw
GROUP BY Disease
UNION ALL
SELECT 'Severity', Severity, COUNT(*)
FROM hospital_operations_raw
GROUP BY Severity
UNION ALL
SELECT 'Admission_Type', Admission_Type, COUNT(*)
FROM hospital_operations_raw
GROUP BY Admission_Type
UNION ALL
SELECT 'Bed_Required', Bed_Required, COUNT(*)
FROM hospital_operations_raw
GROUP BY Bed_Required
UNION ALL
SELECT 'ICU_Required', ICU_Required, COUNT(*)
FROM hospital_operations_raw
GROUP BY ICU_Required
UNION ALL
SELECT 'Oxygen_Required', Oxygen_Required, COUNT(*)
FROM hospital_operations_raw
GROUP BY Oxygen_Required
UNION ALL
SELECT 'Ventilator_Required', Ventilator_Required, COUNT(*)
FROM hospital_operations_raw
GROUP BY Ventilator_Required
UNION ALL
SELECT 'Season', Season, COUNT(*)
FROM hospital_operations_raw
GROUP BY Season
UNION ALL
SELECT 'Day_of_Week', Day_of_Week, COUNT(*)
FROM hospital_operations_raw
GROUP BY Day_of_Week
UNION ALL
SELECT 'Department', Department, COUNT(*)
FROM hospital_operations_raw
GROUP BY Department
UNION ALL
SELECT 'Readmission_Within_30_Days', Readmission_Within_30_Days, COUNT(*)
FROM hospital_operations_raw
GROUP BY Readmission_Within_30_Days
ORDER BY field_name, raw_value;

-- Classify supported Visit_Date formats before converting dates or derived fields.

SELECT
    CASE
        WHEN TRIM(Visit_Date) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 'YYYY-MM-DD'
        WHEN TRIM(Visit_Date) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN 'DD-MM-YYYY'
        WHEN TRIM(Visit_Date) REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN 'YYYY/MM/DD'
        ELSE 'Other or missing'
    END AS date_format,
    COUNT(*) AS row_count
FROM hospital_operations_raw
GROUP BY date_format
ORDER BY date_format;

-- Check date parseability and consistency with the supplied Month and Day_of_Week.

WITH parsed_dates AS (
    SELECT
        Visit_Date,
        Month,
        Day_of_Week,
        CASE
            WHEN TRIM(Visit_Date) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                THEN STR_TO_DATE(TRIM(Visit_Date), '%Y-%m-%d')
            WHEN TRIM(Visit_Date) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
                THEN STR_TO_DATE(TRIM(Visit_Date), '%d-%m-%Y')
            WHEN TRIM(Visit_Date) REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
                THEN STR_TO_DATE(TRIM(Visit_Date), '%Y/%m/%d')
            ELSE NULL
        END AS parsed_visit_date
    FROM hospital_operations_raw
)
SELECT
    SUM(parsed_visit_date IS NULL) AS unparsed_visit_dates,
    SUM(
        parsed_visit_date IS NOT NULL
        AND Month REGEXP '^[0-9]{1,2}$'
        AND CAST(Month AS UNSIGNED) <> MONTH(parsed_visit_date)
    ) AS month_mismatches,
    SUM(
        parsed_visit_date IS NOT NULL
        AND LOWER(TRIM(Day_of_Week)) <> LOWER(DAYNAME(parsed_visit_date))
    ) AS day_of_week_mismatches
FROM parsed_dates;

-- Profile numeric fields for blanks, non-integer text and observed ranges.

SELECT
    field_name,
    SUM(raw_value = '') AS blank_values,
    SUM(raw_value <> '' AND raw_value NOT REGEXP '^-?[0-9]+$') AS non_integer_values,
    MIN(CASE WHEN raw_value REGEXP '^-?[0-9]+$' THEN CAST(raw_value AS SIGNED) END) AS minimum_value,
    MAX(CASE WHEN raw_value REGEXP '^-?[0-9]+$' THEN CAST(raw_value AS SIGNED) END) AS maximum_value,
    SUM(raw_value REGEXP '^-?[0-9]+$' AND CAST(raw_value AS SIGNED) < 0) AS negative_values,
    SUM(raw_value REGEXP '^-?[0-9]+$' AND CAST(raw_value AS SIGNED) = 0) AS zero_values
FROM (
    SELECT 'Age' AS field_name, TRIM(Age) AS raw_value FROM hospital_operations_raw
    UNION ALL SELECT 'Length_of_Stay', TRIM(Length_of_Stay) FROM hospital_operations_raw
    UNION ALL SELECT 'Total_Beds_Available', TRIM(Total_Beds_Available) FROM hospital_operations_raw
    UNION ALL SELECT 'Beds_Occupied', TRIM(Beds_Occupied) FROM hospital_operations_raw
    UNION ALL SELECT 'ICU_Beds_Available', TRIM(ICU_Beds_Available) FROM hospital_operations_raw
    UNION ALL SELECT 'ICU_Beds_Occupied', TRIM(ICU_Beds_Occupied) FROM hospital_operations_raw
    UNION ALL SELECT 'Oxygen_Units_Used', TRIM(Oxygen_Units_Used) FROM hospital_operations_raw
    UNION ALL SELECT 'Month', TRIM(Month) FROM hospital_operations_raw
) AS numeric_fields
GROUP BY field_name
ORDER BY field_name;

-- Check resource-field combinations and recorded occupancy against capacity.

SELECT
    SUM(UPPER(TRIM(ICU_Required)) = 'YES' AND UPPER(TRIM(Bed_Required)) = 'NO') AS icu_yes_bed_no,
    SUM(UPPER(TRIM(Ventilator_Required)) = 'YES' AND UPPER(TRIM(Oxygen_Required)) = 'NO') AS ventilator_yes_oxygen_no,
    SUM(
        Beds_Occupied REGEXP '^[0-9]+$'
        AND Total_Beds_Available REGEXP '^[0-9]+$'
        AND CAST(Beds_Occupied AS UNSIGNED) > CAST(Total_Beds_Available AS UNSIGNED)
    ) AS bed_occupancy_over_capacity,
    SUM(
        ICU_Beds_Occupied REGEXP '^[0-9]+$'
        AND ICU_Beds_Available REGEXP '^[0-9]+$'
        AND CAST(ICU_Beds_Occupied AS UNSIGNED) > CAST(ICU_Beds_Available AS UNSIGNED)
    ) AS icu_occupancy_over_capacity
FROM hospital_operations_raw;
SELECT 
    COUNT(*) AS Duplicate_Patient_IDs
FROM
    (SELECT 
        Patient_ID
    FROM
        hospital_operations_raw
    GROUP BY Patient_ID
    HAVING COUNT(*) > 1) AS duplicated_patients;



