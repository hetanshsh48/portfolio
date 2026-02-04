-- Advanced KPI queries for CMS Readmissions Analytics

-- 1) System-wide monthly readmission rate trend
WITH monthly_rollup AS (
    SELECT
        dt.year,
        dt.month,
        SUM(fr.number_of_readmissions) AS total_readmissions,
        SUM(fr.number_of_discharges) AS total_discharges
    FROM fact_readmissions fr
    JOIN dim_time dt ON dt.time_key = fr.time_key
    GROUP BY dt.year, dt.month
),
rate_calc AS (
    SELECT
        year,
        month,
        total_readmissions,
        total_discharges,
        ROUND(1.0 * total_readmissions / NULLIF(total_discharges, 0), 4) AS readmission_rate
    FROM monthly_rollup
)
SELECT
    year,
    month,
    readmission_rate,
    AVG(readmission_rate) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3mo_rate
FROM rate_calc
ORDER BY year, month;

-- 2) Hospital rank vs peer benchmark (ownership) using percentile rank
WITH hospital_rates AS (
    SELECT
        h.hospital_key,
        h.hospital_name,
        h.hospital_ownership,
        SUM(fr.number_of_readmissions) AS total_readmissions,
        SUM(fr.number_of_discharges) AS total_discharges,
        ROUND(1.0 * SUM(fr.number_of_readmissions) / NULLIF(SUM(fr.number_of_discharges), 0), 4) AS readmission_rate
    FROM fact_readmissions fr
    JOIN dim_hospital h ON h.hospital_key = fr.hospital_key
    GROUP BY h.hospital_key, h.hospital_name, h.hospital_ownership
)
SELECT
    hospital_name,
    hospital_ownership,
    readmission_rate,
    PERCENT_RANK() OVER (PARTITION BY hospital_ownership ORDER BY readmission_rate) AS ownership_percentile
FROM hospital_rates
ORDER BY hospital_ownership, readmission_rate DESC;

-- 3) Measure-level performance with variance from expected rate
WITH measure_perf AS (
    SELECT
        m.measure_name,
        SUM(fr.number_of_readmissions) AS total_readmissions,
        SUM(fr.number_of_discharges) AS total_discharges,
        ROUND(1.0 * SUM(fr.number_of_readmissions) / NULLIF(SUM(fr.number_of_discharges), 0), 4) AS observed_rate,
        AVG(fr.expected_readmission_rate) AS expected_rate
    FROM fact_readmissions fr
    JOIN dim_measure m ON m.measure_key = fr.measure_key
    GROUP BY m.measure_name
)
SELECT
    measure_name,
    observed_rate,
    expected_rate,
    ROUND(observed_rate - expected_rate, 4) AS variance_from_expected
FROM measure_perf
ORDER BY variance_from_expected DESC;

-- 4) High-risk hospitals (top 10% penalty exposure)
WITH penalty_base AS (
    SELECT
        h.hospital_name,
        h.state,
        AVG(fr.payment_reduction_percentage) AS avg_penalty
    FROM fact_readmissions fr
    JOIN dim_hospital h ON h.hospital_key = fr.hospital_key
    GROUP BY h.hospital_name, h.state
),
penalty_rank AS (
    SELECT
        hospital_name,
        state,
        avg_penalty,
        NTILE(10) OVER (ORDER BY avg_penalty DESC) AS penalty_decile
    FROM penalty_base
)
SELECT
    hospital_name,
    state,
    avg_penalty,
    penalty_decile
FROM penalty_rank
WHERE avg_penalty IS NOT NULL
  AND penalty_decile = 1;

-- 5) Year-over-year change in readmission rate
WITH annual_rates AS (
    SELECT
        dt.year,
        SUM(fr.number_of_readmissions) AS total_readmissions,
        SUM(fr.number_of_discharges) AS total_discharges,
        ROUND(1.0 * SUM(fr.number_of_readmissions) / NULLIF(SUM(fr.number_of_discharges), 0), 4) AS readmission_rate
    FROM fact_readmissions fr
    JOIN dim_time dt ON dt.time_key = fr.time_key
    GROUP BY dt.year
)
SELECT
    year,
    readmission_rate,
    readmission_rate - LAG(readmission_rate) OVER (ORDER BY year) AS yoy_change
FROM annual_rates
ORDER BY year;
