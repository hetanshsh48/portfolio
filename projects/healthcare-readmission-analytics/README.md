# Healthcare Readmission & Operations Analytics (End-to-End)

## 1) Business Problem
Hospital leaders want to reduce 30-day readmissions while controlling cost per discharge and protecting quality scores that impact CMS reimbursement. This project builds an end-to-end analytics workflow to identify facilities, service lines, and patient cohorts driving readmissions, and to highlight operational levers for improvement.

**Stakeholders**
- Chief Medical Officer (CMO)
- VP of Clinical Operations
- Finance & Revenue Cycle leadership
- Quality Improvement (QI) team

**Business Goals**
- Reduce 30-day readmission rate by 2–3% in high-risk cohorts.
- Improve hospital quality score percentile rank.
- Lower avoidable cost per discharge.

**KPIs**
- 30-Day Readmission Rate
- Risk-Adjusted Readmission Index
- Cost per Discharge
- Average Length of Stay (ALOS)
- Mortality Rate
- CMS Payment Penalty Exposure

---

## 2) Dataset (Public)
**Primary Source**: CMS Hospital Readmissions Reduction Program (HRRP) & Hospital General Information data.

**Suggested public files (CSV)**
- `Hospital_General_Information.csv`
- `Hospital_Readmissions_Reduction_Program.csv`
- `Hospital_Value_Based_Purchasing.csv` (optional)

Download data from: https://data.cms.gov/provider-data

### Schema Overview & Relationships
- **Hospital General Information** provides hospital attributes (name, address, type, ownership, etc.).
- **HRRP** provides readmission measures and penalty flags.
- **Value-Based Purchasing** provides quality performance details (optional).

### Star Schema
**Fact Table**: `fact_readmissions`

**Dimensions**:
- `dim_hospital`
- `dim_geography`
- `dim_measure`
- `dim_time`

The star schema supports time-based KPI trending and hospital segmentation by region, ownership, and type.

---

## 3) Data Engineering / ETL
Python scripts in `etl/` implement ingestion, cleaning, validation, and feature engineering.

### Step-by-step
1. **Ingest** raw CMS CSVs into a staging dataframe.
2. **Clean & Validate** critical columns (IDs, dates, numeric measures).
3. **Feature Engineering**: derive risk flags, normalize measures, create surrogate keys.
4. **Persist** cleaned dimension and fact tables to `/data/processed`.
5. **Load** tables into local SQL (SQLite or Postgres).

### Files
- `etl/ingest.py`
- `etl/clean_validate.py`
- `etl/feature_engineering.py`

---

## 4) SQL (DDL + Advanced Analysis)
**DDL**: `sql/schema.sql` contains star schema tables and constraints.

**Load Script**: `sql/load.sql` provides insert patterns to populate tables from staging.

**Advanced Analysis**: `sql/advanced_kpis.sql`
- CTEs
- Window functions
- Rolling trends
- Hospital percentile rank
- Readmission & cost KPIs

---

## 5) BI Dashboard (Power BI / Tableau)
**Dashboard Spec**: `dashboard/dashboard_spec.md`

**Key Views**
- Executive KPI Summary (Readmission Rate, Cost per Discharge, ALOS)
- Readmission Trends by Month
- Hospital Rank vs Peer Benchmark
- Readmission Heatmap by State & Ownership
- Measure-level performance (AMI, HF, PN, COPD, etc.)

---

## 6) Insights & Recommendations
See `docs/insights_and_recommendations.md`.

---

## 7) Resume-Ready Outputs
- End-to-end ETL + star schema
- Advanced SQL analysis
- BI dashboard design
- Insights and recommendations

See `docs/resume_bullets.md` and `docs/interview_talking_points.md`.

---

## Folder Structure
```
projects/healthcare-readmission-analytics/
├─ data/
│  ├─ raw/
│  └─ processed/
├─ dashboard/
│  └─ dashboard_spec.md
├─ docs/
│  ├─ insights_and_recommendations.md
│  ├─ interview_talking_points.md
│  └─ resume_bullets.md
├─ etl/
│  ├─ clean_validate.py
│  ├─ feature_engineering.py
│  └─ ingest.py
├─ notebooks/
│  └─ exploratory_eda.ipynb
└─ sql/
   ├─ advanced_kpis.sql
   ├─ load.sql
   └─ schema.sql
```

---

## How to Run (Local)
1. Place CMS raw files into `data/raw/`.
2. Run `python etl/ingest.py` → outputs staging parquet.
3. Run `python etl/clean_validate.py` → outputs cleaned parquet.
4. Run `python etl/feature_engineering.py` → outputs star schema CSVs.
5. Load SQL schema: `sqlite3 healthcare.db < sql/schema.sql`.
6. Insert data: `sqlite3 healthcare.db < sql/load.sql`.
7. Use Power BI / Tableau to connect to `healthcare.db`.

---

## Interview Talking Points (Short)
- Built an end-to-end analytics pipeline on CMS HRRP data to reduce readmissions.
- Modeled star schema and automated ETL in Python for analytics-ready tables.
- Authored advanced SQL with window functions to benchmark hospitals and detect trends.
- Designed executive dashboard and delivered actionable recommendations.
