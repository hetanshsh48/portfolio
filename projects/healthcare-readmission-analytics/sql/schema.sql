-- Star schema for CMS Readmissions Analytics (SQLite/Postgres-compatible)

DROP TABLE IF EXISTS fact_readmissions;
DROP TABLE IF EXISTS dim_time;
DROP TABLE IF EXISTS dim_measure;
DROP TABLE IF EXISTS dim_geography;
DROP TABLE IF EXISTS dim_hospital;

CREATE TABLE dim_hospital (
    hospital_key INTEGER PRIMARY KEY,
    provider_id TEXT NOT NULL,
    hospital_name TEXT,
    state TEXT,
    city TEXT,
    zip_code TEXT,
    hospital_type TEXT,
    hospital_ownership TEXT,
    emergency_services TEXT
);

CREATE TABLE dim_geography (
    geo_key INTEGER PRIMARY KEY,
    state TEXT,
    city TEXT,
    zip_code TEXT
);

CREATE TABLE dim_measure (
    measure_key INTEGER PRIMARY KEY,
    measure_id TEXT NOT NULL,
    measure_name TEXT
);

CREATE TABLE dim_time (
    time_key INTEGER PRIMARY KEY,
    date DATE NOT NULL,
    year INTEGER,
    month INTEGER,
    quarter INTEGER
);

CREATE TABLE fact_readmissions (
    fact_key INTEGER PRIMARY KEY,
    hospital_key INTEGER NOT NULL,
    measure_key INTEGER NOT NULL,
    time_key INTEGER NOT NULL,
    excess_readmission_ratio REAL,
    predicted_readmission_rate REAL,
    expected_readmission_rate REAL,
    number_of_readmissions INTEGER,
    number_of_discharges INTEGER,
    payment_reduction_percentage REAL,
    readmission_rate REAL,
    FOREIGN KEY (hospital_key) REFERENCES dim_hospital (hospital_key),
    FOREIGN KEY (measure_key) REFERENCES dim_measure (measure_key),
    FOREIGN KEY (time_key) REFERENCES dim_time (time_key)
);

-- Optional staging tables for raw CMS data
DROP TABLE IF EXISTS staging_hospital_general;
DROP TABLE IF EXISTS staging_hrrp;

CREATE TABLE staging_hospital_general (
    provider_id TEXT,
    hospital_name TEXT,
    state TEXT,
    city TEXT,
    zip_code TEXT,
    hospital_type TEXT,
    hospital_ownership TEXT,
    emergency_services TEXT
);

CREATE TABLE staging_hrrp (
    provider_id TEXT,
    measure_id TEXT,
    measure_name TEXT,
    start_date DATE,
    end_date DATE,
    excess_readmission_ratio REAL,
    predicted_readmission_rate REAL,
    expected_readmission_rate REAL,
    number_of_readmissions INTEGER,
    number_of_discharges INTEGER,
    payment_reduction_percentage REAL
);
