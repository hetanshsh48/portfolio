# Dashboard Specification (Power BI / Tableau)

## Dashboard Goal
Provide leadership with a readmission performance overview, identify high-risk hospitals and measures, and track improvement over time.

## Pages & Visuals
### 1) Executive Summary
- **KPI Cards**: Readmission Rate, Cost per Discharge, ALOS, Penalty Exposure
- **Trend Line**: 12-month rolling readmission rate
- **Benchmark Bar**: Hospital vs peer average (ownership)

### 2) Readmissions by Measure
- **Bar Chart**: Readmission rate by measure (AMI, HF, PN, COPD, CABG, THA/TKA)
- **Scatter Plot**: Readmission rate vs expected rate
- **Table**: Top 10 measures with variance from expected

### 3) Hospital Performance
- **Map**: Readmission heatmap by state
- **Table**: Hospital rank with percentile, penalty decile, and trend indicator

## Filters
- Year / Quarter
- Measure
- State
- Ownership Type

## Core Measures (DAX/Tableau)
- **Readmission Rate** = SUM(number_of_readmissions) / SUM(number_of_discharges)
- **Penalty Exposure** = AVG(payment_reduction_percentage)
- **Risk-Adjusted Readmission Index** = AVG(excess_readmission_ratio)
- **Rolling 3-Month Rate** = Average of last 3 months (window function)

## Executive Summary Metrics
- System-wide Readmission Rate
- Change vs Prior Year
- Top 10 Penalty Hospitals
- Top 5 Measures Above Expected
