-- =====================================================
-- HOSPITAL OPERATIONS ANALYSIS
-- 05 - EXPLORATORY ANALYSIS
-- =====================================================

-- Answers the six business questions in documentation/project_brief.md.
-- Grain: one row per hospital visit. Rates are percentages of visits.
-- Rows with a NULL grouping value are shown as 'Unknown' rather than dropped.

USE hospital_operations;

-- -----------------------------------------------------
-- Headline KPIs
-- -----------------------------------------------------

SELECT
    COUNT(*) AS visits,
    MIN(visit_date) AS first_visit,
    MAX(visit_date) AS last_visit,
    ROUND(AVG(CASE
                  WHEN admission_type IN ('Inpatient', 'Emergency')
                       AND flag_long_stay = 0
                  THEN length_of_stay
              END), 2) AS avg_stay_days_admitted_excl_long,
    ROUND(100.0 * SUM(bed_required) / COUNT(*), 2) AS bed_required_pct,
    ROUND(100.0 * SUM(icu_required) / COUNT(*), 2) AS icu_required_pct,
    ROUND(100.0 * SUM(oxygen_required) / COUNT(*), 2) AS oxygen_required_pct,
    ROUND(100.0 * SUM(ventilator_required) / COUNT(*), 2) AS ventilator_required_pct,
    ROUND(AVG(bed_occupancy_pct), 2) AS avg_bed_occupancy_pct,
    ROUND(AVG(icu_occupancy_pct), 2) AS avg_icu_occupancy_pct,
    ROUND(100.0 * SUM(readmitted_within_30_days) / COUNT(*), 2) AS readmission_pct
FROM hospital_operations_clean;

-- -----------------------------------------------------
-- Q1. Which departments, diseases and admission types
--     account for the highest visit volumes?
-- -----------------------------------------------------

SELECT
    COALESCE(department, 'Unknown') AS department,
    COUNT(*) AS visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_visits_pct
FROM hospital_operations_clean
GROUP BY department
ORDER BY visits DESC;

SELECT
    disease,
    COUNT(*) AS visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_visits_pct
FROM hospital_operations_clean
GROUP BY disease
ORDER BY visits DESC;

SELECT
    admission_type,
    COUNT(*) AS visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_visits_pct
FROM hospital_operations_clean
GROUP BY admission_type
ORDER BY visits DESC;

-- -----------------------------------------------------
-- Q2. How does visit volume vary by month, day of week
--     and season?
-- -----------------------------------------------------

SELECT visit_year, visit_month, COUNT(*) AS visits
FROM hospital_operations_clean
GROUP BY visit_year, visit_month
ORDER BY visit_year, visit_month;

-- Average visits per calendar month across both years, to separate
-- seasonality from one-off spikes.

SELECT visit_month, COUNT(*) AS visits, ROUND(COUNT(*) / 2.0, 1) AS avg_visits_per_year
FROM hospital_operations_clean
GROUP BY visit_month
ORDER BY visit_month;

SELECT
    visit_season,
    COUNT(*) AS visits,
    COUNT(DISTINCT visit_month) AS months_in_season,
    ROUND(COUNT(*) / (2.0 * COUNT(DISTINCT visit_month)), 1) AS avg_visits_per_month
FROM hospital_operations_clean
GROUP BY visit_season
ORDER BY avg_visits_per_month DESC;

SELECT visit_day_of_week, COUNT(*) AS visits
FROM hospital_operations_clean
GROUP BY visit_day_of_week
ORDER BY visits DESC;

-- -----------------------------------------------------
-- Q3. How does length of stay vary by admission type,
--     severity and department?
-- OPD visits are same-day by design, so stay analysis
-- uses Inpatient and Emergency visits. Stays of 60+ days
-- are flagged and excluded from averages.
-- -----------------------------------------------------

SELECT
    admission_type,
    COUNT(length_of_stay) AS admitted_visits_with_stay,
    ROUND(AVG(length_of_stay), 2) AS avg_stay_days,
    MIN(length_of_stay) AS min_stay_days,
    MAX(length_of_stay) AS max_stay_days
FROM hospital_operations_clean
WHERE admission_type IN ('Inpatient', 'Emergency')
  AND flag_long_stay = 0
GROUP BY admission_type
ORDER BY avg_stay_days DESC;

