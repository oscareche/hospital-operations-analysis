-- =====================================================
-- HOSPITAL OPERATIONS ANALYSIS
-- 01 - DATABASE SETUP
-- =====================================================

CREATE DATABASE IF NOT EXISTS hospital_operations;

USE hospital_operations;

DROP TABLE IF EXISTS hospital_operations_raw;

-- SQL automatically created the databses with the incorrect data type
-- I have had to run a query to drop the table and create a new hospital ops data
-- table with fields data type as text because are unsure as to what data type the raw table is in

CREATE TABLE hospital_operations_raw (
    Patient_ID TEXT,
    Visit_Date TEXT,
    Age TEXT,
    Gender TEXT,
    Disease TEXT,
    Severity TEXT,
    Admission_Type TEXT,
    Length_of_Stay TEXT,
    Bed_Required TEXT,
    ICU_Required TEXT,
    Oxygen_Required TEXT,
    Ventilator_Required TEXT,
    Total_Beds_Available TEXT,
    Beds_Occupied TEXT,
    ICU_Beds_Available TEXT,
    ICU_Beds_Occupied TEXT,
    Oxygen_Units_Used TEXT,
    Month TEXT,
    Season TEXT,
    Day_of_Week TEXT,
    Department TEXT,
    Readmission_Within_30_Days TEXT
);

DESCRIBE hospital_operations_raw;

-- Validate the number of imported records.
SELECT 
    COUNT(*) AS Raw_Row_Count
FROM
    hospital_operations_raw;

-- Inspect the imported records.
SELECT 
    *
FROM
    hospital_operations_raw
LIMIT 10;