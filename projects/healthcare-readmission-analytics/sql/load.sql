-- Load dimension tables from staging tables

INSERT INTO dim_hospital (
    hospital_key,
    provider_id,
    hospital_name,
    state,
    city,
    zip_code,
    hospital_type,
    hospital_ownership,
    emergency_services
)
SELECT
    ROW_NUMBER() OVER (ORDER BY provider_id) AS hospital_key,
    provider_id,
    hospital_name,
    state,
    city,
    zip_code,
    hospital_type,
    hospital_ownership,
    emergency_services
FROM (
    SELECT DISTINCT * FROM staging_hospital_general
) base;

INSERT INTO dim_geography (
    geo_key,
    state,
    city,
    zip_code
)
SELECT
    ROW_NUMBER() OVER (ORDER BY state, city, zip_code) AS geo_key,
    state,
    city,
    zip_code
FROM (
    SELECT DISTINCT state, city, zip_code FROM staging_hospital_general
) base;

INSERT INTO dim_measure (
    measure_key,
    measure_id,
    measure_name
)
SELECT
    ROW_NUMBER() OVER (ORDER BY measure_id) AS measure_key,
    measure_id,
    measure_name
FROM (
    SELECT DISTINCT measure_id, measure_name FROM staging_hrrp
) base;

INSERT INTO dim_time (
    time_key,
    date,
    year,
    month,
    quarter
)
SELECT
    ROW_NUMBER() OVER (ORDER BY date) AS time_key,
    date,
    CAST(strftime('%Y', date) AS INTEGER) AS year,
    CAST(strftime('%m', date) AS INTEGER) AS month,
    CAST(((CAST(strftime('%m', date) AS INTEGER) + 2) / 3) AS INTEGER) AS quarter
FROM (
    SELECT DISTINCT DATE(start_date) AS date FROM staging_hrrp
    UNION
    SELECT DISTINCT DATE(end_date) AS date FROM staging_hrrp
) base;

-- Load fact table
INSERT INTO fact_readmissions (
    fact_key,
    hospital_key,
    measure_key,
    time_key,
    excess_readmission_ratio,
    predicted_readmission_rate,
    expected_readmission_rate,
    number_of_readmissions,
    number_of_discharges,
    payment_reduction_percentage,
    readmission_rate
)
SELECT
    ROW_NUMBER() OVER (ORDER BY h.provider_id, s.measure_id, s.end_date) AS fact_key,
    h.hospital_key,
    m.measure_key,
    t.time_key,
    s.excess_readmission_ratio,
    s.predicted_readmission_rate,
    s.expected_readmission_rate,
    s.number_of_readmissions,
    s.number_of_discharges,
    s.payment_reduction_percentage,
    CASE
        WHEN s.number_of_discharges > 0 THEN ROUND(1.0 * s.number_of_readmissions / s.number_of_discharges, 4)
        ELSE NULL
    END AS readmission_rate
FROM staging_hrrp s
JOIN dim_hospital h ON h.provider_id = s.provider_id
JOIN dim_measure m ON m.measure_id = s.measure_id
JOIN dim_time t ON t.date = DATE(s.end_date);
