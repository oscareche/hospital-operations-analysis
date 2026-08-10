# Hospital Operations Data Quality Log

This log records material data-quality issues identified during data ingestion, raw profiling, cleaning and validation.

The project is currently being revisited from the raw-data stage. Findings from the previous project version are retained for traceability but are marked for revalidation until they are confirmed using the current raw dataset.

| Issue ID | Stage | Finding | Evidence | Impact | Action / Decision | Status |
|---|---|---|---|---|---|---|
| DQ-001 | Import validation | Initial MySQL import loaded fewer records than the source dataset | The source CSV contained 5,075 data records, while the initial MySQL Workbench import loaded 4,928. Investigation showed that Workbench had automatically inferred numeric datatypes for several fields rather than preserving the raw source values as text. | The initial raw table was incomplete and could not be relied upon for profiling or analysis. Automatic type conversion also risked transforming or rejecting source values before data-quality assessment. | The initial raw table was removed. `hospital_operations_raw` was manually recreated with all 22 fields defined as `TEXT`, and the CSV was imported into the existing table so Workbench could not override the datatypes. The final import contained all 5,075 data records. | Resolved |
| DQ-002 | Raw data profiling | 75 distinct `Patient_ID` values occur more than once | Initial raw profiling identified 75 distinct `Patient_ID` values with more than one record. No `Patient_ID` currently appears more than twice. | Repeated IDs may represent legitimate repeat hospital visits rather than duplicate records. This affects whether row counts should be interpreted as hospital encounters or unique patients. | No records will be removed at this stage. Repeated `Patient_ID` records will be compared using `Visit_Date` and other encounter-level fields to determine whether they represent separate visits or genuine duplicate records. | Under investigation |
| DQ-003 | Historical cleaning validation | Two records were previously identified with `Age = 0` | In the previous project version, two records with `Age = 0` were identified. Both were associated with General Medicine, with diagnoses of dengue and influenza. The source data does not establish whether age 0 represents valid infant patients or data-entry errors. | If confirmed, age-based analysis could be slightly distorted or require separate treatment of these records. | Re-run age profiling against the current raw dataset before deciding whether the values should be retained, corrected, excluded or flagged. | To be revalidated |
| DQ-004 | Historical cleaning validation | 94 records were previously identified with `ICU_Required = Yes` and `Bed_Required = No` | The previous project version identified 94 records with this combination. | The combination may indicate a logical inconsistency in the source data and could affect interpretation of ICU and bed-demand metrics. | Re-run the logical consistency check against the current raw dataset. If confirmed, retain the source values unless a defensible business rule or source-system clarification supports correction. | To be revalidated |
| DQ-005 | Historical cleaning validation | 62 records were previously identified with `Ventilator_Required = Yes` and `Oxygen_Required = No` | The previous project version identified 62 records with this combination. | The combination may indicate inconsistent respiratory-support fields and could affect oxygen and ventilator analysis. | Re-run the logical consistency check against the current raw dataset. Do not modify the records without evidence supporting a correction. | To be revalidated |
| DQ-006 | Historical cleaning validation | 103 records were previously identified with missing `Gender` and 77 with missing `Department` | In the previous cleaned dataset, blank text values were standardised to `NULL`. | Missing values could reduce the completeness of gender- and department-level analysis and may require an Unknown or Missing category in reporting. | Re-profile missing and blank values in the current raw dataset. Cleaning rules will be defined only after the counts and raw representations are confirmed. | To be revalidated |

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

**Project phase:** Raw data understanding and profiling.

**Raw table:** `hospital_operations_raw`

**Imported data records:** 5,075

**Raw fields:** 22

**Raw datatype approach:** All fields stored as `TEXT` to preserve the original source values before profiling and cleaning.

The next stage is to continue profiling the raw dataset and update this log only when a material data-quality issue is supported by SQL evidence.