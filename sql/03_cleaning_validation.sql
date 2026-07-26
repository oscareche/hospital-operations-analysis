/*
Project: Hospital Operations Analysis
Script: 03_cleaning_validation.sql
Purpose: Validate the cleaned dataset and identify remaining quality issues.
Source table: hospital_operations_clean
Important: This script checks the data but does not modify it.
*/

USE hospital_operations;

-- =========================================================
-- 1. DUPLICATE PATIENT IDS
-- Check whether the same Patient_ID appears more than once.
-- Multiple visits may be valid, so this is an investigation
-- rather than an automatic error.
-- =========================================================

SELECT
    Patient_ID,
    COUNT(*) AS number_of_records
FROM hospital_operations_clean
GROUP BY Patient_ID
HAVING COUNT(*) > 1
ORDER BY number_of_records DESC;

-- Validation result:
-- No duplicate Patient_ID values were found.
-- Each patient appears once in the cleaned dataset.

-- =========================================================
-- 2. AGE VALIDATION
-- Identify missing, zero, negative, or unusually high ages.
-- =========================================================

SELECT *
FROM hospital_operations_clean
WHERE Age IS NULL
   OR Age = 0
   OR Age > 120;
   
   -- Review records where age is recorded as zero.
-- Age 0 may represent patients younger than one year.

SELECT
    Patient_ID,
    Age,
    Disease,
    Severity,
    Admission_Type,
    Department,
    Length_of_Stay
FROM hospital_operations_clean
WHERE Age = 0;

-- Validation result:
-- Two records have Age = 0.
-- Both are assigned to General Medicine, with diagnoses of dengue
-- and influenza. The available fields do not confirm whether these
-- patients are infants or whether age was entered incorrectly.
-- The records have been retained and flagged for source-system review.

SELECT 
    *
FROM
    hospital_operations_clean
WHERE
    Beds_Occupied > Total_Beds_Available
        OR ICU_Beds_Occupied > ICU_Beds_AvailableZ;
   
-- Validation result:
-- No records were found where occupied beds exceeded
-- the total number of beds available.
-- No ICU records exceeded ICU bed capacity.

-- =========================================================
-- 3. ICU REQUIREMENT CONSISTENCY
-- Check whether patients marked as requiring ICU care
-- are also recorded as requiring a bed.
-- =========================================================

SELECT *
FROM hospital_operations_clean
WHERE ICU_Required = 'Yes'
  AND Bed_Required <> 'Yes';
  
SELECT
    ICU_Required,
    Bed_Required,
    COUNT(*) AS number_of_records
FROM hospital_operations_clean
GROUP BY ICU_Required, Bed_Required
ORDER BY ICU_Required, Bed_Required;

-- Validation result:
-- 94 records are marked as ICU_Required = 'Yes'
-- while Bed_Required = 'No'.
-- This is a potential logical inconsistency because ICU care
-- would normally require a bed.
-- The records have been retained and flagged for review.

-- =========================================================
-- 4. OXYGEN REQUIREMENT CONSISTENCY
-- Identify records where oxygen units were used even though
-- Oxygen_Required is not marked as Yes.
-- =========================================================

SELECT
    Oxygen_Required,
    COUNT(*) AS number_of_records
FROM hospital_operations_clean
WHERE Oxygen_Units_Used > 0
GROUP BY Oxygen_Required;

-- Check whether Oxygen_Units_Used is repeated across patients
-- recorded on the same visit date.

SELECT
    Visit_Date,
    COUNT(*) AS patient_records,
    COUNT(DISTINCT Oxygen_Units_Used) AS distinct_oxygen_values
FROM hospital_operations_clean
GROUP BY Visit_Date
HAVING COUNT(*) > 1
ORDER BY patient_records DESC
LIMIT 10;

-- Validation result:
-- 2,877 records have Oxygen_Required = 'No' while
-- Oxygen_Units_Used is greater than zero.
-- Oxygen usage varies within the same visit date, so the field does
-- not appear to be a single daily hospital-wide measure.
-- However, the dataset does not clearly define whether usage is
-- patient-level, department-level, or another operational measure.
-- No values were changed; the inconsistency is flagged for review.

SELECT
    Patient_ID,
    Visit_Date,
    Disease,
    Department
FROM hospital_operations_clean
WHERE Visit_Date IS NULL;

SELECT
    c.Patient_ID,
    r.Visit_Date AS raw_visit_date,
    c.Visit_Date AS cleaned_visit_date,
    c.Disease,
    c.Department
FROM hospital_operations_clean AS c
JOIN hospital_operations_raw AS r
    ON c.Patient_ID = r.Patient_ID
WHERE c.Visit_Date IS NULL;

-- =========================================================
-- 5. VENTILATOR CONSISTENCY
-- Check whether patients marked as requiring a ventilator
-- are also marked as requiring oxygen.
-- =========================================================

SELECT
    Ventilator_Required,
    Oxygen_Required,
    COUNT(*) AS number_of_records
FROM hospital_operations_clean
GROUP BY Ventilator_Required, Oxygen_Required
ORDER BY Ventilator_Required, Oxygen_Required;

-- Validation result:
-- 62 records have Ventilator_Required = 'Yes'
-- while Oxygen_Required = 'No'.
-- This is a potential logical inconsistency.
-- The records have been retained and flagged for source-system review.

-- =========================================================
-- 6. CATEGORY VALIDATION
-- Review the distinct values used in key categorical fields.
-- This helps identify spelling variations, blanks, or unexpected labels.
-- =========================================================

SELECT 'Gender' AS field_name, Gender AS field_value, COUNT(*) AS number_of_records
FROM hospital_operations_clean
GROUP BY Gender

UNION ALL

SELECT 'Severity', Severity, COUNT(*)
FROM hospital_operations_clean
GROUP BY Severity

UNION ALL

SELECT 'Admission_Type', Admission_Type, COUNT(*)
FROM hospital_operations_clean
GROUP BY Admission_Type

UNION ALL

SELECT 'Department', Department, COUNT(*)
FROM hospital_operations_clean
GROUP BY Department

ORDER BY field_name, field_value;

-- Validation result:
-- Leading and trailing spaces were removed successfully.
-- Category labels are now standardised.
-- 77 records have a missing Department.
-- 103 records have a missing Gender.

SELECT
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS missing_gender,
    SUM(CASE WHEN Disease IS NULL THEN 1 ELSE 0 END) AS missing_disease,
    SUM(CASE WHEN Severity IS NULL THEN 1 ELSE 0 END) AS missing_severity,
    SUM(CASE WHEN Admission_Type IS NULL THEN 1 ELSE 0 END) AS missing_admission_type,
    SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END) AS missing_department
FROM hospital_operations_clean;

-- Validation result:
-- 103 records have a missing Gender.
-- 77 records have a missing Department.
-- Disease, Severity and Admission_Type contain no missing values.
-- Missing Gender and Department values were retained as NULL
-- rather than being guessed or imputed.