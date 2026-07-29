/*
Project: Hospital Operations Analysis
Script: 05_reporting_views.sql
Purpose: Create reusable reporting views for Power BI.
Source table: hospital_operations_clean
*/

USE hospital_operations;


-- =========================================================
-- 1. HEADLINE KPI SUMMARY
-- =========================================================

-- Purpose:
-- Create a single-row view containing the main hospital operation KPIs for Power BI dashboard cards.

CREATE OR REPLACE VIEW vw_hospital_kpi_summary AS
SELECT
    COUNT(*) AS total_patient_records,
    COUNT(DISTINCT Visit_Date) AS total_visit_dates,
    MIN(Visit_Date) AS earliest_visit_date,
    MAX(Visit_Date) AS latest_visit_date,
    ROUND(AVG(Length_of_Stay), 2) AS average_length_of_stay,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Readmission_Within_30_Days = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS readmission_percentage,

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

SELECT *
FROM vw_hospital_kpi_summary;

-- =========================================================
-- 2. MONTHLY PATIENT DEMAND
-- =========================================================

-- Purpose:
-- Create a monthly patient demand view for trend analysis in Power BI.

CREATE OR REPLACE VIEW vw_monthly_patient_demand AS
SELECT
    YEAR(Visit_Date) AS visit_year,
    MONTH(Visit_Date) AS visit_month,
    MONTHNAME(Visit_Date) AS month_name,
    DATE_FORMAT(Visit_Date, '%Y-%m-01') AS month_start_date,
    COUNT(*) AS patient_records
FROM hospital_operations_clean
WHERE Visit_Date IS NOT NULL
GROUP BY
    YEAR(Visit_Date),
    MONTH(Visit_Date),
    MONTHNAME(Visit_Date),
    DATE_FORMAT(Visit_Date, '%Y-%m-01')
ORDER BY
    visit_year,
    visit_month;

    -- =========================================================
-- 3. DEPARTMENT PERFORMANCE
-- =========================================================

-- Purpose:
-- Create a department-level view containing patient volume, length of stay, resource requirements and readmission rates for Power BI.

CREATE OR REPLACE VIEW vw_department_performance AS
SELECT
    Department,
    COUNT(*) AS patient_records,
    ROUND(AVG(Length_of_Stay), 2) AS average_length_of_stay,

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
    ) AS ventilator_required_records,

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
GROUP BY Department;

-- =========================================================
-- 4. SEVERITY AND RESOURCE REQUIREMENTS
-- =========================================================

-- Purpose:
-- Create a severity-level view containing patient volume, length of stay and resource requirement percentages for Power BI.

CREATE OR REPLACE VIEW vw_severity_resource_summary AS
SELECT
    Severity,
    COUNT(*) AS patient_records,
    ROUND(AVG(Length_of_Stay), 2) AS average_length_of_stay,

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
GROUP BY Severity;

-- =========================================================
-- 5. READMISSION SUMMARY
-- =========================================================

-- Purpose:
-- Create a department-level readmission view for comparison in Power BI.

CREATE OR REPLACE VIEW vw_readmission_summary AS
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
GROUP BY Department;

SELECT *
FROM vw_readmission_summary
ORDER BY readmission_percentage DESC;