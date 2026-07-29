/*
Project: Hospital Operations Analysis
Script: 04_exploratory_analysis.sql
Purpose: Explore patient demand, hospital capacity and operational patterns.
Source table: hospital_operations_clean
*/

USE hospital_operations;


-- =========================================================
-- 1. OVERALL ACTIVITY SUMMARY
-- =========================================================

-- Business question:
-- What is the overall scale, date coverage and length-of-stay profile of the dataset?

SELECT
    COUNT(*) AS total_patient_records,
    COUNT(DISTINCT Visit_Date) AS number_of_visit_dates,
    MIN(Visit_Date) AS earliest_visit_date,
    MAX(Visit_Date) AS latest_visit_date,
    ROUND(AVG(Length_of_Stay), 2) AS average_length_of_stay,
    MIN(Length_of_Stay) AS minimum_length_of_stay,
    MAX(Length_of_Stay) AS maximum_length_of_stay
FROM hospital_operations_clean;

-- Finding:
-- The dataset contains 5,075 patient records across 730 distinct visit dates.
-- The recorded visit period runs from 1 January 2023 to 31 December 2024.
-- The average length of stay is 5.10 days, with a minimum of 0 days and a maximum of 120 days.


-- Business question:
-- What are the minimum, maximum and average recorded lengths of stay?

SELECT
    MIN(Length_of_Stay) AS minimum_stay,
    MAX(Length_of_Stay) AS maximum_stay,
    AVG(Length_of_Stay) AS average_stay
FROM hospital_operations_clean;


-- Business question:
-- Which patient records have the longest recorded lengths of stay?

SELECT
    Patient_ID,
    Visit_Date,
    Age,
    Disease,
    Severity,
    Admission_Type,
    Department,
    Length_of_Stay
FROM hospital_operations_clean
ORDER BY Length_of_Stay DESC
LIMIT 10;

-- Finding:
-- The average length of stay is 5.10 days, but a small number of records have substantially longer stays.
-- The ten longest stays include 1 record at 120 days, 4 at 90 days, 1 at 60 days and 4 at 30 days.
-- These records have been retained because there is no evidence that they are incorrect.


-- =========================================================
-- 2. LENGTH-OF-STAY DISTRIBUTION
-- =========================================================

-- Business question:
-- How are patient records distributed across different lengths of stay?

SELECT
    Length_of_Stay,
    COUNT(*) AS number_of_records
FROM hospital_operations_clean
WHERE Length_of_Stay IS NOT NULL
GROUP BY Length_of_Stay
ORDER BY Length_of_Stay
LIMIT 100;

-- Finding:
-- Length of stay is concentrated at the lower end of the distribution.
-- A total of 1,644 records have a stay of 0 days, while most remaining records fall between 1 and 15 days.
-- Stays of 30 days or more are rare, with only a small number of records at 60, 90 and 120 days.
-- Zero-day stays require interpretation because they may represent same-day treatment, outpatient activity or incomplete recording.


-- Business question:
-- Which admission types account for the zero-day length-of-stay records?

SELECT
    Admission_Type,
    COUNT(*) AS zero_day_records
FROM hospital_operations_clean
WHERE Length_of_Stay = 0
GROUP BY Admission_Type
ORDER BY zero_day_records DESC;

-- Finding:
-- All 1,644 records with Length_of_Stay = 0 are classified as OPD.
-- This strongly suggests that zero-day stays represent outpatient visits where no overnight admission occurred.
-- These records are therefore retained as valid values.


-- Business question:
-- How does length of stay vary between admission types?

SELECT
    Admission_Type,
    COUNT(*) AS patient_records,
    ROUND(AVG(Length_of_Stay), 2) AS average_length_of_stay,
    MIN(Length_of_Stay) AS minimum_length_of_stay,
    MAX(Length_of_Stay) AS maximum_length_of_stay
FROM hospital_operations_clean
WHERE Length_of_Stay IS NOT NULL
GROUP BY Admission_Type
ORDER BY average_length_of_stay DESC;

-- Finding:
-- OPD patients had the shortest average length of stay at 0.17 days, which is consistent with outpatient treatment.
-- However, the OPD group also contains the longest recorded stay of 120 days.
-- This is inconsistent with the wider OPD pattern and should be investigated as a potential outlier or misclassified admission.
-- Emergency and Inpatient records both have a minimum stay of 1 day, suggesting that these admission types generally involved at least one overnight stay.


-- =========================================================
-- 3. OPD LENGTH-OF-STAY INVESTIGATION
-- =========================================================

