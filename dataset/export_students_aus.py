"""Export Australia student rows from CY08MSP_STU_QQQ.SAV to CSV."""
from pathlib import Path

import pandas as pd
import pyreadstat

SAV = Path(__file__).resolve().parent / "CY08MSP_STU_QQQ.SAV"
OUT = Path(__file__).resolve().parent / "students_aus.csv"

USECOLS = [
    "CNT",
    "CNTSTUID",
    "ESCS",
    "PV1MATH",
    "PV1READ",
    "PV1SCIE",
    "ST004D01T",
    "CNTSCHID",
]

RENAME = {
    "CNTSTUID": "student_id",
    "ESCS": "escs",
    "PV1MATH": "score_math",
    "PV1READ": "score_reading",
    "PV1SCIE": "score_science",
    "ST004D01T": "gender",
    "CNTSCHID": "school_id",
}


def main() -> None:
    df, _meta = pyreadstat.read_sav(
        str(SAV),
        usecols=USECOLS,
        apply_value_formats=True,
    )

    cnt = df["CNT"].astype(str)
    aus = cnt.str.strip().str.upper().isin({"AUS", "AUSTRALIA"})
    df = df.loc[aus].drop(columns=["CNT"])

    df = df.rename(columns=RENAME)

    df = df[
        [
            "student_id",
            "escs",
            "score_math",
            "score_reading",
            "score_science",
            "gender",
            "school_id",
        ]
    ]

    for col in ("student_id", "school_id"):
        s = pd.to_numeric(df[col], errors="coerce")
        if s.notna().all() and (s % 1 == 0).all():
            df[col] = s.astype("int64")

    df.to_csv(OUT, index=False)
    print(f"Wrote {len(df)} rows to {OUT}")


if __name__ == "__main__":
    main()
