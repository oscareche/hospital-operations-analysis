-- =====================================================
-- HOSPITAL OPERATIONS ANALYSIS
-- 04 - CLEANING VALIDATION
-- =====================================================

-- Checks hospital_operations_clean before analysis. This script reads only.
-- Expected results are noted under each check. They come from the raw-data
-- profiling re-verified on 29-30 Oct 2026 and recorded in data_quality_log.md.
-- Run 03_data_cleaning.sql first, including its collation step, or check 7
-- will fail with an "illegal mix of collations" error.

USE hospital_operations;

-- 1. Row count and visit grain.
-- Expected: 5,000 rows, 5,000 distinct patient IDs, 0 missing dates,
-- first visit 2023-01-01 and last visit 2024-12-31.

SELECT
    COUNT(*) AS clean_rows,
    COUNT(DISTINCT patient_id) AS distinct_patient_ids,
    SUM(visit_date IS NULL) AS missing_visit_dates,
    MIN(visit_date) AS first_visit_date,
    MAX(visit_date) AS last_visit_date
FROM hospital_operations_clean;

-- 2. Exact duplicates removed.
-- Expected: 0 repeated patient IDs.

SELECT COUNT(*) AS repeated_patient_ids
FROM (
    SELECT patient_id
    FROM hospital_operations_clean
    GROUP BY patient_id
    HAVING COUNT(*) > 1
) AS repeated;

-- 3. Category labels standardised.
-- Expected: one row per valid label, so 3 genders, 4 severities,
-- 3 admission types, 8 departments and 7 weekdays.
-- NULL appears only for gender (100) and department (75).

SELECT 'gender' AS field_name, gender AS value, COUNT(*) AS row_count
FROM hospital_operations_clean GROUP BY gender
UNION ALL
SELECT 'severity', severity, COUNT(*) FROM hospital_operations_clean GROUP BY severity
UNION ALL
SELECT 'admission_type', admission_type, COUNT(*) FROM hospital_operations_clean GROUP BY admission_type
UNION ALL
SELECT 'department', department, COUNT(*) FROM hospital_operations_clean GROUP BY department
UNION ALL
SELECT 'visit_day_of_week', visit_day_of_week, COUNT(*) FROM hospital_operations_clean GROUP BY visit_day_of_week
ORDER BY field_name, value;

-- 4. Remaining missing values.
-- These are the genuine blanks in the source, kept as NULL rather than filled in.
-- Expected: gender 100, department 75, length_of_stay 50, oxygen_units_used 100.

SELECT
    SUM(gender IS NULL) AS missing_gender,
    SUM(department IS NULL) AS missing_department,
    SUM(length_of_stay IS NULL) AS missing_length_of_stay,
    SUM(oxygen_units_used IS NULL) AS missing_oxygen_units_used
FROM hospital_operations_clean;

-- 5. Recorded occupancy within capacity.
-- Expected: 0 and 0.

SELECT
    SUM(beds_occupied > total_beds_available) AS beds_over_capacity,
    SUM(icu_beds_occupied > icu_beds_available) AS icu_beds_over_capacity
FROM hospital_operations_clean;

-- 6. Review flags.
-- Age and oxygen units are kept as recorded with no flag (DQ-003, DQ-011),
-- so only the five agreed flags are checked here.
-- Expected: OPD with stay 52, long stay 6, ICU without bed 93,
-- ventilator without oxygen 61, source month mismatch 13.

SELECT
    SUM(flag_opd_with_stay) AS opd_with_stay,
    SUM(flag_long_stay) AS long_stay,
    SUM(flag_icu_without_bed) AS icu_without_bed,
    SUM(flag_ventilator_without_oxygen) AS ventilator_without_oxygen,
    SUM(flag_source_month_mismatch) AS source_month_mismatch
FROM hospital_operations_clean;

-- 7. Derived season agrees with the source Season label.
-- Joins each clean visit back to its raw rows by patient ID. The 75 duplicate
-- pairs each match twice, which is harmless because both copies carry the same
-- Season, so this reads 5,075 raw rows rather than 5,000.
-- Expected: 0. The 13 source Month mismatches are therefore errors in the
-- Month field, because Season agrees with Visit_Date in every row.

SELECT COUNT(*) AS season_disagreements
FROM hospital_operations_clean AS c
JOIN hospital_operations_raw AS r
    ON TRIM(r.Patient_ID) = c.patient_id
WHERE TRIM(r.Season) <> c.visit_season;

-- 8. Fields that should be complete.
-- Catches a label the cleaning script failed to recognise, which would be
-- stored as NULL rather than reported as an error.
-- Expected: 0 for every column.

SELECT
    SUM(patient_id IS NULL) AS missing_patient_id,
    SUM(age IS NULL) AS missing_age,
    SUM(disease IS NULL) AS missing_disease,
    SUM(severity IS NULL) AS missing_severity,
    SUM(admission_type IS NULL) AS missing_admission_type,
    SUM(visit_season IS NULL) AS missing_visit_season,
    SUM(readmitted_within_30_days IS NULL) AS missing_readmission_flag
FROM hospital_operations_clean;

-- 9. Text columns share one collation.
-- Columns built from text written in 03 otherwise inherit the connection's
-- collation, which differs from the raw table's and breaks any comparison
-- between the two tables.
-- Expected: 1 row, utf8mb4_0900_ai_ci, covering every text column.

SELECT collation_name, COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'hospital_operations'
    AND table_name = 'hospital_operations_clean'
    AND collation_name IS NOT NULL
GROUP BY collation_name
ORDER BY collation_name;