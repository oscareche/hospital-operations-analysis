-- =====================================================
-- HOSPITAL OPERATIONS ANALYSIS
-- 02 - RAW DATA PROFILING
-- =====================================================
-- Every query in this script only reads the raw table. Nothing is changed.
-- Expected values were confirmed against hospital_operations_raw on 29 Oct 2026,
-- except the visit date range in section 5, confirmed on 30 Oct 2026.

USE hospital_operations;


-- =====================================================
-- 1. ROW COUNT
-- =====================================================

-- Total rows in the raw table.
-- Expected: 5,075.

SELECT
    COUNT(*) AS raw_rows
FROM hospital_operations_raw;


-- =====================================================
-- 2. REPEATED IDS AND DUPLICATE ROWS
-- =====================================================

-- Count Patient_IDs that appear more than once.
-- TRIM removes stray spaces and blank IDs are excluded.
-- Repeated IDs are not assumed to be duplicate visits at this stage.
-- Expected: 75.

SELECT
    COUNT(*) AS repeated_patient_id_values
FROM (
    SELECT
        TRIM(Patient_ID) AS patient_id
    FROM hospital_operations_raw
    WHERE Patient_ID IS NOT NULL
        AND TRIM(Patient_ID) <> ''
    GROUP BY TRIM(Patient_ID)
    HAVING COUNT(*) > 1
) AS repeated_ids;


-- Compare total rows with distinct non-blank Patient_IDs.
-- The gap between the two is the number of extra rows created by repeated IDs.
-- DATABASE() confirms which database the connection is pointing at.
-- Expected: hospital_operations, 5,075 rows, 5,000 distinct IDs.

SELECT
    DATABASE() AS active_schema,
    COUNT(*) AS raw_rows,
    COUNT(DISTINCT NULLIF(TRIM(Patient_ID), '')) AS distinct_nonblank_patient_ids
FROM hospital_operations_raw;


-- List the most repeated Patient_IDs and how many rows each one has.
-- If every repeated ID appears exactly twice, the top 10 will all show row_count = 2.
-- Expected: row_count = 2 for every ID listed.

SELECT
    TRIM(Patient_ID) AS patient_id,
    COUNT(*) AS row_count
FROM hospital_operations_raw
WHERE Patient_ID IS NOT NULL
    AND TRIM(Patient_ID) <> ''
GROUP BY TRIM(Patient_ID)
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 10;


-- Show both rows for one repeated Patient_ID so they can be compared side by side.
-- P01403 is one example from the list above. The full check across all
-- repeated IDs is the 22-column block below.
-- Expected: two rows that match in every column.

SELECT
    *
FROM hospital_operations_raw
WHERE TRIM(Patient_ID) = 'P01403';


-- Count groups of rows that are identical across all 22 columns.
-- excess_exact_duplicate_rows is how many rows would be removed to keep one copy of each.
-- MySQL's default text comparison ignores upper and lower case, so rows that differ
-- only in case would be counted as identical here.
-- Expected: 75 groups and 75 excess rows.

SELECT
    COUNT(*) AS exact_duplicate_groups,
    COALESCE(SUM(occurrences - 1), 0) AS excess_exact_duplicate_rows