SELECT
    severity,
    COUNT(length_of_stay) AS admitted_visits_with_stay,
    ROUND(AVG(length_of_stay), 2) AS avg_stay_days
FROM hospital_operations_clean
WHERE admission_type IN ('Inpatient', 'Emergency')
  AND flag_long_stay = 0
GROUP BY severity
ORDER BY avg_stay_days DESC;

SELECT
    COALESCE(department, 'Unknown') AS department,
    COUNT(length_of_stay) AS admitted_visits_with_stay,
    ROUND(AVG(length_of_stay), 2) AS avg_stay_days,
    SUM(length_of_stay) AS total_bed_days
FROM hospital_operations_clean
WHERE admission_type IN ('Inpatient', 'Emergency')
  AND flag_long_stay = 0
GROUP BY department
ORDER BY total_bed_days DESC;

-- -----------------------------------------------------
-- Q4. How do bed, ICU, oxygen and ventilator requirements
--     vary by severity, department and admission type?
-- -----------------------------------------------------

SELECT
    severity,
    COUNT(*) AS visits,
    ROUND(100.0 * SUM(bed_required) / COUNT(*), 2) AS bed_pct,
    ROUND(100.0 * SUM(icu_required) / COUNT(*), 2) AS icu_pct,
    ROUND(100.0 * SUM(oxygen_required) / COUNT(*), 2) AS oxygen_pct,
    ROUND(100.0 * SUM(ventilator_required) / COUNT(*), 2) AS ventilator_pct
FROM hospital_operations_clean
GROUP BY severity
ORDER BY icu_pct DESC;

SELECT
    COALESCE(department, 'Unknown') AS department,
    COUNT(*) AS visits,
    SUM(icu_required) AS icu_visits,
    ROUND(100.0 * SUM(icu_required) / COUNT(*), 2) AS icu_pct,
    SUM(ventilator_required) AS ventilator_visits,
    ROUND(100.0 * SUM(ventilator_required) / COUNT(*), 2) AS ventilator_pct,
    ROUND(100.0 * SUM(oxygen_required) / COUNT(*), 2) AS oxygen_pct
FROM hospital_operations_clean
GROUP BY department
ORDER BY icu_visits DESC;

SELECT
    admission_type,
    COUNT(*) AS visits,
    ROUND(100.0 * SUM(bed_required) / COUNT(*), 2) AS bed_pct,
    ROUND(100.0 * SUM(icu_required) / COUNT(*), 2) AS icu_pct,
    ROUND(100.0 * SUM(oxygen_required) / COUNT(*), 2) AS oxygen_pct,
    ROUND(100.0 * SUM(ventilator_required) / COUNT(*), 2) AS ventilator_pct
FROM hospital_operations_clean
GROUP BY admission_type
ORDER BY icu_pct DESC;

-- -----------------------------------------------------
-- Q5. What do recorded bed and ICU occupancy suggest
--     about capacity pressure?
--
-- Answered as a negative finding. The occupancy and
-- capacity fields are recorded independently on every
-- visit row rather than once per hospital day, so no
-- value describes the hospital on a given date and the
-- fields cannot measure capacity pressure. The evidence
-- is in the extras section at the end of this script and
-- is recorded as DQ-012.
--
-- The query below reports what was recorded, for
-- completeness only. It is not evidence of pressure, any
-- seasonal difference in occupancy is noise, and these
-- fields are excluded from the dashboard.
-- Expected: 5,000 visit records, average bed occupancy
-- 66.24 and average ICU occupancy 52.24.
-- -----------------------------------------------------

SELECT
    COUNT(*) AS visit_records,
    ROUND(AVG(bed_occupancy_pct), 2) AS avg_bed_occupancy_pct,
    MAX(bed_occupancy_pct) AS max_bed_occupancy_pct,
    ROUND(AVG(icu_occupancy_pct), 2) AS avg_icu_occupancy_pct,
    MAX(icu_occupancy_pct) AS max_icu_occupancy_pct
FROM hospital_operations_clean;

-- -----------------------------------------------------
-- Q6. What patterns appear in 30-day readmissions?
-- -----------------------------------------------------

SELECT
    severity,
    COUNT(*) AS visits,
    SUM(readmitted_within_30_days) AS readmissions,
    ROUND(100.0 * SUM(readmitted_within_30_days) / COUNT(*), 2) AS readmission_pct
