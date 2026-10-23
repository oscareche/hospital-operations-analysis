# Hospital Operations Analysis Project

## 1. Business Context
Hospital operations teams need clear visibility into how patient demand translates into the use of beds, ICU capacity, oxygen, ventilation and other critical resources.

Without a structured view of demand and resource utilisation, it can be difficult to identify where operational pressure is concentrated, how resource requirements vary across departments, and where capacity planning may need greater attention.

This project analyses historical hospital visit data to identify operational patterns that could support more informed capacity-planning and resource-management decisions.


## 2. Business Objectives
The objective is to analyze hospital visit demand and recorded resource requirements, assess what the available capacity measures suggest about potential operational pressure, and provide descriptive evidence to support resource allocation and capacity planning.


## 3. Key Business Questions
The analysis will focus on the following questions:

1. Which departments, diseases and admission types account for the highest hospital visit volumes?
2. How does visit volume vary by month and day of the week, and what seasonal patterns are supported by the data?
3. How does length of stay vary by department, admission type and severity?
4. How do recorded bed, ICU, oxygen and ventilator requirements vary by department and patient group?
5. What do the recorded bed and ICU occupancy measures indicate about potential capacity pressure?
6. What patterns appear in recorded 30-day readmissions by disease, department and severity?

Data-quality checks will identify issues that could affect the reliability of these measures. Capacity and resource-use results will be interpreted in light of the fields' reporting level and the dataset's limitations.


## 4. Analytical Scope

### In Scope

The analysis will examine:

- Hospital visits and admissions
- Patient demographics
- Disease and severity
- Admission type
- Department
- Length of stay
- Bed availability and occupancy
- ICU availability and occupancy
- ICU requirement
- Oxygen requirement and usage
- Ventilator requirement
- Time-based demand patterns
- 30-day readmissions

### Out of Scope

The dataset does not contain sufficient information to evaluate:

- Staffing levels or staff productivity
- Treatment effectiveness
- Financial cost or profitability
- Clinical outcomes beyond the available readmission field
- Real-time or hourly capacity utilisation
- Hospital-site comparisons
- Causal relationships between patient characteristics and outcomes

The analysis will therefore focus on descriptive and exploratory operational insights rather than causal or clinical conclusions.


## 5. Dataset

**Source:** Kaggle – Hospital Operations Dataset – Unclean Data

The imported dataset contains:

- 5,075 hospital visit records
- 22 fields

The raw data is stored in:

`hospital_operations_raw`

All raw fields are initially stored as TEXT to preserve source values before data-quality assessment and cleaning.

## 6. Dataset Grain

Each row represents one hospital visit or admission event.

A patient may appear in more than one row if they have multiple hospital visits.

Therefore:

- `COUNT(*)` represents visit or encounter volume.
- `COUNT(DISTINCT Patient_ID)` represents unique patients.

This distinction will be maintained throughout the analysis.


## 7. Data Quality Approach

The raw dataset will not be modified directly.

The workflow will be:

1. Preserve the original data in `hospital_operations_raw`.
2. Profile the raw data for missing, inconsistent, duplicate and invalid values.
3. Document data-quality findings.
4. Define cleaning rules based on analytical requirements.
5. Create a separate cleaned table.
6. Validate the cleaned dataset before analysis.

Cleaning decisions will be documented rather than applied automatically.


## 8. Analytical Deliverables

The project is expected to produce:

- Reproducible SQL scripts
- Data-quality documentation
- A validated cleaned dataset
- Exploratory analysis
- Operational KPIs
- Visualisations/dashboard
- Business findings and recommendations
- A GitHub portfolio repository documenting the analytical workflow


## 9. Success Criteria

The project will be considered successful if it:

- Produces a reproducible raw-to-clean data workflow.
- Identifies and documents material data-quality issues.
- Clearly distinguishes hospital visits from unique patients.
- Produces reliable operational metrics for demand and resource utilisation.
- Answers the agreed business questions using validated data.
- Communicates findings in a form that could support operational decision-making.


## 10. Tools

- MySQL
- VS Code
- SQLTools
- Python
- Power BI
- Git
- GitHub


## 11. Current Project Phase

**Current phase:** Raw data understanding and profiling.

The database and raw ingestion layer have been established and validated.

The next stage is to profile the fields required by the business questions before defining any cleaning rules.
