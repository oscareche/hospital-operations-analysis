-- =====================================================
-- HOSPITAL OPERATIONS ANALYSIS
-- 03 - DATA CLEANING
-- =====================================================

-- Builds hospital_operations_clean from hospital_operations_raw.
-- The raw table is not modified. Each rule below responds to an issue
-- profiled in 02_raw_data_profiling.sql and logged in data_quality_log.md.
--
-- Rules:
--   1. Remove exact duplicate rows (DQ-002). Repeated Patient_IDs that are
--      not exact duplicates would be kept as separate visits.
--   2. Trim whitespace and map category labels to one spelling (DQ-007).
--   3. Convert the three Visit_Date formats to DATE (DQ-008).
--   4. Derive month, day of week and season from Visit_Date (DQ-009).
--   5. Convert blank text to NULL and numeric text to integers (DQ-006).
--   6. Keep unusual values but flag them so analysis can include or
--      exclude them deliberately (DQ-003, DQ-004, DQ-005, DQ-010, DQ-011).

USE hospital_operations;

DROP TABLE IF EXISTS hospital_operations_clean;

CREATE TABLE hospital_operations_clean AS
WITH deduplicated AS (
    SELECT
        raw.*,
        ROW_NUMBER() OVER (
            PARTITION BY
                Patient_ID, Visit_Date, Age, Gender, Disease, Severity,
                Admission_Type, Length_of_Stay, Bed_Required, ICU_Required,
                Oxygen_Required, Ventilator_Required, Total_Beds_Available,
                Beds_Occupied, ICU_Beds_Available, ICU_Beds_Occupied,
                Oxygen_Units_Used, Month, Season, Day_of_Week, Department,
                Readmission_Within_30_Days
        ) AS duplicate_rank
    FROM hospital_operations_raw AS raw
),
typed AS (
    SELECT
        TRIM(Patient_ID) AS patient_id,

        CASE
            WHEN TRIM(Visit_Date) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
                THEN STR_TO_DATE(TRIM(Visit_Date), '%Y-%m-%d')
            WHEN TRIM(Visit_Date) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
                THEN STR_TO_DATE(TRIM(Visit_Date), '%d-%m-%Y')
            WHEN TRIM(Visit_Date) REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
                THEN STR_TO_DATE(TRIM(Visit_Date), '%Y/%m/%d')
        END AS visit_date,

        CAST(TRIM(Age) AS UNSIGNED) AS age,

        CASE UPPER(TRIM(Gender))
            WHEN 'FEMALE' THEN 'Female'
            WHEN 'MALE' THEN 'Male'
            WHEN 'OTHER' THEN 'Other'
        END AS gender,

        TRIM(Disease) AS disease,

        CASE UPPER(TRIM(Severity))
            WHEN 'MILD' THEN 'Mild'
            WHEN 'MODERATE' THEN 'Moderate'
            WHEN 'SEVERE' THEN 'Severe'
            WHEN 'CRITICAL' THEN 'Critical'
        END AS severity,

        CASE UPPER(TRIM(Admission_Type))
            WHEN 'OPD' THEN 'OPD'
            WHEN 'INPATIENT' THEN 'Inpatient'
            WHEN 'EMERGENCY' THEN 'Emergency'
        END AS admission_type,

        CAST(NULLIF(TRIM(Length_of_Stay), '') AS UNSIGNED) AS length_of_stay,

        UPPER(TRIM(Bed_Required)) = 'YES' AS bed_required,
        UPPER(TRIM(ICU_Required)) = 'YES' AS icu_required,
        UPPER(TRIM(Oxygen_Required)) = 'YES' AS oxygen_required,
        UPPER(TRIM(Ventilator_Required)) = 'YES' AS ventilator_required,

        CAST(TRIM(Total_Beds_Available) AS UNSIGNED) AS total_beds_available,
        CAST(TRIM(Beds_Occupied) AS UNSIGNED) AS beds_occupied,
        CAST(TRIM(ICU_Beds_Available) AS UNSIGNED) AS icu_beds_available,
        CAST(TRIM(ICU_Beds_Occupied) AS UNSIGNED) AS icu_beds_occupied,
        CAST(NULLIF(TRIM(Oxygen_Units_Used), '') AS UNSIGNED) AS oxygen_units_used,

        CAST(TRIM(Month) AS UNSIGNED) AS source_month,
        TRIM(Season) AS source_season,

        CASE UPPER(TRIM(Department))
            WHEN 'CARDIOLOGY' THEN 'Cardiology'
            WHEN 'GASTROENTEROLOGY' THEN 'Gastroenterology'
            WHEN 'GENERAL MEDICINE' THEN 'General Medicine'
            WHEN 'ICU' THEN 'ICU'
            WHEN 'NEPHROLOGY' THEN 'Nephrology'
            WHEN 'NEUROLOGY' THEN 'Neurology'
            WHEN 'ORTHOPEDICS' THEN 'Orthopedics'
            WHEN 'PULMONOLOGY' THEN 'Pulmonology'
        END AS department,

        UPPER(TRIM(Readmission_Within_30_Days)) = 'YES' AS readmitted_within_30_days
    FROM deduplicated
    WHERE duplicate_rank = 1
)
SELECT
    ROW_NUMBER() OVER (ORDER BY visit_date, patient_id) AS visit_id,
    patient_id,
    visit_date,
    YEAR(visit_date) AS visit_year,
    MONTH(visit_date) AS visit_month,
    DAYNAME(visit_date) AS visit_day_of_week,

    -- Season follows the dominant month-to-season pattern in the source data.
    CASE
        WHEN MONTH(visit_date) IN (12, 1, 2) THEN 'Winter'
        WHEN MONTH(visit_date) IN (3, 4) THEN 'Spring'
        WHEN MONTH(visit_date) IN (5, 6) THEN 'Summer'
        WHEN MONTH(visit_date) IN (7, 8, 9) THEN 'Monsoon'
        WHEN MONTH(visit_date) IN (10, 11) THEN 'Autumn'
    END AS visit_season,

    age,
    gender,
    disease,
    severity,
    admission_type,
    department,
    length_of_stay,
    bed_required,
    icu_required,
    oxygen_required,
    ventilator_required,
    total_beds_available,
    beds_occupied,
    ROUND(beds_occupied / total_beds_available * 100, 2) AS bed_occupancy_pct,
    icu_beds_available,
    icu_beds_occupied,
    ROUND(icu_beds_occupied / icu_beds_available * 100, 2) AS icu_occupancy_pct,
    oxygen_units_used,
    readmitted_within_30_days,

    -- Review flags. Records are retained; analysis decides how to treat them.
    (age = 0 OR age > 105) AS flag_age_review,
    COALESCE(admission_type = 'OPD' AND length_of_stay > 0, 0) AS flag_opd_with_stay,
    COALESCE(length_of_stay >= 60, 0) AS flag_long_stay,
    COALESCE(oxygen_units_used >= 500, 0) AS flag_oxygen_units_extreme,
    (icu_required AND NOT bed_required) AS flag_icu_without_bed,
    (ventilator_required AND NOT oxygen_required) AS flag_ventilator_without_oxygen,
    (source_month <> MONTH(visit_date)) AS flag_source_month_mismatch
FROM typed;

-- Confirm the cleaned row count: 5,075 raw rows less 75 exact duplicates.

SELECT COUNT(*) AS clean_row_count
FROM hospital_operations_clean;
