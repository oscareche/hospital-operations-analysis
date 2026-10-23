# Hospital Operations Data Quality Log

This log records material data-quality issues identified during data ingestion, raw profiling, cleaning and validation.

All findings below were reproduced against the current raw dataset on 23 October 2026.

| Issue ID | Stage | Finding | Evidence | Impact | Action / Decision | Status |
|---|---|---|---|---|---|---|
| DQ-001 | Import validation | Initial MySQL import loaded fewer records than the source dataset | The source CSV contained 5,075 data records, while the initial MySQL Workbench import loaded 4,928. Investigation showed that Workbench had automatically inferred numeric datatypes for several fields rather than preserving the raw source values as text. | The initial raw table was incomplete and could not be relied upon for profiling or analysis. Automatic type conversion also risked transforming or rejecting source values before data-quality assessment. | The initial raw table was removed. `hospital_operations_raw` was manually recreated with all 22 fields defined as `TEXT`, and the CSV was imported into the existing table so Workbench could not override the datatypes. The final import contained all 5,075 data records. | Resolved |
| DQ-002 | Raw data profiling | 75 distinct `Patient_ID` values occur more than once, and all 75 are exact duplicate rows | The exact-duplicate check in `02_raw_data_profiling.sql` returned 75 duplicate groups and 75 excess rows. Every repeated `Patient_ID` matches its pair on all 22 fields. | The copies would double-count 75 visits and every measure built on them. | Removed in `03_data_cleaning.sql` with `ROW_NUMBER()` over all 22 fields, keeping one row per group. The clean table holds 5,000 visits with 5,000 distinct `Patient_ID` values. | Resolved |
| DQ-003 | Raw data profiling | 8 records have an implausible or uncertain age | 2 records have `Age = 0`, 1 has `Age = 110` and 5 have `Age = 120`. The source data does not show whether age 0 means an infant or an entry error. | Age-based analysis could be distorted at the extremes. | Retained and flagged with `flag_age_review` (age 0 or over 105). Age is not used in the current business questions. | Flagged |
| DQ-004 | Raw data profiling | `ICU_Required = Yes` with `Bed_Required = No` | 94 raw records, 93 after duplicate removal. | A logical inconsistency that affects how ICU and bed demand are read together. | Retained and flagged with `flag_icu_without_bed`. Bed and ICU rates are reported separately, as recorded. | Flagged |
| DQ-005 | Raw data profiling | `Ventilator_Required = Yes` with `Oxygen_Required = No` | 62 raw records, 61 after duplicate removal. | Inconsistent respiratory-support fields that affect oxygen and ventilator analysis. | Retained and flagged with `flag_ventilator_without_oxygen`. | Flagged |
| DQ-006 | Raw data profiling | Blank values in four fields | Raw blanks: `Gender` 103, `Department` 77, `Length_of_Stay` 50, `Oxygen_Units_Used` 100. After duplicate removal: 100, 75, 50 and 100. | Reduces completeness of gender, department and stay analysis. | Converted to `NULL`. Department analysis reports these visits as `Unknown`, and stay averages exclude them. | Resolved |
| DQ-007 | Raw data profiling | Inconsistent category labels | `Gender`, `Severity`, `Admission_Type`, `Day_of_Week`, `Department` and `Readmission_Within_30_Days` contain case and whitespace variants such as `MALE`, ` Male` and `icu`. `Disease` and `Season` are consistent. | Variants split one category into several groups. | Trimmed and mapped to one canonical label per value with explicit `CASE` mappings. | Resolved |
| DQ-008 | Raw data profiling | `Visit_Date` uses three formats | 5,001 `YYYY-MM-DD`, 49 `DD-MM-YYYY` and 25 `YYYY/MM/DD`. All parse to valid dates between 2023-01-01 and 2024-12-31. | Unconverted text dates cannot be sorted or grouped by period. | Converted to `DATE` with `STR_TO_DATE` per format. | Resolved |
| DQ-009 | Raw data profiling | `Month` disagrees with `Visit_Date` in 13 records | 13 records have a `Month` value that differs from the month of `Visit_Date`. `Day_of_Week` and `Season` agree with `Visit_Date` in every record. | Monthly analysis on the source `Month` field would misplace these visits. | `visit_month`, `visit_day_of_week` and `visit_season` are derived from `visit_date`. The source mismatch is kept as `flag_source_month_mismatch`. | Resolved |
| DQ-010 | Raw data profiling | OPD visits with multi-day stays, and very long stays | 52 OPD visits record a stay above 0 days (up to 120). 6 visits record stays of 60 days or more. | Inflates average stay, especially for OPD, where visits are expected to be same-day. | Retained and flagged with `flag_opd_with_stay` and `flag_long_stay`. Stay averages exclude long stays and focus on Inpatient and Emergency visits. | Flagged |
| DQ-011 | Raw data profiling | `Oxygen_Units_Used` does not behave like a visit-level measure | 2,876 visits with `Oxygen_Required = No` record oxygen units above 0. 6 records have values of 500, 800 or 999, far above the rest (max 390). | Patient-level oxygen consumption cannot be measured reliably. | Retained. Extreme values flagged with `flag_oxygen_units_extreme`. Oxygen analysis uses `oxygen_required` only. | Flagged |

## Current Data Quality Approach

The current project revision follows these principles:

1. The raw table will remain unchanged after ingestion.
2. Data-quality issues will be quantified before cleaning rules are defined.
3. Repeated patient identifiers will not automatically be treated as duplicate records.
4. Missing, invalid and inconsistent values will be documented before transformation.
5. Historical findings from the previous project version will not be assumed to remain valid until they are reproduced against the current raw dataset.
6. Cleaning decisions will be based on the business objective and analytical requirements rather than applying transformations to every field automatically.
7. Where the dataset does not provide enough evidence to correct a value, the value will be retained or flagged rather than replaced using an unsupported assumption.

## Current Status

**Project phase:** Exploratory analysis complete.

**Raw table:** `hospital_operations_raw` (5,075 rows, 22 fields, all `TEXT`, unchanged)

**Clean table:** `hospital_operations_clean` (5,000 visits), built by `03_data_cleaning.sql` and checked by `04_cleaning_validation.sql`.
