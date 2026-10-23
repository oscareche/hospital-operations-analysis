# Hospital Operations Analysis

## Overview

This project uses SQL to analyse hospital visit data, including patient and admission details, recorded resource requirements, and capacity measures.

The workflow begins with profiling the raw data and documenting data-quality issues before defining cleaning rules and conducting exploratory analysis. The analysis focuses on descriptive operational patterns and interprets capacity measures in light of the dataset's limitations.

## Business Objective

The objective is to analyse hospital visit demand and recorded resource requirements, assess what available capacity measures suggest about potential operational pressure, and provide descriptive evidence to support resource allocation and capacity planning.

### Key Business Questions

- Which departments, diseases and admission types account for the highest hospital visit volumes?
- How does visit volume vary by month and day of the week, and what seasonal patterns are supported by the data?
- How does length of stay vary by department, admission type and severity?
- How do recorded bed, ICU, oxygen and ventilator requirements vary by department, severity, admission type and disease?
- What do the recorded bed and ICU occupancy measures indicate about potential capacity pressure?
- What patterns appear in recorded 30-day readmissions by disease, department and severity?

Data-quality checks will identify issues that could affect the reliability of these measures. Capacity and resource-use results will be interpreted in light of the fields' reporting level and the dataset's limitations.

## Dataset Summary

The cleaned dataset contains 5,075 patient records covering the period from 1 January 2023 to 31 December 2024.

The dataset includes information on:

- patient demographics;
- disease and severity;
- admission type;
- department;
- length of stay;
- bed, ICU, oxygen and ventilator requirements;
- hospital bed and ICU capacity;
- 30-day readmission status.

## Tools Used

- MySQL
- MySQL Workbench
- Git
- GitHub
- Power BI

## Project Workflow

### 1. Data Profiling

The raw dataset was reviewed to identify:

- missing values;
- inconsistent date formats;
- invalid numeric values;
- duplicate patient identifiers;
- inconsistent categorical values;
- operational inconsistencies.

### 2. Data Cleaning

The cleaning process included:

- converting multiple date formats into a consistent date field;
- converting blank text values to `NULL`;
- trimming whitespace from categorical fields;
- converting numeric text fields into numeric data types;
- preserving unusual values where there was insufficient evidence to remove them.

### 3. Data Validation

Validation checks confirmed:

- 5,075 records were retained in the cleaned table;
- no duplicate Patient_ID values were found;
- no records showed occupied beds exceeding available beds;
- no records showed occupied ICU beds exceeding available ICU beds;
- unusual resource combinations and outliers were retained and documented.

### 4. Exploratory Analysis

The SQL analysis covered:

- overall patient activity;
- patient demand by department and disease;
- monthly and weekly demand patterns;
- length-of-stay distribution;
- OPD stay patterns;
- resource requirements;
- bed and ICU occupancy;
- severity and resource intensity;
- 30-day readmissions.

## Key Findings

- General Medicine recorded the highest patient volume with 1,502 records.
- Food Poisoning was the most frequently recorded disease with 374 records.
- Patient demand remained relatively stable across the reporting period.
- Wednesday recorded the highest patient volume, although demand was evenly distributed across the week.
- The average length of stay was 5.10 days.
- OPD activity was overwhelmingly same-day, although unusual OPD stays of 60 and 120 days were identified.
- Beds were required for 66.03% of patient records.
- Oxygen was required for 30.72% of records.
- ICU services were required for 19.47% of records.
- Ventilators were required for 6.17% of records.
- Average bed occupancy was 66.25%.
- Average ICU occupancy was 52.67%.
- No recorded observation exceeded available bed or ICU capacity.
- Critical patients recorded the highest ICU, oxygen and ventilator requirement percentages.
- Severe patients recorded the highest 30-day readmission rate by severity at 19.18%.
- Stroke recorded the highest readmission rate by disease at 20.60%.
- ICU recorded the highest departmental readmission rate at 17.57%.

## Limitations

- The dataset appears to combine patient-level records with hospital-wide operational measures.
- Capacity values may therefore be repeated across multiple patient records.
- The analysis identifies patterns and associations but does not establish causation.
- Resource requirement fields do not show duration of use.
- Readmission records do not confirm whether the return visit was planned, avoidable or related to the original condition.
- Unusual records were retained unless there was sufficient evidence that they were incorrect.

## Repository Structure

```text
hospital-operations-analysis/
│
├── data/
│   ├── raw/
│   └── cleaned/
│
├── documentation/
│   ├── data_dictionary.csv
│   ├── data_quality_log.md
│   └── project_brief.md
│
├── sql/
│   ├── 01_data_profiling.sql
│   ├── 02_data_cleaning.sql
│   ├── 03_cleaning_validation.sql
│   └── 04_exploratory_analysis.sql
│
├── powerbi/
├── images/
├── exports/
├── python/
└── README.md