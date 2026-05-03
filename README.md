# PISA 2022 Australia — Education Analytics

A data analytics project exploring student performance patterns across Australian schools using PISA 2022 data.

**Author:** [Harley Le](https://github.com/maymay-ha)  
**Repository:** [pisa-2022-australia-analytics](https://github.com/maymay-ha/pisa-2022-australia-analytics)

**Tools:** PostgreSQL · DBeaver · Python (optional export scripts) · GitHub

---

## Project Structure

```
pisa-2022-australia-analytics/
├── README.md
├── analysis_notes.md
├── requirements.txt
├── sql/
│   ├── 01_explore_and_clean.sql
│   └── 02_analysis.sql
└── dataset/
    ├── export_students_aus.py   # student .sav → students_aus.csv
    ├── export_schools_aus.py    # school .sav → schools_aus.csv
    └── pisa_aus_export.py       # optional: CLI filter for any PISA .sav
```

Place OECD `.sav` inputs next to these scripts (see comments at top of each exporter). Output CSVs are gitignored; load them into PostgreSQL for the SQL step.

This repository contains **code and documentation only** — not OECD microdata. Download PISA files under [OECD conditions](https://www.oecd.org/en/data/datasets/pisa-2022-database.html); do not redistribute raw extracts via GitHub.

## Data Source

**Programme for International Student Assessment (PISA) 2022** — OECD  
Official database: [PISA 2022 database](https://www.oecd.org/en/data/datasets/pisa-2022-database.html).  
Filtered to Australia only. Two primary tables:

| Table | Rows | Description |
|---|---|---|
| `students_aus` | 13,437 | Student-level responses, plausible values, weights |
| `schools_aus` | 743 | School principal questionnaire responses |

---

## Data Quality & Preprocessing Decisions

Data was assessed across four dimensions before analysis. PISA 2022 Australia data was found to be exceptionally clean with minimal intervention required.

### Assessment results — students_aus

| Column | Completeness | Decision |
|---|---|---|
| score_math, score_reading, score_science | 100% | No action needed |
| gender | 99.8% (22 NULL) | Kept — see rationale below |
| escs (SES index) | 96.5% (466 NULL) | Kept — see rationale below |
| School join key | 100% match | No orphan records |

### Assessment results — schools_aus

| Column | Missing | % | Decision |
|---|---|---|---|
| school_type | 21 | 2.9% | Kept as NULL |
| location_community | 61 | 8.3% | Kept as NULL |
| class_size_test_language | 131 | 17.8% | Kept as NULL |
| ict_computers_availability | 182 | 24.8% | Kept as NULL |
| ict_computers_with_internet | 169 | 23.0% | Kept as NULL |
| ict_tablets_availability | 174 | 23.7% | Kept as NULL |
| shortage_educational_staff | 130 | 17.7% | Kept as NULL |

ICT and staff shortage columns show 18–25% missing, suggesting systematic non-response from a subset of schools. All NULLs retained — missing is informative (non-response from principals) and handled at query time.

### Decision: retain NULL gender rows (22 rows, 0.16%)

These rows contain complete score and ESCS data. Dropping them would remove valid observations solely due to a missing attribute that is irrelevant to most analyses. Gender NULL rows are excluded only in gender-specific queries at query time using `WHERE gender IS NOT NULL`, not pre-emptively at the data layer.

### Decision: retain NULL ESCS rows (466 rows, 3.5%)

A 3.5% missing rate is within acceptable thresholds for survey research. ESCS values are missing not due to data quality issues but because some students did not complete the background questionnaire. Imputation was not applied as it would introduce bias into equity analyses. Queries involving ESCS automatically exclude NULL values via PostgreSQL's standard NULL handling.

### Decision: retain all NULL values in schools_aus

Schools table has 18–25% missing across ICT and staff shortage columns. This reflects systematic non-response from school principals — not data quality failure. Empty strings were converted to NULL via `NULLIF()` to ensure consistent handling. All NULLs retained without imputation or recoding, for two reasons: (1) missing is informative — principals who did not respond may represent a distinct subgroup, and (2) imputing school-level variables risks introducing artificial patterns. NULLs are excluded at query time only when the relevant column is used in analysis.

### Decision: no star schema redesign

PISA is survey-based data, not transactional data. Star schema is designed for scenarios where entities (customers, products, locations) appear repeatedly across fact rows. In this dataset, each student appears exactly once, making additional dimension tables unnecessary. The existing `students_aus` ↔ `schools_aus` relationship already represents the appropriate data model. Forcing a star schema here would add complexity without analytical benefit.

### Missing value codes

PISA uses 9997, 9998, 9999 as missing value codes in some versions. Verified these do not appear in score columns:

```sql
SELECT COUNT(*) FROM students_aus
WHERE score_reading IN (9997, 9998, 9999)
   OR score_math    IN (9997, 9998, 9999)
   OR score_science IN (9997, 9998, 9999);
-- Result: 0
```

---

## AI Integration

This project used AI tooling deliberately to reduce low-value workload and focus time on analysis and interpretation.

| Task | Tool | How AI was used |
|---|---|---|
| File conversion | Cursor | Converted PISA .sav (SPSS) files to .csv for PostgreSQL import |
| SQL generation | Claude Opus 4.6 | Generated complex CTEs and window functions from natural language descriptions |
| Writing & grammar | Claude Opus 4.6 | Reviewed and corrected grammar in analysis notes and documentation |
| Version control | Cursor | Assisted with Git workflow — commit, push, pull operations |

AI was used as a force multiplier, not a replacement for analytical judgment. All SQL was reviewed and validated before use.

---

## Key Findings

1. **Math is Australia's weakest domain** — 26.3% of students below baseline proficiency (PISA Level 2). Science is strongest (19.1% at risk).

2. **SES is the single strongest predictor of outcomes** — About 100 score points between the most advantaged and most disadvantaged quartiles in math and science, and about 93 points in reading (see `analysis_notes.md` §3.2). 43% of the most disadvantaged students lack foundational math skills vs 12% of the most advantaged.

3. **Gender gap is domain-specific** — females outscore males by 22.5 points in reading; males outscore females by 10.5 points in math. 25% of boys score below baseline in reading vs 16% of girls.

4. **Urban-rural gap: 64 points in math** — smooth linear gradient from village (443.7) to large city (507.8). Staff shortages compound regional disadvantage (37-point gap).

5. **ICT access does not correlate with higher scores** — village/rural schools report higher computers-per-student (1.64) than large-city schools (1.02) but score lower in math; see `analysis_notes.md` §5.3. This likely reflects targeted equity funding rather than technology failure.

See `analysis_notes.md` for full findings with data tables and strategic implications.

---

## Limitations

1. **PISA is a low-stakes assessment.** It does not count toward students' ATAR or school grades. OECD post-2022 analyses indicate significant effort variation among Australian students, with a majority reporting they did not fully try. Performance gaps may partially reflect differences in test engagement rather than latent capability.

2. **No Indigenous status identifier.** PISA 2022 public-use data does not include an Aboriginal and Torres Strait Islander status variable. Rural and low-SES variables partially overlap with Indigenous disadvantage but do not capture the distinct cultural and systemic barriers faced by First Nations students. For analysis relevant to Australian education strategy — particularly for institutions with reconciliation commitments — supplementary data sources (e.g. NAPLAN, ABS) disaggregated by Indigenous status would be essential.

3. **Text-heavy math items conflate reading and numeracy.** PISA math questions are applied reasoning tasks requiring students to read extended text before solving problems. The 26% math at-risk rate may partially reflect reading difficulties rather than purely mathematical deficiency — supported by the 0.80 cross-domain correlation between math and reading scores. This is a known construct validity concern with PISA's format.

4. **"At risk" is an OECD benchmark, not an Australian standard.** Level 2 is the OECD's normative baseline, also used by the Australian government in official PISA reporting. However, it does not directly map to Australian curriculum standards or VET entry requirements. The "at-risk" framing reflects the OECD framework, not an absolute measure of student capability in an Australian classroom context.

5. **Points-to-years conversion is contested.** A common extrapolation equates ~40 PISA points to one year of schooling. This analysis avoids this conversion because PISA measures applied reasoning in unfamiliar contexts (unlike TIMSS, which measures curriculum mastery). Gaps are instead anchored in PISA's own proficiency level framework.

6. **Cross-sectional data cannot establish causation.** Correlations between school factors (ICT, staff shortage, school type) and scores may reflect reverse causality or confounding variables. For example, higher device ratios in disadvantaged schools likely reflect targeted equity funding, not technology failure.

7. **Staff shortage is perceptual data.** The "shortage_educational_staff" variable comes from principal questionnaires, not objective staffing metrics. Principals' thresholds for reporting "shortage" may vary by school context — a well-resourced school may report "major shortage" based on higher expectations, while an under-resourced school may have normalised understaffing. The 37-point gradient is suggestive but cannot distinguish between actual staffing gaps and variation in reporting standards.

8. **Small subgroup samples.** Some cross-tabulations (e.g. disadvantaged students in independent schools, n=183) have small samples that limit generalisability. These are flagged in the analysis notes.

9. **PISA-to-university pipeline.** PISA assesses 15-year-olds (Year 10). University entrance occurs after Year 12, following ATAR selection, VET sorting, and attrition. Strategic implications for tertiary education are directional observations, not direct predictions.

10. **No migrant/CALD disaggregation.** This analysis does not control for language background or immigrant generation. In Australia (~30% foreign-born), first/second-generation students from some backgrounds outperform in math/science despite lower ESCS scores. Without this variable, SES-based conclusions may not hold uniformly across all cultural groups.

11. **Cross-sectional data, not value-added.** PISA measures absolute achievement at age 15 — not student growth. School sector comparisons reflect intake composition as much as school effectiveness. A school that lifts students from Level 1 to Level 3 adds more educational value than one that maintains students at Level 5, but PISA cannot distinguish between them.

12. **Class size allocation bias.** Small and large classes both show high scores, creating a misleading flat relationship. This reflects allocation policy (gifted streams, remedial groups, oversubscribed urban schools) rather than class size impact on learning.

---

## How to Reproduce

1. Download PISA 2022 data from the [OECD PISA 2022 database](https://www.oecd.org/en/data/datasets/pisa-2022-database.html) and filter to Australia (or use your own Australia extracts).
2. **Optional — build CSVs:** install Python deps (`pip install -r requirements.txt`), place the relevant `.sav` files in `dataset/`, then run `python dataset/export_students_aus.py` and `python dataset/export_schools_aus.py` (see script headers for expected filenames).
3. Import the CSVs into PostgreSQL using `COPY` (see comments in the SQL scripts for suggested syntax).
4. Run `sql/01_explore_and_clean.sql` to verify data quality and clean.
5. Run `sql/02_analysis.sql` for all analysis queries.