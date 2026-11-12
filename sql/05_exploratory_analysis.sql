-- =====================================================
-- HOSPITAL OPERATIONS ANALYSIS
-- 05 - EXPLORATORY ANALYSIS
-- =====================================================
-- Answers the six business questions in documentation/project_brief.md.
-- Every query in this script only reads the clean table. Nothing is changed.
-- Grain: one row per hospital visit. Rates are percentages of visits.
-- Visits with no department are shown as 'Unknown' rather than dropped.
-- Expected values were confirmed against hospital_operations_clean on 12 Nov 2026.
--
-- Reading the results: many groups here are small. A rate based on a few
-- hundred visits can move several points by chance, so check the visit count
-- behind a percentage before comparing it with another.

USE hospital_operations;


-- =====================================================
-- 1. HEADLINE KPIS
-- =====================================================

-- One row summarising the clean table.
-- The average stay covers admitted visits only (Inpatient and Emergency) and
-- leaves out the six stays of 60 days or more, as agreed in DQ-010. The CASE
-- returns NULL for every other visit, and AVG skips NULLs.
-- Occupancy is not reported here because it cannot measure capacity (see section 6).
-- Expected: 5,000 visits from 2023-01-01 to 2024-12-31, average admitted stay
-- 7.54 days, bed 65.98%, ICU 19.48%, oxygen 30.78%, ventilator 6.20%,
-- readmission 13.82%.

SELECT
    COUNT(*) AS visits,
    MIN(visit_date) AS first_visit,
    MAX(visit_date) AS last_visit,
    ROUND(
        AVG(
            CASE
                WHEN admission_type IN ('Inpatient', 'Emergency')
                    AND flag_long_stay = 0
                    THEN length_of_stay
            END
        ),
        2
    ) AS avg_stay_days_admitted_excl_long,
    ROUND(100.0 * SUM(bed_required) / COUNT(*), 2) AS bed_required_pct,
    ROUND(100.0 * SUM(icu_required) / COUNT(*), 2) AS icu_required_pct,
    ROUND(100.0 * SUM(oxygen_required) / COUNT(*), 2) AS oxygen_required_pct,
    ROUND(100.0 * SUM(ventilator_required) / COUNT(*), 2) AS ventilator_required_pct,
    ROUND(100.0 * SUM(readmitted_within_30_days) / COUNT(*), 2) AS readmission_pct
FROM hospital_operations_clean;


-- =====================================================
-- 2. Q1 - VISIT VOLUME
-- Which departments, diseases and admission types
-- account for the highest visit volumes?
-- =====================================================

-- Visits and share of all visits by department.
-- SUM(COUNT(*)) OVER () adds the group counts together to give the 5,000 total,
-- so each group can be shown as a share of it.
-- Expected: nine rows summing to 5,000. General Medicine 1,482 (29.64%),
-- ICU 959 (19.18%), Pulmonology 863 (17.26%) and Gastroenterology 740 (14.80%)
-- hold 80.88% between them. Unknown 75 (1.50%).

SELECT
    COALESCE(department, 'Unknown') AS department,
    COUNT(*) AS visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_visits_pct
FROM hospital_operations_clean
GROUP BY department
ORDER BY visits DESC;


-- Visits and share of all visits by disease.
-- Expected: 20 rows summing to 5,000, spread fairly evenly. Food Poisoning 364
-- (7.28%), Influenza 359 and Dengue 358 are highest; Heart Disease 183 (3.66%)
-- is lowest.

SELECT
    disease,
    COUNT(*) AS visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_visits_pct
FROM hospital_operations_clean
GROUP BY disease
ORDER BY visits DESC;


-- Visits and share of all visits by admission type.
-- Expected: Inpatient 1,912 (38.24%), OPD 1,695 (33.90%), Emergency 1,393 (27.86%).

SELECT
    admission_type,
    COUNT(*) AS visits,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_visits_pct
FROM hospital_operations_clean
GROUP BY admission_type
ORDER BY visits DESC;


-- =====================================================
-- 3. Q2 - VISIT VOLUME OVER TIME
-- How does visit volume vary by month, day of week
-- and season?
-- =====================================================

