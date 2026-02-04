from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parents[1]
CLEAN_DIR = BASE_DIR / "data" / "processed" / "cleaned"
OUTPUT_DIR = BASE_DIR / "data" / "processed" / "star_schema"


def ensure_columns(df: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    df = df.copy()
    for col in columns:
        if col not in df.columns:
            df[col] = None
    return df


def build_dim_hospital(hospital_df: pd.DataFrame) -> pd.DataFrame:
    hospital_df = ensure_columns(
        hospital_df,
        [
            "provider_id",
            "hospital_name",
            "state",
            "city",
            "zip_code",
            "hospital_type",
            "hospital_ownership",
            "emergency_services",
        ],
    )
    dim_hospital = hospital_df[[
        "provider_id",
        "hospital_name",
        "state",
        "city",
        "zip_code",
        "hospital_type",
        "hospital_ownership",
        "emergency_services",
    ]].copy()
    dim_hospital = dim_hospital.drop_duplicates(subset=["provider_id"])
    dim_hospital["hospital_key"] = range(1, len(dim_hospital) + 1)
    return dim_hospital


def build_dim_geography(hospital_df: pd.DataFrame) -> pd.DataFrame:
    hospital_df = ensure_columns(hospital_df, ["state", "city", "zip_code"])
    dim_geo = hospital_df[["state", "city", "zip_code"]].copy()
    dim_geo = dim_geo.drop_duplicates()
    dim_geo["geo_key"] = range(1, len(dim_geo) + 1)
    return dim_geo


def build_dim_measure(hrrp_df: pd.DataFrame) -> pd.DataFrame:
    dim_measure = hrrp_df[["measure_id", "measure_name"]].copy()
    dim_measure = dim_measure.drop_duplicates(subset=["measure_id"])
    dim_measure["measure_key"] = range(1, len(dim_measure) + 1)
    return dim_measure


def build_dim_time(hrrp_df: pd.DataFrame) -> pd.DataFrame:
    dates = pd.concat([hrrp_df["start_date"], hrrp_df["end_date"]]).dropna()
    dates = pd.to_datetime(dates)
    dim_time = pd.DataFrame({"date": dates.dt.date}).drop_duplicates()
    dim_time["year"] = pd.to_datetime(dim_time["date"]).dt.year
    dim_time["month"] = pd.to_datetime(dim_time["date"]).dt.month
    dim_time["quarter"] = pd.to_datetime(dim_time["date"]).dt.quarter
    dim_time["time_key"] = range(1, len(dim_time) + 1)
    return dim_time


def build_fact_readmissions(hrrp_df: pd.DataFrame, dim_hospital: pd.DataFrame, dim_measure: pd.DataFrame, dim_time: pd.DataFrame) -> pd.DataFrame:
    fact = hrrp_df.copy()
    fact = fact.merge(dim_hospital[["provider_id", "hospital_key"]], on="provider_id", how="left")
    fact = fact.merge(dim_measure[["measure_id", "measure_key"]], on="measure_id", how="left")
    fact["end_date_only"] = fact["end_date"].dt.date
    fact = fact.merge(dim_time[["date", "time_key"]], left_on="end_date_only", right_on="date", how="left")

    fact["readmission_rate"] = fact["number_of_readmissions"] / fact["number_of_discharges"]
    fact["readmission_rate"] = fact["readmission_rate"].round(4)

    fact = fact[[
        "hospital_key",
        "measure_key",
        "time_key",
        "excess_readmission_ratio",
        "predicted_readmission_rate",
        "expected_readmission_rate",
        "number_of_readmissions",
        "number_of_discharges",
        "payment_reduction_percentage",
        "readmission_rate",
    ]]

    fact["fact_key"] = range(1, len(fact) + 1)
    return fact


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    hospital_df = pd.read_parquet(CLEAN_DIR / "hospital_general_clean.parquet")
    hrrp_df = pd.read_parquet(CLEAN_DIR / "hrrp_clean.parquet")

    dim_hospital = build_dim_hospital(hospital_df)
    dim_geo = build_dim_geography(hospital_df)
    dim_measure = build_dim_measure(hrrp_df)
    dim_time = build_dim_time(hrrp_df)
    fact_readmissions = build_fact_readmissions(hrrp_df, dim_hospital, dim_measure, dim_time)

    dim_hospital.to_csv(OUTPUT_DIR / "dim_hospital.csv", index=False)
    dim_geo.to_csv(OUTPUT_DIR / "dim_geography.csv", index=False)
    dim_measure.to_csv(OUTPUT_DIR / "dim_measure.csv", index=False)
    dim_time.to_csv(OUTPUT_DIR / "dim_time.csv", index=False)
    fact_readmissions.to_csv(OUTPUT_DIR / "fact_readmissions.csv", index=False)

    print("Star schema files written to:", OUTPUT_DIR)


if __name__ == "__main__":
    main()
