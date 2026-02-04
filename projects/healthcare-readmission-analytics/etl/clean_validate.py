from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parents[1]
STAGING_DIR = BASE_DIR / "data" / "processed" / "staging"
CLEAN_DIR = BASE_DIR / "data" / "processed" / "cleaned"


PROVIDER_ID_COLUMNS = [
    "provider_id",
    "facility_id",
    "ccn",
    "cms_certification_number",
]


def standardize_provider_id(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    for col in PROVIDER_ID_COLUMNS:
        if col in df.columns:
            df["provider_id"] = df[col].astype(str).str.zfill(6)
            break
    if "provider_id" not in df.columns:
        raise ValueError("Provider ID column not found in dataset.")
    return df


def coerce_numeric(df: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    df = df.copy()
    for col in columns:
        if col in df.columns:
            df[col] = (
                df[col]
                .replace({"Not Available": None, "NA": None, "": None})
                .astype(str)
                .str.replace("%", "", regex=False)
            )
            df[col] = pd.to_numeric(df[col], errors="coerce")
    return df


def clean_hospital_general(df: pd.DataFrame) -> pd.DataFrame:
    df = standardize_provider_id(df)
    df["hospital_name"] = df.get("hospital_name", "").astype(str).str.title()
    df["state"] = df.get("state", "").astype(str).str.upper()
    df["zip_code"] = df.get("zip_code", "").astype(str).str[:5]
    df = df.drop_duplicates(subset=["provider_id"])
    return df


def clean_hrrp(df: pd.DataFrame) -> pd.DataFrame:
    df = standardize_provider_id(df)
    numeric_cols = [
        "excess_readmission_ratio",
        "predicted_readmission_rate",
        "expected_readmission_rate",
        "number_of_readmissions",
        "number_of_discharges",
        "payment_reduction_percentage",
    ]
    df = coerce_numeric(df, numeric_cols)
    df["measure_id"] = df.get("measure_id", "").astype(str).str.upper()
    df["measure_name"] = df.get("measure_name", "").astype(str)
    df["start_date"] = pd.to_datetime(df.get("start_date"), errors="coerce")
    df["end_date"] = pd.to_datetime(df.get("end_date"), errors="coerce")
    return df


def main() -> None:
    CLEAN_DIR.mkdir(parents=True, exist_ok=True)

    hospital_general = pd.read_parquet(STAGING_DIR / "hospital_general.parquet")
    hrrp = pd.read_parquet(STAGING_DIR / "hrrp.parquet")

    hospital_general_clean = clean_hospital_general(hospital_general)
    hrrp_clean = clean_hrrp(hrrp)

    hospital_general_clean.to_parquet(CLEAN_DIR / "hospital_general_clean.parquet", index=False)
    hrrp_clean.to_parquet(CLEAN_DIR / "hrrp_clean.parquet", index=False)

    print("Cleaned datasets saved to:", CLEAN_DIR)
    print("Hospital count:", hospital_general_clean["provider_id"].nunique())
    print("HRRP measure rows:", len(hrrp_clean))


if __name__ == "__main__":
    main()