FROM (
    SELECT
        COUNT(*) AS occurrences
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


-- =====================================================
-- 3. MISSING VALUES
-- =====================================================

-- Count missing values in every column. A value counts as missing if it is NULL
-- or contains only spaces. Each condition returns 1 if true and 0 if false,
-- so SUM adds up the number of rows that meet it.
-- Expected: Gender 103, Department 77, Length_of_Stay 50, Oxygen_Units_Used 100, all others 0.

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


-- =====================================================
-- 4. CATEGORY LABELS
-- =====================================================

-- List every distinct value in each category column with its row count.
-- UNION ALL stacks the separate results into one table, tagged by field name.
-- GROUP BY here uses MySQL's case-insensitive comparison, so case variants are
-- merged into one row. The case-sensitive check below finds those.
-- Expected: stray-space variants in Gender, Severity, Admission_Type, Day_of_Week,
-- Department and Readmission_Within_30_Days (45 rows). Disease and Season are consistent.

SELECT
    'Gender' AS field_name,
    Gender AS raw_value,
    COUNT(*) AS row_count
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


-- Re-check the six messy fields with a case-sensitive comparison.
-- TRIM removes the stray spaces already found, so any extra rows that appear
-- are true case variants (e.g. MALE vs Male). The default comparison hides these.
-- Expected: 32 rows with odd casing across the six fields, e.g. MALE, female, icu.

SELECT
    'Gender' AS field_name,
    TRIM(Gender) COLLATE utf8mb4_bin AS cleaned_value,
    COUNT(*) AS row_count
FROM hospital_operations_raw
GROUP BY TRIM(Gender) COLLATE utf8mb4_bin

UNION ALL

SELECT 'Severity', TRIM(Severity) COLLATE utf8mb4_bin, COUNT(*)
FROM hospital_operations_raw
GROUP BY TRIM(Severity) COLLATE utf8mb4_bin

UNION ALL

SELECT 'Admission_Type', TRIM(Admission_Type) COLLATE utf8mb4_bin, COUNT(*)
FROM hospital_operations_raw
GROUP BY TRIM(Admission_Type) COLLATE utf8mb4_bin

UNION ALL

SELECT 'Day_of_Week', TRIM(Day_of_Week) COLLATE utf8mb4_bin, COUNT(*)
FROM hospital_operations_raw
GROUP BY TRIM(Day_of_Week) COLLATE utf8mb4_bin

UNION ALL

SELECT 'Department', TRIM(Department) COLLATE utf8mb4_bin, COUNT(*)
FROM hospital_operations_raw
GROUP BY TRIM(Department) COLLATE utf8mb4_bin

UNION ALL

SELECT 'Readmission_Within_30_Days', TRIM(Readmission_Within_30_Days) COLLATE utf8mb4_bin, COUNT(*)
FROM hospital_operations_raw
GROUP BY TRIM(Readmission_Within_30_Days) COLLATE utf8mb4_bin

ORDER BY field_name, cleaned_value;


-- Check the remaining category fields for hidden case variants.
-- default_distinct uses MySQL's case-insensitive comparison; case_sensitive_distinct
-- uses an exact one. If the two numbers match for a field, it has no case variants.
-- Expected: Disease 20, Season 5, and 2 for each yes/no field, equal in both columns.

SELECT
    'Disease' AS field_name,
    COUNT(DISTINCT TRIM(Disease)) AS default_distinct,
    COUNT(DISTINCT TRIM(Disease) COLLATE utf8mb4_bin) AS case_sensitive_distinct
FROM hospital_operations_raw

UNION ALL

SELECT
    'Season',
    COUNT(DISTINCT TRIM(Season)),
    COUNT(DISTINCT TRIM(Season) COLLATE utf8mb4_bin)
FROM hospital_operations_raw

UNION ALL

SELECT
    'Bed_Required',
    COUNT(DISTINCT TRIM(Bed_Required)),
    COUNT(DISTINCT TRIM(Bed_Required) COLLATE utf8mb4_bin)
FROM hospital_operations_raw

UNION ALL

SELECT
    'ICU_Required',
    COUNT(DISTINCT TRIM(ICU_Required)),
    COUNT(DISTINCT TRIM(ICU_Required) COLLATE utf8mb4_bin)
FROM hospital_operations_raw

UNION ALL

SELECT
    'Oxygen_Required',
    COUNT(DISTINCT TRIM(Oxygen_Required)),
    COUNT(DISTINCT TRIM(Oxygen_Required) COLLATE utf8mb4_bin)
FROM hospital_operations_raw

UNION ALL

SELECT
    'Ventilator_Required',
    COUNT(DISTINCT TRIM(Ventilator_Required)),
    COUNT(DISTINCT TRIM(Ventilator_Required) COLLATE utf8mb4_bin)
FROM hospital_operations_raw;


-- =====================================================
-- 5. DATES
-- =====================================================

-- Sort each Visit_Date into a format bucket and count the rows in each.
-- CASE WHEN checks the patterns in order and labels the row with the first one that fits.
-- REGEXP tests the text against a pattern: [0-9]{4} means exactly four digits,
-- ^ and $ mean the whole value must match, not just part of it.
-- Anything that fits none of the three patterns lands in 'Other or missing'.
-- Expected: 5,001 YYYY-MM-DD, 49 DD-MM-YYYY and 25 YYYY/MM/DD (5,075 in total).

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


-- Convert each Visit_Date to a real DATE, then compare it with the supplied Month and Day_of_Week.
-- WITH ... AS builds a named temporary result (a CTE) that the final SELECT then reads from.
-- STR_TO_DATE turns text into a date using the format code for that pattern;
-- it returns NULL if the date doesn't exist (e.g. 31-02-2024).
-- Each SUM counts the rows meeting its condition (true = 1, false = 0).
-- Expected: unparsed_visit_dates 0, month_mismatches 13, day_of_week_mismatches 0.

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


-- Compare the supplied Season with the month taken from Visit_Date.
-- The CTE converts each date as in the block above.
-- Sorting by month makes it easy to spot a month listed under two seasons.
-- Expected: 12 rows, one season per month, so Season always agrees with the date
-- and the 13 month mismatches above are errors in the Month column.

WITH parsed_dates AS (
    SELECT
        Season,
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
    MONTH(parsed_visit_date) AS visit_month,
    TRIM(Season) AS season,
    COUNT(*) AS row_count
FROM parsed_dates
GROUP BY MONTH(parsed_visit_date), TRIM(Season)
ORDER BY visit_month, season;


-- Find the earliest and latest visit dates across all three date formats.
-- The CTE converts each date as in the blocks above, then MIN and MAX pick
-- the first and last. This confirms the period the analysis covers, which
-- question 2 (monthly and seasonal patterns) depends on.
-- Expected: first_visit 2023-01-01, last_visit 2024-12-31.

WITH parsed_dates AS (
    SELECT
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
    MIN(parsed_visit_date) AS first_visit,
    MAX(parsed_visit_date) AS last_visit
FROM parsed_dates;


-- =====================================================
-- 6. NUMERIC FIELDS
-- =====================================================

-- Profile each numeric column for blanks, non-numeric text and the range of values.
-- The inner query stacks the eight columns into one list (field_name, raw_value)
-- with UNION ALL, so the outer query can profile them all in one pass.
-- REGEXP '^-?[0-9]+$' tests for a whole number (optional minus sign, then digits only).
-- CASE WHEN ... THEN CAST(... AS SIGNED) converts to a number only when the text is a
-- valid whole number, so MIN and MAX ignore anything else.
-- Each SUM counts the rows meeting its condition (true = 1, false = 0).
-- Expected: no non-integer or negative values in any column; blanks in Length_of_Stay (50)
-- and Oxygen_Units_Used (100); Age 0 to 120; Length_of_Stay up to 120;
-- Oxygen_Units_Used up to 999; Month 1 to 12 with no blanks.

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
    UNION ALL
    SELECT 'Length_of_Stay', TRIM(Length_of_Stay) FROM hospital_operations_raw
    UNION ALL
    SELECT 'Total_Beds_Available', TRIM(Total_Beds_Available) FROM hospital_operations_raw
    UNION ALL
    SELECT 'Beds_Occupied', TRIM(Beds_Occupied) FROM hospital_operations_raw
    UNION ALL
    SELECT 'ICU_Beds_Available', TRIM(ICU_Beds_Available) FROM hospital_operations_raw
    UNION ALL
    SELECT 'ICU_Beds_Occupied', TRIM(ICU_Beds_Occupied) FROM hospital_operations_raw
    UNION ALL
    SELECT 'Oxygen_Units_Used', TRIM(Oxygen_Units_Used) FROM hospital_operations_raw
    UNION ALL
    SELECT 'Month', TRIM(Month) FROM hospital_operations_raw
) AS numeric_fields
GROUP BY field_name
ORDER BY field_name;


-- =====================================================
-- 7. CONTRADICTIONS BETWEEN COLUMNS
-- =====================================================

-- Look for rows where related columns contradict each other.
-- icu_yes_bed_no: ICU needed but no bed needed (an ICU stay should include a bed).
-- ventilator_yes_oxygen_no: ventilator needed but no oxygen needed.
-- bed_occupancy_over_capacity: more beds occupied than beds available.
-- icu_occupancy_over_capacity: more ICU beds occupied than ICU beds available.
-- UPPER(TRIM(...)) makes the Yes/No test ignore stray spaces and case.
-- REGEXP '^[0-9]+$' makes sure the text is a whole number before it is converted and compared.
-- Each SUM counts the rows meeting its condition (true = 1, false = 0).
-- Expected: icu_yes_bed_no 94, ventilator_yes_oxygen_no 62, and 0 for both capacity checks.

SELECT
    SUM(
        UPPER(TRIM(ICU_Required)) = 'YES'
        AND UPPER(TRIM(Bed_Required)) = 'NO'
    ) AS icu_yes_bed_no,
    SUM(
        UPPER(TRIM(Ventilator_Required)) = 'YES'
        AND UPPER(TRIM(Oxygen_Required)) = 'NO'
    ) AS ventilator_yes_oxygen_no,
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


-- =====================================================
-- 8. UNUSUAL VALUES
-- =====================================================

-- List the ages at the extremes of the range: zero, or over 100.
-- CAST(... AS SIGNED) turns the text age into a number. Grouping and sorting
-- on that same number keeps MySQL's only_full_group_by mode happy.
-- Expected: 2 at age 0, 1 at age 110, 5 at age 120. None are among the 75 copies.

SELECT
    CAST(TRIM(Age) AS SIGNED) AS age,
    COUNT(*) AS row_count
FROM hospital_operations_raw
WHERE CAST(TRIM(Age) AS SIGNED) = 0
    OR CAST(TRIM(Age) AS SIGNED) > 100
GROUP BY CAST(TRIM(Age) AS SIGNED)
ORDER BY CAST(TRIM(Age) AS SIGNED);


-- Compare length of stay with admission type.
-- OPD (outpatient) visits are expected to be same-day, so a stay above 0 is suspect.
-- UPPER(TRIM(...)) merges the spacing and case variants into one label.
-- REGEXP '^[0-9]+$' skips blank stays before converting the text to a number.
-- Each SUM counts the rows meeting its condition (true = 1, false = 0).
-- Expected: all zero-day stays are OPD; 52 OPD visits with a stay above 0;
-- 6 stays of 60 days or more in total (2 per admission type).

SELECT
    UPPER(TRIM(Admission_Type)) AS admission_type,
    SUM(TRIM(Length_of_Stay) = '0') AS zero_day_stays,
    SUM(
        TRIM(Length_of_Stay) REGEXP '^[0-9]+$'
        AND CAST(TRIM(Length_of_Stay) AS UNSIGNED) > 0
    ) AS stays_over_zero_days,
    SUM(
        TRIM(Length_of_Stay) REGEXP '^[0-9]+$'
        AND CAST(TRIM(Length_of_Stay) AS UNSIGNED) >= 60
    ) AS stays_60_days_or_more
FROM hospital_operations_raw
GROUP BY UPPER(TRIM(Admission_Type))
ORDER BY admission_type;


-- Check whether Oxygen_Units_Used behaves like a per-visit measure.
-- If it were per visit, visits that did not need oxygen should record 0 units.
-- Blank units are excluded so CAST only sees numbers.
-- Expected: NO 3,450 rows recorded, 2,877 above zero; YES 1,525 recorded, 1,525 above zero.
-- Most no-oxygen visits record units, so the column looks like a hospital-level figure.

SELECT
    UPPER(TRIM(Oxygen_Required)) AS oxygen_required,
    COUNT(*) AS rows_with_units_recorded,
    SUM(CAST(TRIM(Oxygen_Units_Used) AS UNSIGNED) > 0) AS rows_with_units_above_zero
FROM hospital_operations_raw
WHERE TRIM(Oxygen_Units_Used) <> ''
GROUP BY UPPER(TRIM(Oxygen_Required));


-- List unusually high Oxygen_Units_Used values (400 or more) with their counts.
-- Grouping and sorting on the same converted number avoids the only_full_group_by error.
-- Expected: 2 each at 500, 800 and 999 (6 in total). Every other value is below 400.

SELECT
    CAST(TRIM(Oxygen_Units_Used) AS UNSIGNED) AS oxygen_units_used,
    COUNT(*) AS row_count
FROM hospital_operations_raw
WHERE TRIM(Oxygen_Units_Used) REGEXP '^[0-9]+$'
    AND CAST(TRIM(Oxygen_Units_Used) AS UNSIGNED) >= 400
GROUP BY CAST(TRIM(Oxygen_Units_Used) AS UNSIGNED)
ORDER BY CAST(TRIM(Oxygen_Units_Used) AS UNSIGNED);


-- =====================================================
-- 9. EVIDENCE FOR CLEANING DECISIONS
-- =====================================================

-- Compare average length of stay with and without stays of 60 days or more.
-- SELECT DISTINCT * in the subquery removes the 75 exact copies first.
-- UPPER(TRIM(...)) merges the spacing and case variants of each admission type.
-- NULLIF turns blank stays into NULL, so COUNT and AVG skip them.
-- The CASE WHEN returns NULL for stays of 60+ days, so AVG skips those too.
-- Expected: Emergency 9.26 vs 9.14, Inpatient 6.47 vs 6.39, OPD 0.17 vs 0.06 (4,950 stays).
-- Excluding 60+ day stays changes admitted averages by about 0.1 day, and the
-- "under 60 days" figures match the README. Decision: flag long stays, keep them
-- in the clean table, and exclude them and OPD from length-of-stay averages.

SELECT
    UPPER(TRIM(Admission_Type)) AS admission_type,
    COUNT(NULLIF(TRIM(Length_of_Stay), '')) AS stays_recorded,
    ROUND(AVG(CAST(NULLIF(TRIM(Length_of_Stay), '') AS UNSIGNED)), 2) AS avg_stay_all,
    ROUND(
        AVG(
            CASE
                WHEN CAST(NULLIF(TRIM(Length_of_Stay), '') AS UNSIGNED) < 60
                    THEN CAST(NULLIF(TRIM(Length_of_Stay), '') AS UNSIGNED)
            END
        ),
        2
    ) AS avg_stay_under_60_days
FROM (
    SELECT DISTINCT
        *
    FROM hospital_operations_raw
) AS unique_rows
GROUP BY UPPER(TRIM(Admission_Type))
ORDER BY admission_type;