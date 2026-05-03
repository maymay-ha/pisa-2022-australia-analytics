-- =============================================================
-- pisa 2022 australia — data quality & cleaning
-- =============================================================
-- decisions:
--   - numeric columns cannot store empty strings in postgresql,
--     so missing values are already null after import
--   - varchar columns may contain empty strings — converted to null
--   - all nulls retained (not imputed or recoded)
--     rationale: missing is informative (non-response from schools)
-- =============================================================
 
 
-- -------------------------------------------------------------
-- 1. students_aus
-- -------------------------------------------------------------
 
-- overview
select count(*) from students_aus;
-- total: 13,437
 
-- column list
select column_name, data_type
from information_schema.columns
where table_name = 'students_aus'
order by ordinal_position;
 
-- missing value check
-- varchar: check null and empty string
-- numeric: check null only (postgresql cannot store '' in numeric)
select
    sum(case when student_id    is null or student_id = ''  then 1 else 0 end) as student_id_missing,
    sum(case when school_id     is null or school_id  = ''  then 1 else 0 end) as school_id_missing,
    sum(case when gender        is null or gender     = ''  then 1 else 0 end) as gender_missing,
    sum(case when escs          is null                     then 1 else 0 end) as escs_missing,
    sum(case when score_math    is null                     then 1 else 0 end) as score_math_missing,
    sum(case when score_reading is null                     then 1 else 0 end) as score_reading_missing,
    sum(case when score_science is null                     then 1 else 0 end) as score_science_missing
from students_aus;
-- student_id: 0 | school_id: 0 | gender: 22 | escs: 466
-- score_math: 0 | score_reading: 0 | score_science: 0
 
-- gender distribution
select gender, count(*)
from students_aus
group by 1
order by 2 desc;
-- female: 6,557 | male: 6,858 | null/empty: 22
 
-- check pisa missing value codes in score columns
select count(*) from students_aus
where score_reading in (9997, 9998, 9999)
   or score_math    in (9997, 9998, 9999)
   or score_science in (9997, 9998, 9999);
-- result: 0 — no pisa bad codes present
 
-- check join integrity: students → schools
select count(distinct s.school_id)
from students_aus s
left join schools_aus sch on s.school_id = sch.school_id
where sch.school_id is null;
-- result: 0 — all students have a matching school record
 
-- clean: convert empty string to null (gender only)
update students_aus
set gender = nullif(gender, '');
 
-- verify
select sum(case when gender = '' then 1 else 0 end) as gender_empty_string
from students_aus;
-- result: 0
 
 
-- -------------------------------------------------------------
-- 2. schools_aus
-- -------------------------------------------------------------
 
-- overview
select count(*) from schools_aus;
-- total: 743
 
-- column list
select column_name, data_type
from information_schema.columns
where table_name = 'schools_aus'
order by ordinal_position;
 
-- missing value check
select
    sum(case when school_id                   is null or school_id = ''                   then 1 else 0 end) as school_id_missing,
    sum(case when school_type                 is null or school_type = ''                 then 1 else 0 end) as school_type_missing,
    sum(case when location_community          is null or location_community = ''          then 1 else 0 end) as location_missing,
    sum(case when class_size_test_language    is null or class_size_test_language = ''    then 1 else 0 end) as class_size_missing,
    sum(case when math_class_size             is null or math_class_size = ''             then 1 else 0 end) as math_class_size_missing,
    sum(case when ict_computers_availability  is null                                     then 1 else 0 end) as ict_computers_missing,
    sum(case when ict_computers_with_internet is null                                     then 1 else 0 end) as ict_internet_missing,
    sum(case when ict_tablets_availability    is null                                     then 1 else 0 end) as ict_tablets_missing,
    sum(case when shortage_educational_staff  is null                                     then 1 else 0 end) as staff_shortage_missing
from schools_aus;
-- school_type: 21 (2.9%) | location: 61 (8.3%)  | class_size: 131 (17.8%)
-- ict_computers: 182 (24.8%) | ict_internet: 169 (23.0%) | ict_tablets: 174 (23.7%)
-- staff_shortage: 130 (17.7%)
-- note: high missing rate across ict and class_size columns suggests
--       systematic non-response from a subset of schools
 
-- clean: convert empty strings to null for varchar columns only
-- numeric columns (ict, staff_shortage) already null from import
update schools_aus
set school_type              = nullif(school_type, ''),
    location_community       = nullif(location_community, ''),
    class_size_test_language = nullif(class_size_test_language, ''),
    math_class_size          = nullif(math_class_size, '');
 
-- verify
select
    sum(case when school_type              = '' then 1 else 0 end) as school_type_empty,
    sum(case when location_community       = '' then 1 else 0 end) as location_empty,
    sum(case when class_size_test_language = '' then 1 else 0 end) as class_size_empty,
    sum(case when math_class_size          = '' then 1 else 0 end) as math_class_size_empty
from schools_aus;
-- all results: 0
 