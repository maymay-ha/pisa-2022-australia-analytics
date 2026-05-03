"""
Export PISA CY08 .sav to CSV: Australia only, selected columns.
Student file (CY08MSP_STU_*.SAV): Student ID, ESCS, PV scores, gender, school ID.
School file (CY08MSP_SCH_*.SAV): school-level only — no ESCS / achievement / student gender.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import pandas as pd

# OECD PISA CY08 (2022) typical names — student questionnaire
STUDENT_COLS = {
    "CNT": "country",
    "STIDSTD": "student_id",
    "CNTSCHID": "school_id",
    "ESCS": "escs",
    "PV1MATH": "score_math",
    "PV1READ": "score_reading",
    "PV1SCIE": "score_science",
    "ST004D01T": "gender",
}

SCHOOL_MIN_COLS = {"CNT": "country", "CNTSCHID": "school_id"}


def main() -> None:
    p = argparse.ArgumentParser(description="Filter AUS and export selected columns from PISA .sav")
    p.add_argument("sav_path", type=Path, help="Path to .sav file")
    p.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Output CSV path (default: same stem + _Australia.csv)",
    )
    args = p.parse_args()
    sav = args.sav_path.expanduser().resolve()
    if not sav.is_file():
        print(f"File not found: {sav}", file=sys.stderr)
        sys.exit(1)

    out = args.output or sav.with_name(f"{sav.stem}_Australia.csv")

    df = pd.read_spss(str(sav))

    if "CNT" not in df.columns:
        print("No CNT column; cannot filter by country.", file=sys.stderr)
        sys.exit(1)

    # OECD SPSS often stores full names (e.g. "Australia"); codebooks also use ISO "AUS".
    cnt_norm = df["CNT"].astype(str).str.strip().str.upper()
    aus_mask = cnt_norm.isin({"AUS", "AUSTRALIA"})
    df = df.loc[aus_mask].copy()
    if df.empty:
        print("No rows for Australia (CNT must be 'AUS' or 'Australia').", file=sys.stderr)
        sys.exit(1)

    name_upper = sav.name.upper()
    is_school = "SCH" in name_upper and "STU" not in name_upper

    if is_school:
        present = [c for c in SCHOOL_MIN_COLS if c in df.columns]
        sub = df[present].rename(columns={k: v for k, v in SCHOOL_MIN_COLS.items() if k in present})
        print(
            "NOTE: This is a school questionnaire file. It does not contain "
            "student_id, ESCS, achievement plausible values (PV1MATH/READ/SCIE), or student gender. "
            "Use the student microdata file (e.g. CY08MSP_STU_QQQ.SAV) for those variables.",
            file=sys.stderr,
        )
    else:
        missing = [c for c in STUDENT_COLS if c not in df.columns]
        if missing:
            print(f"Missing columns in this file: {missing}", file=sys.stderr)
            sys.exit(1)
        want = list(STUDENT_COLS.keys())
        sub = df[want].rename(columns=STUDENT_COLS)

    for col in ("school_id", "student_id"):
        if col not in sub.columns:
            continue
        s = pd.to_numeric(sub[col], errors="coerce")
        if s.notna().all() and (s % 1 == 0).all():
            sub = sub.copy()
            sub[col] = s.astype("int64")

    sub.to_csv(out, index=False)
    print(f"Wrote {len(sub)} rows to {out}")


if __name__ == "__main__":
    main()
