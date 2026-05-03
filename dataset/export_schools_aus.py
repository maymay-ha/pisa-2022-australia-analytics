"""Export Australian schools from CY08MSP_SCH_QQQ.SAV to schools_aus.csv."""
from pathlib import Path

import pandas as pd

SAV = Path(__file__).resolve().parent / "CY08MSP_SCH_QQQ.SAV"
OUT = Path(__file__).resolve().parent / "schools_aus.csv"

# In OECD SPSS exports, CNT is often the full country name; ISO code AUS also accepted.
SELECT = {
    "CNTSCHID": "school_id",
    "SCHLTYPE": "school_type",
    "SC001Q01TA": "location_community",  # urban/rural-style community size
    "RATCMP1": "ict_computers_availability",
    "RATCMP2": "ict_computers_with_internet",
    "RATTAB": "ict_tablets_availability",
    "STAFFSHORT": "shortage_educational_staff",
    "CLSIZE": "class_size_test_language",
    "MCLSIZE": "math_class_size",
}


def main() -> None:
    df = pd.read_spss(str(SAV))
    cnt = df["CNT"].astype(str).str.strip().str.upper()
    df = df[cnt.isin({"AUS", "AUSTRALIA"})].copy()
    if df.empty:
        raise SystemExit("No rows for Australia (use CNT 'AUS' or 'Australia').")

    out_df = df[list(SELECT.keys())].rename(columns=SELECT)

    sid = pd.to_numeric(out_df["school_id"], errors="coerce")
    if sid.notna().all() and (sid % 1 == 0).all():
        out_df["school_id"] = sid.astype("int64")

    for c in out_df.columns:
        if c == "school_id":
            continue
        if out_df[c].dtype == "category":
            out_df[c] = out_df[c].astype(str).replace("nan", pd.NA)

    out_df.to_csv(OUT, index=False)
    print(f"Wrote {len(out_df)} rows to {OUT}")


if __name__ == "__main__":
    main()
