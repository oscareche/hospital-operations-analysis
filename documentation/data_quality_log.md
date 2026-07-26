# Data Quality Log

| Issue ID | Stage | Finding | Evidence | Impact | Planned action |
|---|---|---|---|---|---|
| DQ-001 | Import validation | Initial MySQL import loaded fewer records than the source CSV | CSV contained 5,075 data rows, but the first import loaded 4,928. Investigation found 147 rows with blank values in numeric fields, mainly `Oxygen_Units_Used` and `Length_of_Stay` | The initial table was incomplete and unsuitable for analysis | Resolved by manually creating the raw table with all columns stored as text and reimporting all 5,075 records |