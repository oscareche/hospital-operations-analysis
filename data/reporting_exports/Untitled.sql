CREATE DATABASE hospital_operations;
USE hospital_operations;
SELECT COUNT(*) AS total_rows
FROM hospital_operations_raw;
SHOW WARNINGS;
DROP TABLE hospital_operations_raw;
DESCRIBE hospital_operations_raw;
DROP TABLE hospital_operations_raw;
CREATE TABLE hospital_operations_raw (
    Patient_ID VARCHAR(50),
    Visit_Date VARCHAR(50),
    Age VARCHAR(50),
    Gender VARCHAR(50),
    Disease VARCHAR(100),
    Severity VARCHAR(50),
    Admission_Type VARCHAR(50),
    Length_of_Stay VARCHAR(50),
    Bed_Required VARCHAR(50),
    ICU_Required VARCHAR(50),
    Oxygen_Required VARCHAR(50),
    Ventilator_Required VARCHAR(50),
    Total_Beds_Available VARCHAR(50),
    Beds_Occupied VARCHAR(50),
    ICU_Beds_Available VARCHAR(50),
    ICU_Beds_Occupied VARCHAR(50),
    Oxygen_Units_Used VARCHAR(50),
    Month VARCHAR(50),
    Season VARCHAR(50),
    Day_of_Week VARCHAR(50),
    Department VARCHAR(100),
    Readmission_Within_30_Days VARCHAR(50)
);

DESCRIBE hospital_operations_raw;
SELECT COUNT(*) AS total_rows
FROM hospital_operations_raw;
SELECT *
FROM hospital_operations_raw
LIMIT 10;
SELECT
    SUM(CASE WHEN Length_of_Stay IS NULL OR TRIM(Length_of_Stay) = '' THEN 1 ELSE 0 END) AS missing_length_of_stay,
    SUM(CASE WHEN Oxygen_Units_Used IS NULL OR TRIM(Oxygen_Units_Used) = '' THEN 1 ELSE 0 END) AS missing_oxygen_units
FROM hospital_operations_raw;

SELECT COUNT(*) AS rows_missing_both
FROM hospital_operations_raw
WHERE (Length_of_Stay IS NULL OR TRIM(Length_of_Stay) = '')
  AND (Oxygen_Units_Used IS NULL OR TRIM(Oxygen_Units_Used) = '');