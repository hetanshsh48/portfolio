import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
RAW_DIR = BASE_DIR / "data" / "raw"
STAGING_DIR = BASE_DIR / "data" / "processed" / "staging"


def load_csv(filename: str) -> pd.DataFrame:
    file_path = RAW_DIR / filename
    return pd.read_csv(file_path, dtype=str)


def normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = (
        df.columns.str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
        .str.replace("/", "_", regex=False)
    )
    return df


def main() -> None:
    STAGING_DIR.mkdir(parents=True, exist_ok=True)

    hospital_info = load_csv("Hospital_General_Information.csv")
    hrrp = load_csv("Hospital_Readmissions_Reduction_Program.csv")

    hospital_info = normalize_columns(hospital_info)
    hrrp = normalize_columns(hrrp)

    hospital_info.to_parquet(STAGING_DIR / "hospital_general.parquet", index=False)
    hrrp.to_parquet(STAGING_DIR / "hrrp.parquet", index=False)

    print("Staging files written to:", STAGING_DIR)


if __name__ == "__main__":
    main()