-- Visits in each month of each year.
-- Expected: 24 rows; 2,469 visits in 2023 and 2,531 in 2024. October is the
-- highest month in both years (228 and 240) and November is low in both
-- (186 and 169). Every other month falls between 187 and 231.

SELECT
    visit_year,
    visit_month,
    COUNT(*) AS visits
FROM hospital_operations_clean
GROUP BY
    visit_year,
    visit_month
ORDER BY
    visit_year,
    visit_month;


-- Visits by calendar month with the two years combined, to separate a repeated
-- pattern from a one-off spike. The table covers two years, so dividing by 2
-- gives the average for that month.
-- Expected: 12 rows. October 468 is highest and November 355 is lowest;
-- every other month falls between 389 and 454.

SELECT
    visit_month,
    COUNT(*) AS visits,
    ROUND(COUNT(*) / 2.0, 1) AS avg_visits_per_year
FROM hospital_operations_clean
GROUP BY visit_month
ORDER BY visit_month;


-- Visits by season. Seasons hold two or three months each, so the comparison
-- uses average visits per month: total visits divided by the number of months
-- in the season across both years.
-- Expected: Spring 211.5, Summer 211.5, Winter 209.0, Autumn 205.8, Monsoon 205.2.
-- October and November are both in Autumn and cancel each other out.

SELECT
    visit_season,
    COUNT(*) AS visits,
    COUNT(DISTINCT visit_month) AS months_in_season,
    ROUND(COUNT(*) / (2.0 * COUNT(DISTINCT visit_month)), 1) AS avg_visits_per_month
FROM hospital_operations_clean
GROUP BY visit_season
ORDER BY avg_visits_per_month DESC;


-- Visits by day of the week.
-- Expected: seven rows between 697 (Monday) and 728 (Friday), a spread of about 4%.

SELECT
    visit_day_of_week,
    COUNT(*) AS visits
FROM hospital_operations_clean
GROUP BY visit_day_of_week
ORDER BY visits DESC;


-- =====================================================
-- 4. Q3 - LENGTH OF STAY
-- How does length of stay vary by admission type,
-- severity and department?
-- =====================================================
-- OPD (outpatient) visits are same-day by design, so every query in this
-- section covers Inpatient and Emergency visits only and leaves out the six
-- flagged stays of 60 days or more (DQ-010). COUNT(length_of_stay) counts only
-- visits with a stay recorded, so blank stays are left out as well.

-- Average, shortest and longest stay by admission type.
-- Expected: Emergency 1,373 visits averaging 9.14 days; Inpatient 1,897 visits
-- averaging 6.39 days; 3,270 visits in total. Stays run from 1 to 30 days.

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


-- Average stay by severity.
-- Expected: Critical 393 visits averaging 20.24 days, Severe 996 averaging 9.93,
-- Moderate 1,242 averaging 4.47 and Mild 639 averaging 1.99; 3,270 visits in
-- total. Each step up in severity roughly doubles the average stay.

SELECT
    severity,
    COUNT(length_of_stay) AS admitted_visits_with_stay,
    ROUND(AVG(length_of_stay), 2) AS avg_stay_days
FROM hospital_operations_clean
WHERE admission_type IN ('Inpatient', 'Emergency')
    AND flag_long_stay = 0
GROUP BY severity
ORDER BY avg_stay_days DESC;


-- Average stay and total bed-days by department. Bed-days are the sum of all
-- stay lengths, which shows where bed time is used, not just how many visits.
-- Expected: nine rows summing to 3,270 visits and 24,664 bed-days. ICU has 890
-- visits averaging 13.49 days and 12,007 bed-days, 48.7% of the total. General
-- Medicine is next with 3,995 bed-days from 834 visits.

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


-- =====================================================
-- 5. Q4 - RESOURCE REQUIREMENTS
-- How do bed, ICU, oxygen and ventilator requirements
-- vary by severity, department and admission type?
-- =====================================================
-- Each resource field is a yes or no recorded on the visit. It shows whether a
-- resource was needed, not for how long.

