# Data Quality Log

| Issue ID | Stage | Finding | Evidence | Impact | Planned action |
|---|---|---|---|---|---|
| DQ-001 | Import validation | Initial MySQL import loaded fewer records than the source CSV | CSV contained 5,075 data rows, but the first import loaded 4,928. Investigation found 147 rows with blank values in numeric fields, mainly `Oxygen_Units_Used` and `Length_of_Stay` | The initial table was incomplete and unsuitable for analysis | Resolved by manually creating the raw table with all columns stored as text and reimporting all 5,075 records |

| DQ-002 | Cleaning validation | Two records contain Age = 0 | Both records are in General Medicine, with diagnoses of dengue and influenza. The dataset does not confirm whether age 0 represents infants or an entry error | Age-based analysis could be slightly distorted | Retained in the cleaned dataset and flagged for source-system clarification |

| DQ-003 | Cleaning validation | 94 records have ICU_Required = Yes and Bed_Required = No | This combination may be logically inconsistent because ICU care would normally require a bed | ICU-related analysis may be unreliable for these records | Retained and flagged for source-system review |

| DQ-004 | Cleaning validation | 62 records have Ventilator_Required = Yes and Oxygen_Required = No | Ventilator support would normally involve oxygen support, so this combination may be inconsistent | Respiratory-support analysis may be unreliable for these records | Retained and flagged for source-system review |

| DQ-005 | Cleaning validation | 103 records have missing Gender and 77 records have missing Department | Blank text values were standardised to NULL during cleaning | Gender- and department-level analysis will exclude or separately group these records | Retained as NULL and documented; no assumptions were made |