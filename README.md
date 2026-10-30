# Hospital Operations Analysis

**Status:** data profiling complete and re-verified (October 2026). Cleaning, validation and analysis in progress.

## Overview

This project uses SQL to analyse hospital visit data, including patient and admission details, recorded resource requirements, and capacity measures.

The workflow begins with profiling the raw data and documenting data-quality issues before defining cleaning rules and conducting exploratory analysis. The analysis focuses on descriptive operational patterns and interprets capacity measures in light of the dataset's limitations.

## Business Objective

The objective is to analyse hospital visit demand and recorded resource requirements, assess what available capacity measures suggest about potential operational pressure, and provide descriptive evidence to support resource allocation and capacity planning.

### Key Business Questions

1. Which departments, diseases and admission types account for the highest hospital visit volumes?
2. How does visit volume vary by month and day of the week, and what seasonal patterns are supported by the data?
3. How does length of stay vary by department, admission type and severity?
4. How do recorded bed, ICU, oxygen and ventilator requirements vary by department, severity and admission type?
5. What do the recorded bed and ICU occupancy measures indicate about potential capacity pressure?
6. What patterns appear in recorded 30-day readmissions by disease, department and severity?

## Dataset

**Source:** Kaggle – Hospital Operations Dataset – Unclean Data

- **Raw:** 5,075 rows and 22 fields, imported into MySQL with every field stored as `TEXT` so no source values were altered on import.
- **Period:** visits from 1 January 2023 to 31 December 2024.
- **Duplicates:** 75 rows are exact copies. Once they are removed, 5,000 visits remain.
- **Grain:** one row per hospital visit. After de-duplication, every visit has a distinct `Patient_ID`.

## Workflow

1. [`01_database_setup.sql`](sql/01_database_setup.sql): creates the database and an all-`TEXT` raw table.
2. [`02_raw_data_profiling.sql`](sql/02_raw_data_profiling.sql): checks the raw data for duplicates, blanks, inconsistent labels, date formats, unusual values and contradictions.
3. [`03_data_cleaning.sql`](sql/03_data_cleaning.sql): builds a separate clean table without changing the raw data.
4. [`04_cleaning_validation.sql`](sql/04_cleaning_validation.sql): confirms the cleaning worked as intended.
5. [`05_exploratory_analysis.sql`](sql/05_exploratory_analysis.sql): answers the six business questions.

Every data-quality issue, its evidence and the decision taken are recorded in the [data quality log](documentation/data_quality_log.md).

## Tools Used

- MySQL and MySQL Workbench
- VS Code with SQLTools
- Git and GitHub