-- Share of visits needing each resource, by severity.
-- Expected (bed, ICU, oxygen, ventilator):
--   Critical  88.53, 85.29, 76.56, 56.61  (401 visits)
--   Severe    90.26, 51.98, 57.94,  7.84  (1,058 visits)
--   Moderate  78.24,  4.58, 27.23,  0.00  (1,792 visits)
--   Mild      33.56,  0.00,  7.49,  0.00  (1,749 visits)
-- Severe has the lower ICU rate but is the larger group, so it supplies more
-- ICU visits (550) than Critical (342).

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


-- ICU, ventilator and oxygen need by department.
-- Limitation: the ICU field mirrors the ICU department. Every ICU-department
-- visit is recorded as needing ICU and no visit in another named department is,
-- so the field shows where a visit was placed, not an independent clinical need.
-- Expected: 974 ICU visits, 959 in the ICU department (100%) and 15 in Unknown.
-- 310 ventilator visits, 304 in ICU and 6 in Unknown. Every other department
-- shows 0 for both. Oxygen: ICU 63.92% and Pulmonology 58.63%; the other named
-- departments fall between 6.78% and 15.79%.

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


-- Share of visits needing each resource, by admission type.
-- OPD is kept as its own row. 320 OPD visits are recorded as needing a bed, ICU
-- or ventilator, which an outpatient visit should not need. They are flagged as
-- flag_opd_with_resource (DQ-013); the evidence is in section 9.
-- Expected (bed, ICU, oxygen, ventilator):
--   Emergency  90.24, 36.68, 45.30, 14.93  (1,393 visits)
--   Inpatient  90.59, 21.34, 33.73,  4.92  (1,912 visits)
--   OPD        18.29,  3.24, 15.52,  0.47  (1,695 visits)

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


-- =====================================================
-- 6. Q5 - CAPACITY PRESSURE
-- What do recorded bed and ICU occupancy suggest
-- about capacity pressure?
-- =====================================================
-- Answered as a negative finding. The occupancy and capacity fields are
-- recorded separately on every visit row, not once per hospital day, so no
-- value describes the hospital on a given date and the fields cannot measure
-- capacity pressure. The evidence is in section 8 and is logged as DQ-012.

-- Reports what was recorded, for completeness only. These figures are not
-- evidence of capacity pressure and are excluded from the dashboard.
-- Expected: 5,000 visit records; bed occupancy averages 66.24 with a maximum of
-- 89.64; ICU occupancy averages 52.24 with a maximum of 69.70.

SELECT
    COUNT(*) AS visit_records,
    ROUND(AVG(bed_occupancy_pct), 2) AS avg_bed_occupancy_pct,
    MAX(bed_occupancy_pct) AS max_bed_occupancy_pct,
    ROUND(AVG(icu_occupancy_pct), 2) AS avg_icu_occupancy_pct,
    MAX(icu_occupancy_pct) AS max_icu_occupancy_pct
FROM hospital_operations_clean;


-- =====================================================
-- 7. Q6 - 30-DAY READMISSIONS
-- What patterns appear in recorded 30-day readmissions?
-- =====================================================
-- Every patient has exactly one visit in this dataset, so readmission is a
-- yes or no recorded on the visit, not a return visit that can be traced.
-- Results describe visits recorded as readmitted within 30 days. Overall,
-- 691 of the 5,000 visits (13.82%) carry that mark.

-- Recorded readmissions by severity.
-- Expected: Severe 203 of 1,058 (19.19%), Critical 66 of 401 (16.46%),
-- Moderate 222 of 1,792 (12.39%), Mild 200 of 1,749 (11.44%); 691 in total.
-- Critical is a small group, so the gap between Severe and Critical is within
-- what chance could produce.

SELECT
    severity,
    COUNT(*) AS visits,
    SUM(readmitted_within_30_days) AS readmissions,
    ROUND(100.0 * SUM(readmitted_within_30_days) / COUNT(*), 2) AS readmission_pct
FROM hospital_operations_clean
GROUP BY severity
ORDER BY readmission_pct DESC;


-- Recorded readmissions by disease.
-- Expected: 20 rows summing to 691. Stroke is highest at 47 of 228 (20.61%).
-- Allergy, Arthritis, Migraine and Food Poisoning are the only diseases below
-- 10%, with Food Poisoning lowest at 34 of 364 (9.34%). Each disease has only
-- 183 to 364 visits, so most of the ranking in between is not meaningful.

