# Hospital Operations Analysis

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

- **Raw:** 5,075 rows, 22 fields, imported into MySQL with every field stored as `TEXT` so no source values were altered on import.
- **Cleaned:** 5,000 visits from 1 January 2023 to 31 December 2024, after removing 75 exact duplicate rows.
- **Grain:** one row per hospital visit. After de-duplication, every visit has a distinct `Patient_ID`.

## Tools Used

- MySQL and MySQL Workbench
- VS Code with SQLTools
- Git and GitHub