FROM hospital_operations_clean
GROUP BY severity
ORDER BY readmission_pct DESC;

SELECT
    disease,
    COUNT(*) AS visits,
    SUM(readmitted_within_30_days) AS readmissions,
    ROUND(100.0 * SUM(readmitted_within_30_days) / COUNT(*), 2) AS readmission_pct
FROM hospital_operations_clean
GROUP BY disease
ORDER BY readmission_pct DESC;

SELECT
    COALESCE(department, 'Unknown') AS department,
    COUNT(*) AS visits,
    SUM(readmitted_within_30_days) AS readmissions,
    ROUND(100.0 * SUM(readmitted_within_30_days) / COUNT(*), 2) AS readmission_pct
FROM hospital_operations_clean
GROUP BY department
ORDER BY readmission_pct DESC;

-- =====================================================
-- EXTRAS. Evidence behind the Q5 negative finding
-- =====================================================
-- These three checks are not part of the six business
-- questions. They establish that the capacity, occupancy
-- and oxygen-unit fields are recorded per visit row
-- rather than per hospital day. Evidence for DQ-012.
-- -----------------------------------------------------


-- Checks for zero or missing bed capacity. A zero denominator would make the
-- occupancy percentage NULL without raising an error, which would quietly drop
-- rows from the averages above.
-- Expected: 0 in every column.
SELECT
    SUM(total_beds_available = 0) AS zero_total_beds,
    SUM(icu_beds_available = 0) AS zero_icu_beds,
    SUM(total_beds_available IS NULL) AS missing_total_beds,
    SUM(icu_beds_available IS NULL) AS missing_icu_beds,
    SUM(bed_occupancy_pct IS NULL) AS null_bed_occupancy,
    SUM(icu_occupancy_pct IS NULL) AS null_icu_occupancy
FROM hospital_operations_clean;


-- Counts how many different occupancy readings each date carries, alongside how
-- many visits that date has. A figure near 1 would mean a genuine daily value;
-- a figure near the visit count means the value is generated per row.
-- Expected: 730 visit dates, 6.85 visits per day, 6.83 distinct bed-occupancy
-- values per day, at most 17 in a single day, 6.49 distinct ICU values, and
-- only 9 dates carrying a single bed-occupancy value.
SELECT
    COUNT(*) AS visit_dates,
    ROUND(AVG(visits), 2) AS avg_visits_per_day,
    ROUND(AVG(bed_values), 2) AS avg_distinct_bed_values_per_day,
    MAX(bed_values) AS max_distinct_bed_values_in_a_day,
    ROUND(AVG(icu_values), 2) AS avg_distinct_icu_values_per_day,
    SUM(bed_values = 1) AS dates_with_a_single_bed_value
FROM (
    SELECT
        visit_date,
        COUNT(*) AS visits,
        COUNT(DISTINCT bed_occupancy_pct) AS bed_values,
        COUNT(DISTINCT icu_occupancy_pct) AS icu_values
    FROM hospital_operations_clean
    GROUP BY visit_date
) AS daily;


-- Repeats the same test on the capacity and oxygen-unit columns, to confirm the
-- pattern is not limited to the derived occupancy percentages. Oxygen units hold
-- 100 NULLs, which COUNT(DISTINCT) skips, so that column reads slightly low.
-- Expected: 730 visit dates, 6.85 visits per day, and per day 6.72 distinct
-- bed-capacity values, 6.24 ICU-capacity values and 5.25 oxygen-unit values.
SELECT
    COUNT(*) AS visit_dates,
    ROUND(AVG(visits), 2) AS avg_visits_per_day,
    ROUND(AVG(total_bed_values), 2) AS avg_distinct_total_beds_per_day,
    ROUND(AVG(icu_bed_values), 2) AS avg_distinct_icu_beds_per_day,
    ROUND(AVG(oxygen_values), 2) AS avg_distinct_oxygen_units_per_day
FROM (
    SELECT
        visit_date,
        COUNT(*) AS visits,
        COUNT(DISTINCT total_beds_available) AS total_bed_values,
        COUNT(DISTINCT icu_beds_available) AS icu_bed_values,
        COUNT(DISTINCT oxygen_units_used) AS oxygen_values
    FROM hospital_operations_clean
    GROUP BY visit_date
) AS daily;