-- Business question:
-- Which OPD records have a positive length of stay?

SELECT
    Patient_ID,
    Visit_Date,
    Disease,
    Severity,
    Department,
    Length_of_Stay
FROM hospital_operations_clean
WHERE Admission_Type = 'OPD'
  AND Length_of_Stay > 0
ORDER BY Length_of_Stay DESC;


-- Business question:
-- What proportion of OPD records have zero-day, positive or missing lengths of stay?

SELECT
    COUNT(*) AS total_opd_records,

    SUM(
        CASE
            WHEN Length_of_Stay = 0 THEN 1
            ELSE 0
        END
    ) AS zero_day_opd_records,

    SUM(
        CASE
            WHEN Length_of_Stay > 0 THEN 1
            ELSE 0
        END
    ) AS positive_stay_opd_records,

    SUM(
        CASE
            WHEN Length_of_Stay IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_stay_opd_records,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Length_of_Stay = 0 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS zero_day_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Length_of_Stay > 0 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS positive_stay_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Length_of_Stay IS NULL THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS missing_stay_percentage

FROM hospital_operations_clean
WHERE Admission_Type = 'OPD';

-- Finding:
-- The dataset contains 1,715 OPD records.
-- Of these, 1,644 records (95.86%) have a zero-day stay, supporting the interpretation that most OPD activity is same-day.
-- A total of 52 records (3.03%) have a positive length of stay, while 19 records (1.11%) have a missing Length_of_Stay value.
-- The small number of positive OPD stays includes unusual records of 60 and 120 days, which should be flagged for validation.


-- =========================================================
-- 4. PATIENT DEMAND BY DEPARTMENT
-- =========================================================

-- Business question:
-- Which departments recorded the highest patient demand?

SELECT
    Department,
    COUNT(*) AS patient_records
FROM hospital_operations_clean
WHERE Department IS NOT NULL
GROUP BY Department
ORDER BY patient_records DESC;

-- Finding:
-- General Medicine recorded the highest patient demand with 1,502 records, followed by ICU (973), Pulmonology (876) and Gastroenterology (754).
-- Neurology, Cardiology, Orthopedics and Nephrology recorded substantially lower volumes.

-- Limitation:
-- Patient volume does not by itself measure workload, complexity or capacity pressure without also considering severity, ICU requirements and length of stay.


-- =========================================================
-- 5. PATIENT DEMAND BY DISEASE
-- =========================================================

-- Business question:
-- Which diseases recorded the highest patient demand?

SELECT
    Disease,
    COUNT(*) AS patient_records
FROM hospital_operations_clean
GROUP BY Disease
ORDER BY patient_records DESC;

-- Finding:
-- Food Poisoning recorded the highest patient demand with 374 records, followed closely by Influenza (366) and Dengue (362).
-- Gastritis was the fourth most frequently recorded disease with 317 records.
-- Patient demand was distributed across a wide range of conditions rather than being dominated by a single disease.
-- Infectious and respiratory conditions accounted for several of the most frequently recorded diseases.

-- =========================================================
-- 6. PATIENT DEMAND OVER TIME
-- =========================================================

-- Business question:
-- How did patient demand change from month to month across the reporting period?

SELECT
    YEAR(Visit_Date) AS visit_year,
    MONTH(Visit_Date) AS visit_month,
    MONTHNAME(Visit_Date) AS month_name,
    COUNT(*) AS patient_records
FROM hospital_operations_clean
WHERE Visit_Date IS NOT NULL
GROUP BY
    YEAR(Visit_Date),
    MONTH(Visit_Date),
    MONTHNAME(Visit_Date)
ORDER BY
    visit_year,
    visit_month;
    
    -- Finding:
-- Monthly patient demand remained relatively stable across the reporting period, with most months recording between approximately 190 and 230 patient records.
-- October 2024 recorded the highest monthly demand with 246 records, while November 2024 recorded the lowest with 170 records.
-- The results do not show a clear sustained increase or decrease in patient demand over time.

-- Limitation:
-- Monthly totals alone do not explain whether changes were caused by seasonality, disease outbreaks, service availability or differences in data recording.

-- Business question:
-- How did patient demand change for each calendar month between 2023 and 2024?


-- Finding:
-- Patient demand remained broadly stable between 2023 and 2024, but several months recorded noticeable year-on-year changes.
-- June showed the largest increase, rising by 35 records, followed by February with 24 additional records and July with 23 additional records.
-- November showed the largest decrease, falling by 19 records, followed by March with 16 fewer records and December with 14 fewer records.
-- September recorded no year-on-year change, with 202 records in both years.

-- Limitation:
-- The year-on-year comparison shows changes in patient volume but does not explain whether they were caused by seasonality, disease patterns, service changes or differences in data recording.

-- =========================================================
-- 7. MONTHLY DEMAND BY DISEASE
-- =========================================================

-- Business question:
-- Which diseases contributed the highest patient demand in each month?

SELECT
    YEAR(Visit_Date) AS visit_year,
    MONTH(Visit_Date) AS visit_month,
    MONTHNAME(Visit_Date) AS month_name,
    Disease,
    COUNT(*) AS patient_records
FROM hospital_operations_clean
WHERE Visit_Date IS NOT NULL
  AND Disease IS NOT NULL
GROUP BY
    YEAR(Visit_Date),
    MONTH(Visit_Date),
    MONTHNAME(Visit_Date),
    Disease
ORDER BY
    visit_year,
    visit_month,
    patient_records DESC;

-- Finding:
-- June 2024 demand was concentrated in Food Poisoning, Gastritis and Allergy, which recorded 30, 28 and 23 patient records respectively.
-- October 2024 had the highest overall monthly demand, but activity was distributed more evenly across several diseases.
-- November 2024 recorded the lowest monthly demand, with no single disease accounting for a particularly large share of activity.

-- Limitation:
-- The monthly disease totals describe the composition of demand within each month but do not yet show which diseases caused the year-on-year changes between 2023 and 2024.

-- Business question:
-- Which diseases contributed to the increase in patient demand between June 2023 and June 2024?

SELECT
    Disease,

    SUM(
        CASE
            WHEN YEAR(Visit_Date) = 2023
             AND MONTH(Visit_Date) = 6
            THEN 1
            ELSE 0
        END
    ) AS patient_records_june_2023,

    SUM(
        CASE
            WHEN YEAR(Visit_Date) = 2024
             AND MONTH(Visit_Date) = 6
            THEN 1
            ELSE 0
        END
    ) AS patient_records_june_2024,

    SUM(
        CASE
            WHEN YEAR(Visit_Date) = 2024
             AND MONTH(Visit_Date) = 6
            THEN 1
            ELSE 0
        END
    )
    -
    SUM(
        CASE
            WHEN YEAR(Visit_Date) = 2023
             AND MONTH(Visit_Date) = 6
            THEN 1
            ELSE 0
        END
    ) AS year_on_year_change

FROM hospital_operations_clean
WHERE Visit_Date IS NOT NULL
  AND Disease IS NOT NULL
  AND MONTH(Visit_Date) = 6
GROUP BY Disease
ORDER BY year_on_year_change DESC;


-- Finding:
-- Allergy recorded the largest increase between June 2023 and June 2024, rising by 12 patient records.
-- Bronchitis increased by 8 records, while Dengue and Arthritis each increased by 7 records.
-- These increases were partly offset by decreases in Tuberculosis, Chronic Kidney Disease and Diabetes.
-- The overall increase in June demand was therefore driven mainly by Allergy, Bronchitis, Dengue and Arthritis.

-- Limitation:
-- The comparison identifies which diseases changed most but does not explain whether the differences reflect seasonality, outbreaks, service changes or random variation.

-- =========================================================
-- 8. PATIENT DEMAND BY DAY OF WEEK
-- =========================================================

-- Business question:
-- How did patient demand vary across the days of the week?

SELECT
    Day_of_Week,
    COUNT(*) AS patient_records
FROM hospital_operations_clean
WHERE Day_of_Week IS NOT NULL
GROUP BY Day_of_Week
ORDER BY FIELD(
    Day_of_Week,
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
);

-- Finding:
-- Patient demand was evenly distributed across the week, with daily volumes ranging from 709 to 740 records.
-- Wednesday recorded the highest demand with 740 patient records, followed by Thursday (733), Friday (732) and Tuesday (731).
-- Monday recorded the lowest demand with 709 patient records.
-- The small difference between the highest and lowest days suggests that no single day experienced a substantially higher level of patient activity.

-- Limitation:
-- Day-of-week totals do not show whether demand varied by admission type, department, severity or time of day.

-- =========================================================
-- 9. HOSPITAL CAPACITY AND RESOURCE USE
-- =========================================================

-- Business question:
-- How frequently were beds, ICU services, oxygen and ventilators required?

SELECT
    SUM(
        CASE
            WHEN Bed_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS bed_required_records,

    SUM(
        CASE
            WHEN ICU_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS icu_required_records,

    SUM(
        CASE
            WHEN Oxygen_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS oxygen_required_records,

    SUM(
        CASE
            WHEN Ventilator_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS ventilator_required_records

FROM hospital_operations_clean;

-- Finding:
-- Beds were required for 3,351 patient records, making this the most frequently recorded resource requirement.
-- Oxygen was required for 1,559 records, while ICU services were required for 988 records.
-- Ventilators were required for 313 records, making this the least frequently recorded resource requirement.
-- These resource requirements are not mutually exclusive because one patient record may require more than one type of support.

-- Limitation:
-- These totals show how often each resource was required but do not show duration of use, simultaneous demand or whether capacity was sufficient.

-- Business question:
-- What percentage of patient records required beds, ICU services, oxygen and ventilators?

SELECT
    COUNT(*) AS total_patient_records,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Bed_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS bed_required_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN ICU_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS icu_required_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Oxygen_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS oxygen_required_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Ventilator_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS ventilator_required_percentage

FROM hospital_operations_clean;

-- Finding:
-- Beds were required for 66.03% of patient records, making them the most common resource requirement.
-- Oxygen was required for 30.72% of records, while ICU services were required for 19.47%.
-- Ventilators were required for 6.17% of records, making them the least common resource requirement.

-- Limitation:
-- These percentages show how frequently each resource was required but do not measure how long the resource was used or whether multiple resources were required at the same time.

-- Business question:
-- Which departments recorded the highest demand for beds, ICU services, oxygen and ventilators?

SELECT
    Department,

    SUM(
        CASE
            WHEN Bed_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS bed_required_records,

    SUM(
        CASE
            WHEN ICU_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS icu_required_records,

    SUM(
        CASE
            WHEN Oxygen_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS oxygen_required_records,

    SUM(
        CASE
            WHEN Ventilator_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS ventilator_required_records

FROM hospital_operations_clean
WHERE Department IS NOT NULL
GROUP BY Department
ORDER BY bed_required_records DESC;

-- Finding:
-- ICU recorded the highest bed demand with 882 records and accounted for 973 ICU-required records.
-- ICU also recorded the highest oxygen demand with 619 records and almost all ventilator demand with 307 records.
-- Pulmonology recorded the second-highest oxygen demand with 514 records, while General Medicine recorded the second-highest bed demand with 871 records.
-- Gastroenterology, Neurology, Cardiology, Nephrology and Orthopedics recorded lower levels of resource demand.

-- Limitation:
-- These totals are influenced by department size, so departments with more patient records may naturally record higher resource demand.
-- The results do not show the proportion of patients within each department who required each resource.

-- Business question:
-- What percentage of patient records within each department required beds, ICU services, oxygen and ventilators?

SELECT
    Department,
    COUNT(*) AS total_department_records,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Bed_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS bed_required_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN ICU_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS icu_required_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Oxygen_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS oxygen_required_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Ventilator_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS ventilator_required_percentage

FROM hospital_operations_clean
WHERE Department IS NOT NULL
GROUP BY Department
ORDER BY bed_required_percentage DESC;

-- Finding:
-- ICU recorded the highest resource intensity, with 90.65% of records requiring a bed, 100.00% requiring ICU services, 63.62% requiring oxygen and 31.55% requiring a ventilator.
-- Pulmonology recorded the second-highest oxygen requirement at 58.68%, indicating substantial respiratory-support demand within the department.
-- Nephrology recorded the second-highest bed requirement at 71.33%, although it had considerably fewer patient records than ICU or Pulmonology.
-- Orthopedics recorded the lowest bed requirement at 52.22% and the lowest oxygen requirement at 6.67%.
-- General Medicine handled the highest overall patient volume, but its resource requirement percentages were lower than those recorded in ICU and Pulmonology.

-- Limitation:
-- These percentages show the proportion of records requiring each resource but do not measure duration of use, simultaneous demand or actual resource availability.
-- The analysis excludes records with a missing Department value, including some ICU-required and ventilator-required records.

-- Business question:
-- Were occupied beds or ICU beds ever recorded above the available capacity?

SELECT
    SUM(
        CASE
            WHEN Beds_Occupied > Total_Beds_Available THEN 1
            ELSE 0
        END
    ) AS bed_capacity_exceeded_records,

    SUM(
        CASE
            WHEN ICU_Beds_Occupied > ICU_Beds_Available THEN 1
            ELSE 0
        END
    ) AS icu_capacity_exceeded_records

FROM hospital_operations_clean;

-- Finding:
-- No records showed occupied beds exceeding total bed capacity.
-- No records showed occupied ICU beds exceeding available ICU bed capacity.
-- Based on the recorded values, the hospital did not exceed its stated bed or ICU capacity during the reporting period.

-- Limitation:
-- The capacity fields may represent repeated operational snapshots rather than patient-level measurements.
-- A result of zero does not prove that capacity pressure never occurred, because the dataset may not capture peak occupancy, timing or duration.

-- Business question:
-- What were the average bed and ICU occupancy levels across the reporting period?

SELECT
    ROUND(AVG(Beds_Occupied), 2) AS average_beds_occupied,
    ROUND(AVG(Total_Beds_Available), 2) AS average_total_beds_available,
    ROUND(
        100.0 * AVG(Beds_Occupied) / AVG(Total_Beds_Available),
        2
    ) AS average_bed_occupancy_percentage,

    ROUND(AVG(ICU_Beds_Occupied), 2) AS average_icu_beds_occupied,
    ROUND(AVG(ICU_Beds_Available), 2) AS average_icu_beds_available,
    ROUND(
        100.0 * AVG(ICU_Beds_Occupied) / AVG(ICU_Beds_Available),
        2
    ) AS average_icu_occupancy_percentage

FROM hospital_operations_clean;

-- Finding:
-- Average bed occupancy was 109.13 out of 164.72 available beds, producing an average recorded occupancy rate of 66.25%.
-- Average ICU occupancy was 12.56 out of 23.85 available ICU beds, producing an average recorded occupancy rate of 52.67%.
-- General bed occupancy was therefore higher than ICU occupancy across the reporting period.
-- Both average occupancy rates remained below the recorded available capacity.

-- Limitation:
-- The occupancy values may be repeated across multiple patient records and may not represent independent daily capacity snapshots.
-- Average occupancy can conceal short periods of high demand and does not show how frequently capacity approached its maximum.

-- Business question:
-- What were the highest recorded bed and ICU occupancy rates in the dataset?

SELECT
    MAX(Beds_Occupied) AS maximum_beds_occupied,
    MAX(Total_Beds_Available) AS maximum_total_beds_available,
    ROUND(
        MAX(
            100.0 * Beds_Occupied / NULLIF(Total_Beds_Available, 0)
        ),
        2
    ) AS maximum_bed_occupancy_percentage,

    MAX(ICU_Beds_Occupied) AS maximum_icu_beds_occupied,
    MAX(ICU_Beds_Available) AS maximum_icu_beds_available,
    ROUND(
        MAX(
            100.0 * ICU_Beds_Occupied / NULLIF(ICU_Beds_Available, 0)
        ),
        2
    ) AS maximum_icu_occupancy_percentage

FROM hospital_operations_clean;

-- Finding:
-- The highest recorded bed occupancy rate was 89.64%, indicating that general bed usage approached but did not exceed recorded capacity.
-- The highest recorded ICU occupancy rate was 69.70%, which was lower than the peak general bed occupancy rate.
-- Maximum occupied beds reached 218, while maximum occupied ICU beds reached 27.
-- No recorded observation exceeded the corresponding available bed or ICU capacity.

-- Limitation:
-- The maximum occupied and maximum available values may come from different records and should not be interpreted as a matched capacity snapshot.
-- The occupancy percentages are more reliable for identifying peak utilisation because each percentage is calculated within the same record.
-- The dataset may contain repeated capacity observations across patient records, so these results do not confirm how long peak occupancy lasted.

-- Business question:
-- Which records contained the highest bed and ICU occupancy rates?

SELECT
    Visit_Date,
    Department,
    Beds_Occupied,
    Total_Beds_Available,
    ROUND(
        100.0 * Beds_Occupied / NULLIF(Total_Beds_Available, 0),
        2
    ) AS bed_occupancy_percentage,
    ICU_Beds_Occupied,
    ICU_Beds_Available,
    ROUND(
        100.0 * ICU_Beds_Occupied / NULLIF(ICU_Beds_Available, 0),
        2
    ) AS icu_occupancy_percentage
FROM hospital_operations_clean
WHERE Beds_Occupied IS NOT NULL
   OR ICU_Beds_Occupied IS NOT NULL
ORDER BY
    bed_occupancy_percentage DESC,
    icu_occupancy_percentage DESC
LIMIT 10;

-- Finding:
-- The highest recorded bed occupancy rate was 89.64% on 15 February 2023, when 173 of 193 beds were occupied.
-- The ten highest bed occupancy records ranged from 88.89% to 89.64%, showing several observations where general bed use approached 90% of recorded capacity.
-- These high-occupancy records occurred across General Medicine, Pulmonology and ICU rather than being concentrated in a single department.
-- The highest ICU occupancy rate within these ten records was 68.00% on 22 December 2023, indicating that high general bed occupancy did not always coincide with equally high ICU occupancy.

-- Limitation:
-- Each row appears to contain hospital-wide capacity values alongside a patient-level department, so the Department field may not identify which department caused the occupancy level.
-- Several records may repeat the same operational capacity snapshot across different patient records.
-- The query ranks records by bed occupancy first, so it does not necessarily return the ten highest ICU occupancy records.

-- Business question:
-- Which records contained the highest ICU occupancy rates?

SELECT
    Visit_Date,
    Department,
    ICU_Beds_Occupied,
    ICU_Beds_Available,
    ROUND(
        100.0 * ICU_Beds_Occupied / NULLIF(ICU_Beds_Available, 0),
        2
    ) AS icu_occupancy_percentage,
    Beds_Occupied,
    Total_Beds_Available,
    ROUND(
        100.0 * Beds_Occupied / NULLIF(Total_Beds_Available, 0),
        2
    ) AS bed_occupancy_percentage
FROM hospital_operations_clean
WHERE ICU_Beds_Occupied IS NOT NULL
  AND ICU_Beds_Available IS NOT NULL
ORDER BY icu_occupancy_percentage DESC
LIMIT 10;

-- Finding:
-- The highest recorded ICU occupancy rate was 69.70%, appearing in four records across 2023 and 2024.
-- The ten highest ICU occupancy records ranged from 69.23% to 69.70%, indicating that peak ICU utilisation remained below 70% of recorded capacity.
-- High ICU occupancy appeared across several dates and was not concentrated in a single period.
-- General bed occupancy varied considerably across these records, ranging from 56.05% to 83.60%, so high ICU occupancy did not consistently coincide with high general bed occupancy.

-- Limitation:
-- The Department field may describe the patient record rather than the location responsible for the ICU occupancy level.
-- Several records may repeat the same hospital-wide capacity snapshot across different patient rows.
-- The analysis identifies peak recorded utilisation but does not show how long these occupancy levels lasted.

-- =========================================================
-- 10. PATIENT SEVERITY AND RESOURCE REQUIREMENTS
-- =========================================================

-- Business question:
-- How did resource requirements vary by patient severity?

SELECT
    Severity,
    COUNT(*) AS patient_records,

    SUM(
        CASE
            WHEN Bed_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS bed_required_records,

    SUM(
        CASE
            WHEN ICU_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS icu_required_records,

    SUM(
        CASE
            WHEN Oxygen_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS oxygen_required_records,

    SUM(
        CASE
            WHEN Ventilator_Required = 'Yes' THEN 1
            ELSE 0
        END
    ) AS ventilator_required_records

FROM hospital_operations_clean
WHERE Severity IS NOT NULL
GROUP BY Severity
ORDER BY patient_records DESC;

-- Finding:
-- Moderate severity recorded the highest patient volume with 1,823 records, followed by Mild severity with 1,774 records.
-- Severe cases recorded the highest oxygen demand with 622 records and the highest number of bed-required records with 970.
-- Critical cases had the strongest association with intensive resource use, with 344 of 404 records requiring ICU services and 229 requiring ventilators.
-- Mild cases recorded no ICU or ventilator requirements and substantially lower oxygen demand than the other severity groups.
-- Resource requirements generally increased as patient severity increased.

-- Limitation:
-- These are total counts and are influenced by the number of records in each severity group.
-- A percentage-based comparison is needed to assess resource intensity fairly across severity levels.

-- Business question:
-- What percentage of records within each severity group required beds, ICU services, oxygen and ventilators?

SELECT
    Severity,
    COUNT(*) AS patient_records,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Bed_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS bed_required_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN ICU_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS icu_required_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Oxygen_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS oxygen_required_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Ventilator_Required = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS ventilator_required_percentage

FROM hospital_operations_clean
WHERE Severity IS NOT NULL
GROUP BY Severity
ORDER BY
    CASE Severity
        WHEN 'Critical' THEN 1
        WHEN 'Severe' THEN 2
        WHEN 'Moderate' THEN 3
        WHEN 'Mild' THEN 4
        ELSE 5
    END;
    
    -- Finding:
-- Critical cases recorded the highest ICU, oxygen and ventilator requirement percentages, with 85.15% requiring ICU services, 76.49% requiring oxygen and 56.68% requiring ventilators.
-- Severe cases recorded the highest bed requirement percentage at 90.32%, slightly above the 88.61% recorded for Critical cases.
-- Moderate cases showed substantially lower resource intensity, with only 4.55% requiring ICU services and no ventilator requirements.
-- Mild cases recorded the lowest resource requirements, with 33.71% requiring beds, 7.50% requiring oxygen and no ICU or ventilator requirements.
-- The results show a clear increase in resource intensity as patient severity rises.

-- Limitation:
-- Resource requirement fields indicate whether support was required but do not show how long each resource was used.
-- The analysis does not account for patients requiring multiple resources at the same time.

-- Business question:
-- How did length of stay vary across patient severity levels?

SELECT
    Severity,
    COUNT(Length_of_Stay) AS records_with_length_of_stay,
    ROUND(AVG(Length_of_Stay), 2) AS average_length_of_stay,
    MIN(Length_of_Stay) AS minimum_length_of_stay,
    MAX(Length_of_Stay) AS maximum_length_of_stay
FROM hospital_operations_clean
WHERE Severity IS NOT NULL
  AND Length_of_Stay IS NOT NULL
GROUP BY Severity
ORDER BY
    CASE Severity
        WHEN 'Critical' THEN 1
        WHEN 'Severe' THEN 2
        WHEN 'Moderate' THEN 3
        WHEN 'Mild' THEN 4
        ELSE 5
    END;
    
    -- Finding:
-- Average length of stay increased substantially with patient severity.
-- Critical cases recorded the longest average stay at 20.24 days, followed by Severe cases at 9.65 days.
-- Moderate cases recorded an average stay of 3.25 days, while Mild cases recorded the shortest average stay at 0.80 days.
-- Critical and Severe cases both had a minimum stay of 1 day, while Moderate and Mild cases included zero-day stays.
-- The longest recorded stay of 120 days occurred within the Mild severity group, making it inconsistent with the wider severity pattern and suitable for further validation.

-- Limitation:
-- Maximum values are sensitive to unusual records and should not be used alone to represent the typical experience within each severity group.
-- Missing Length_of_Stay values were excluded from the calculation.

-- =========================================================
-- 11. THIRTY-DAY READMISSION ANALYSIS
-- =========================================================

-- Business question:
-- What proportion of patient records were readmitted within 30 days?

SELECT
    Readmission_Within_30_Days,
    COUNT(*) AS patient_records,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_records
FROM hospital_operations_clean
WHERE Readmission_Within_30_Days IS NOT NULL
GROUP BY Readmission_Within_30_Days
ORDER BY patient_records DESC;

-- Finding:
-- A total of 703 patient records were associated with readmission within 30 days, representing 13.85% of all records.
-- Most patient records, 4,372 or 86.15%, were not associated with a 30-day readmission.
-- The overall recorded readmission rate was therefore approximately one in seven patient records.

-- Limitation:
-- The dataset records whether a readmission occurred but does not confirm whether the readmission was avoidable, related to the original condition or planned.
-- The analysis treats each row as a separate patient record and does not verify whether the same patient appears more than once.

-- Business question:
-- How did 30-day readmission rates vary by patient severity?

SELECT
    Severity,
    COUNT(*) AS patient_records,

    SUM(
        CASE
            WHEN Readmission_Within_30_Days = 'Yes' THEN 1
            ELSE 0
        END
    ) AS readmitted_records,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Readmission_Within_30_Days = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS readmission_percentage

FROM hospital_operations_clean
WHERE Severity IS NOT NULL
  AND Readmission_Within_30_Days IS NOT NULL
GROUP BY Severity
ORDER BY readmission_percentage DESC;

-- Finding:
-- Severe cases recorded the highest 30-day readmission rate at 19.18%, with 206 readmitted records.
-- Critical cases recorded the second-highest readmission rate at 16.34%, followed by Moderate cases at 12.62%.
-- Mild cases recorded the lowest readmission rate at 11.33%.
-- Readmission rates were generally higher among patients with greater recorded severity, although Severe cases had a higher rate than Critical cases.

-- Limitation:
-- The analysis shows an association between severity and readmission but does not establish that severity caused the readmission.
-- The results do not account for differences in disease, department, treatment, discharge planning or length of stay.

-- Business question:
-- Which diseases recorded the highest 30-day readmission rates?

SELECT
    Disease,
    COUNT(*) AS patient_records,

    SUM(
        CASE
            WHEN Readmission_Within_30_Days = 'Yes' THEN 1
            ELSE 0
        END
    ) AS readmitted_records,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Readmission_Within_30_Days = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS readmission_percentage

FROM hospital_operations_clean
WHERE Disease IS NOT NULL
  AND Readmission_Within_30_Days IS NOT NULL
GROUP BY Disease
ORDER BY readmission_percentage DESC;

-- Finding:
-- Stroke recorded the highest 30-day readmission rate at 20.60%, with 48 readmitted records from 233 patient records.
-- Bronchitis recorded the second-highest readmission rate at 17.14%, followed by Liver Disease at 16.51%.
-- Food Poisoning recorded the lowest readmission rate at 9.36%, despite having the highest overall patient volume among the diseases analysed.
-- The results show that high patient volume does not necessarily correspond to a high readmission rate.

-- Limitation:
-- Readmission rates are based on record counts and do not confirm whether repeat records belong to the same patient.
-- The analysis does not explain whether readmissions were related to the original condition, planned or potentially avoidable.

-- Business question:
-- Which departments recorded the highest 30-day readmission rates?

SELECT
    Department,
    COUNT(*) AS patient_records,

    SUM(
        CASE
            WHEN Readmission_Within_30_Days = 'Yes' THEN 1
            ELSE 0
        END
    ) AS readmitted_records,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Readmission_Within_30_Days = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS readmission_percentage

FROM hospital_operations_clean
WHERE Department IS NOT NULL
  AND Readmission_Within_30_Days IS NOT NULL
GROUP BY Department
ORDER BY readmission_percentage DESC;

-- Finding:
-- ICU recorded the highest 30-day readmission rate at 17.57%, with 171 readmitted records from 973 patient records.
-- Neurology recorded the second-highest readmission rate at 14.19%, followed by Cardiology at 13.88% and Pulmonology at 13.81%.
-- Nephrology recorded the lowest readmission rate at 10.49%, followed closely by Orthopedics at 10.56%.
-- General Medicine recorded the highest number of readmitted records at 198, but its readmission rate of 13.18% was lower than the rate recorded in ICU.
-- The results show that departments with the highest readmission counts do not necessarily have the highest readmission rates.

-- Limitation:
-- Department-level readmission rates may be influenced by differences in patient severity, disease mix and treatment complexity.
-- The analysis does not determine whether readmissions were planned, related to the original condition or potentially avoidable.

-- =========================================================
-- 12. FINAL ANALYSIS SUMMARY
-- =========================================================

-- Summary:
-- The dataset contains 5,075 patient records covering the period from 1 January 2023 to 31 December 2024.
-- Patient demand remained relatively stable across the reporting period, with monthly activity generally ranging between approximately 190 and 230 records.
-- General Medicine recorded the highest patient volume with 1,502 records, while Food Poisoning was the most frequently recorded disease with 374 records.
-- Patient demand was evenly distributed across the week, with only a small difference between the highest and lowest daily volumes.
-- The average length of stay was 5.10 days, with most records concentrated at the lower end of the distribution.
-- OPD activity was overwhelmingly same-day, although unusual OPD stays of 60 and 120 days were identified and flagged for validation.
-- Beds were the most frequently required resource, followed by oxygen, ICU services and ventilators.
-- ICU recorded the highest overall resource intensity, while Pulmonology also showed substantial oxygen demand.
-- Average recorded bed occupancy was 66.25%, while average recorded ICU occupancy was 52.67%.
-- No records showed occupied beds or ICU beds exceeding recorded available capacity.
-- Resource intensity increased as patient severity increased, with Critical cases recording the highest ICU, oxygen and ventilator requirement percentages.
-- Average length of stay also increased with severity, rising from 0.80 days for Mild cases to 20.24 days for Critical cases.
-- The overall 30-day readmission rate was 13.85%.
-- Severe cases recorded the highest readmission rate by severity at 19.18%.
-- Stroke recorded the highest readmission rate by disease at 20.60%, while ICU recorded the highest departmental readmission rate at 17.57%.

-- Overall limitation:
-- The dataset appears to combine patient-level records with hospital-wide operational measures, so capacity fields may be repeated across multiple rows.
-- The analysis identifies patterns and associations but does not establish causation.
-- Several measures, including readmission, resource use and occupancy, lack detailed timing, duration and clinical context.
-- Unusual records have been retained unless there is sufficient evidence that they are incorrect.