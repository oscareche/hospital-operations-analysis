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
    ROUND(AVG(CASE WHEN admission_type <> 'OPD' THEN length_of_stay END), 2) AS avg_stay_days_admitted,
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
    COUNT(length_of_stay) AS visits_with_stay,
    ROUND(AVG(length_of_stay), 2) AS avg_stay_days,
    MIN(length_of_stay) AS min_stay_days,
    MAX(length_of_stay) AS max_stay_days
FROM hospital_operations_clean
WHERE flag_long_stay = 0
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
-- Occupancy fields look like hospital-level snapshots
-- repeated on each visit row, so results describe the
-- recorded snapshots, not each patient's experience.
-- 85% is used as a common planning threshold.
-- -----------------------------------------------------

SELECT
    ROUND(AVG(bed_occupancy_pct), 2) AS avg_bed_occupancy_pct,
    MAX(bed_occupancy_pct) AS max_bed_occupancy_pct,
    ROUND(100.0 * SUM(bed_occupancy_pct >= 85) / COUNT(*), 2) AS bed_snapshots_85_plus_pct,
    ROUND(AVG(icu_occupancy_pct), 2) AS avg_icu_occupancy_pct,
    MAX(icu_occupancy_pct) AS max_icu_occupancy_pct,
    ROUND(100.0 * SUM(icu_occupancy_pct >= 85) / COUNT(*), 2) AS icu_snapshots_85_plus_pct
FROM hospital_operations_clean;

SELECT
    visit_season,
    ROUND(AVG(bed_occupancy_pct), 2) AS avg_bed_occupancy_pct,
    ROUND(AVG(icu_occupancy_pct), 2) AS avg_icu_occupancy_pct
FROM hospital_operations_clean
GROUP BY visit_season
ORDER BY avg_bed_occupancy_pct DESC;

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
