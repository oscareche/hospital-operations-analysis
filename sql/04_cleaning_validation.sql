-- =====================================================
-- HOSPITAL OPERATIONS ANALYSIS
-- 04 - CLEANING VALIDATION
-- =====================================================

-- Checks hospital_operations_clean before analysis. This script reads only.
-- Expected results (verified 23 Oct 2026) are noted under each check.

USE hospital_operations;

-- 1. Row count and visit grain.
-- Expected: 5,000 rows, 5,000 distinct patient IDs, 0 missing dates.

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
-- Expected: one row per valid label; NULL only for gender (100) and department (75).

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
-- Expected: age 8, OPD with stay 52, long stay 6, extreme oxygen units 6,
-- ICU without bed 93, ventilator without oxygen 61, source month mismatch 13.

SELECT
    SUM(flag_age_review) AS age_review,
    SUM(flag_opd_with_stay) AS opd_with_stay,
    SUM(flag_long_stay) AS long_stay,
    SUM(flag_oxygen_units_extreme) AS oxygen_units_extreme,
    SUM(flag_icu_without_bed) AS icu_without_bed,
    SUM(flag_ventilator_without_oxygen) AS ventilator_without_oxygen,
    SUM(flag_source_month_mismatch) AS source_month_mismatch
FROM hospital_operations_clean;

-- 7. Derived season agrees with the source Season label.
-- Expected: 0. The 13 source Month mismatches are errors in the Month field,
-- because Season agrees with Visit_Date in every row.

SELECT COUNT(*) AS season_disagreements
FROM hospital_operations_clean AS clean
JOIN (
    SELECT DISTINCT TRIM(Patient_ID) AS patient_id, TRIM(Season) AS source_season
    FROM hospital_operations_raw
) AS raw
    ON raw.patient_id = clean.patient_id
WHERE raw.source_season <> clean.visit_season;