SELECT
    disease,
    COUNT(*) AS visits,
    SUM(readmitted_within_30_days) AS readmissions,
    ROUND(100.0 * SUM(readmitted_within_30_days) / COUNT(*), 2) AS readmission_pct
FROM hospital_operations_clean
GROUP BY disease
ORDER BY readmission_pct DESC;


-- Recorded readmissions by department.
-- Expected: nine rows summing to 691. ICU is highest at 168 of 959 (17.52%).
-- Neurology, Pulmonology, Cardiology, Unknown and General Medicine fall between
-- 13.16% and 13.99%. Nephrology is lowest at 14 of 141 (9.93%), a small group.

SELECT
    COALESCE(department, 'Unknown') AS department,
    COUNT(*) AS visits,
    SUM(readmitted_within_30_days) AS readmissions,
    ROUND(100.0 * SUM(readmitted_within_30_days) / COUNT(*), 2) AS readmission_pct
FROM hospital_operations_clean
GROUP BY department
ORDER BY readmission_pct DESC;


-- =====================================================
-- 8. EXTRAS - EVIDENCE FOR DQ-012
-- =====================================================
-- These checks are not part of the six business questions. They show that the
-- capacity, occupancy and oxygen-unit fields are recorded per visit row, not
-- per hospital day, which is the basis for the negative finding in section 6.

-- Check for zero or missing bed capacity. A zero would make the occupancy
-- percentage NULL without raising an error, and the averages in section 6
-- would quietly skip those rows.
-- Each SUM counts the rows meeting its condition (true = 1, false = 0).
-- Expected: 0 in every column.

SELECT
    SUM(total_beds_available = 0) AS zero_total_beds,
    SUM(icu_beds_available = 0) AS zero_icu_beds,
    SUM(total_beds_available IS NULL) AS missing_total_beds,
    SUM(icu_beds_available IS NULL) AS missing_icu_beds,
    SUM(bed_occupancy_pct IS NULL) AS null_bed_occupancy,
    SUM(icu_occupancy_pct IS NULL) AS null_icu_occupancy
FROM hospital_operations_clean;


-- Count how many different occupancy values each date carries, next to how
-- many visits that date has. The subquery builds one row per date; the outer
-- query averages across the dates. A figure near 1 would mean a true daily
-- value. A figure near the visit count means each row has its own value.
-- Expected: 730 visit dates, 6.85 visits per day, 6.83 distinct bed-occupancy
-- values per day, at most 17 in a single day, 6.49 distinct ICU-occupancy
-- values per day, and only 9 dates carrying a single bed-occupancy value.

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


-- Repeat the same test on the capacity and oxygen-unit columns, to confirm the
-- pattern is not limited to the occupancy percentages. Oxygen units hold 100
-- NULLs, which COUNT(DISTINCT) skips, so that column reads slightly low.
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


-- =====================================================
-- 9. EXTRAS - EVIDENCE FOR DQ-013
-- =====================================================

-- Count OPD (outpatient) visits recorded as needing a bed, ICU or ventilator,
-- which an outpatient visit should not need. The last two columns show how many
-- of them have a zero-day stay and how many are already flagged as OPD with a
-- stay (DQ-010).
-- Expected: 1,695 OPD visits; 310 needing a bed, 55 ICU and 8 a ventilator;
-- 320 needing at least one, of which 268 have a zero-day stay and 49 are
-- flagged as OPD with a stay. The other 3 have a blank stay.

SELECT
    COUNT(*) AS opd_visits,
    SUM(bed_required) AS opd_needing_bed,
    SUM(icu_required) AS opd_needing_icu,
    SUM(ventilator_required) AS opd_needing_ventilator,
    SUM(
        bed_required = 1
        OR icu_required = 1
        OR ventilator_required = 1
    ) AS opd_needing_any,
    SUM(
        (
            bed_required = 1
            OR icu_required = 1
            OR ventilator_required = 1
        )
        AND length_of_stay = 0
    ) AS of_which_zero_day_stay,
    SUM(
        (
            bed_required = 1
            OR icu_required = 1
            OR ventilator_required = 1
        )
        AND flag_opd_with_stay = 1
    ) AS of_which_flagged_opd_with_stay
FROM hospital_operations_clean
WHERE admission_type = 'OPD';
