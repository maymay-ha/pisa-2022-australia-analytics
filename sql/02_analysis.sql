-- =============================================================
-- pisa 2022 australia — analysis
-- =============================================================
 
 
-- -------------------------------------------------------------
-- section 1: overall performance snapshot
-- -------------------------------------------------------------
 
-- 1.1 average score across 3 domains
select
    round(avg(score_math)::numeric, 1)    as avg_math,
    round(avg(score_reading)::numeric, 1) as avg_reading,
    round(avg(score_science)::numeric, 1) as avg_science
from students_aus;
-- math 486.8, reading 498.9, science 507.8
 
-- 1.2 score distribution — min, max, stddev
select
    'math'    as domain,
    round(min(score_math)::numeric, 1)    as min_score,
    round(avg(score_math)::numeric, 1)    as avg_score,
    round(max(score_math)::numeric, 1)    as max_score,
    round(stddev(score_math)::numeric, 1) as std_dev
from students_aus
union all
select
    'reading',
    round(min(score_reading)::numeric, 1),
    round(avg(score_reading)::numeric, 1),
    round(max(score_reading)::numeric, 1),
    round(stddev(score_reading)::numeric, 1)
from students_aus
union all
select
    'science',
    round(min(score_science)::numeric, 1),
    round(avg(score_science)::numeric, 1),
    round(max(score_science)::numeric, 1),
    round(stddev(score_science)::numeric, 1)
from students_aus;
 /* domain min avg max std 
math	183.0	486.8	820.9	98.3
reading	101.1	498.9	938.7	109.1
science	108.3	507.8	875.2	106.8 */
 
/*pisa 2022 proficiency level cut scores
set by: OECD using Item Response Theory (IRT)
source: nces.ed.gov/surveys/pisa/pisa2022
level 2 = baseline proficiency — below = "at risk"
			math    reading   science
level 2     420     407       410
level 3     482     480       484
level 4     545     553       559
level 5     607     626       633
level 6     669     698       708*/

-- 1.3 score buckets by pisa proficiency bands
select 'math' as domain,
    case
        when score_math < 420 then '1. below level 2'
        when score_math < 482 then '2. level 2'
        when score_math < 545 then '3. level 3'
        when score_math < 607 then '4. level 4'
        when score_math < 669 then '5. level 5'
        else                       '6. level 6'
    end as band,
    count(*) as students,
    round(count(*) * 100.0 / sum(count(*)) over(), 1) as pct
from students_aus group by 1, 2

union all

select 'reading',
    case
        when score_reading < 407 then '1. below level 2'
        when score_reading < 480 then '2. level 2'
        when score_reading < 553 then '3. level 3'
        when score_reading < 626 then '4. level 4'
        when score_reading < 698 then '5. level 5'
        else                          '6. level 6'
    end, count(*),
    round(count(*) * 100.0 / sum(count(*)) over(), 1)
from students_aus group by 1, 2

union all

select 'science',
    case
        when score_science < 410 then '1. below level 2'
        when score_science < 484 then '2. level 2'
        when score_science < 559 then '3. level 3'
        when score_science < 633 then '4. level 4'
        when score_science < 708 then '5. level 5'
        else                          '6. level 6'
    end, count(*),
    round(count(*) * 100.0 / sum(count(*)) over(), 1)
from students_aus group by 1, 2

order by 1, 2;
/* domain band students pct
math	1. below level 2	3532	26.3
math	2. level 2	3010	22.4
math	3. level 3	3137	23.3
math	4. level 4	2172	16.2
math	5. level 5	1137	8.5
math	6. level 6	449	3.3
reading	1. below level 2	2770	20.6
reading	2. level 2	2873	21.4
reading	3. level 3	3499	26.0
reading	4. level 4	2673	19.9
reading	5. level 5	1246	9.3
reading	6. level 6	376	2.8
science	1. below level 2	2563	19.1
science	2. level 2	2983	22.2
science	3. level 3	3457	25.7
science	4. level 4	2769	20.6
science	5. level 5	1327	9.9
science	6. level 6	338	2.5 */
 
-- 1.4 correlation between domains
-- if high then students strong in one domain tend to be strong in all
select
    round(corr(score_math, score_reading)::numeric, 3) as math_reading_corr,
    round(corr(score_math, score_science)::numeric, 3) as math_science_corr,
    round(corr(score_reading, score_science)::numeric, 3) as reading_science_corr
from students_aus;
/** 0.802	0.870	0.791 **/

-- -------------------------------------------------------------
-- section 2: gender gap analysis
-- -------------------------------------------------------------

-- 2.1 average score by gender
select
    gender,
    round(avg(score_math)::numeric, 1)    as avg_math,
    round(avg(score_reading)::numeric, 1) as avg_reading,
    round(avg(score_science)::numeric, 1) as avg_science,
    count(*) as students
from students_aus
where gender is not null
group by 1;
/* 
gender|avg_math|avg_reading|avg_science|students|
------+--------+-----------+-----------+--------+
Female|   481.4|      510.3|      506.5|    6557|
Male  |   491.9|      487.8|      508.8|    6858|*/

-- 2.2 gender gap — difference (female - male)
select
    round(avg(case when gender = 'Female' then score_math end)::numeric
        - avg(case when gender = 'Male' then score_math end)::numeric, 1) as math_gap,
    round(avg(case when gender = 'Female' then score_reading end)::numeric
        - avg(case when gender = 'Male' then score_reading end)::numeric, 1) as reading_gap,
    round(avg(case when gender = 'Female' then score_science end)::numeric
        - avg(case when gender = 'Male' then score_science end)::numeric, 1) as science_gap
from students_aus
where gender is not null;
-- positive = female scores higher, negative = male scores higher
/* math_gap|reading_gap|science_gap|
--------+-----------+-----------+
   -10.5|       22.5|       -2.3| */


-- 2.3 at-risk rate by gender (below level 2)
select
    gender,
    round(sum(case when score_math < 420 then 1 else 0 end) * 100.0 / count(*), 1) as math_at_risk_pct,
    round(sum(case when score_reading < 407 then 1 else 0 end) * 100.0 / count(*), 1) as reading_at_risk_pct,
    round(sum(case when score_science < 410 then 1 else 0 end) * 100.0 / count(*), 1) as science_at_risk_pct
from students_aus
where gender is not null
group by 1;
/* gender|math_at_risk_pct|reading_at_risk_pct|science_at_risk_pct|
------+----------------+-------------------+-------------------+
Female|            26.3|               16.1|               17.8|
Male  |            26.3|               25.0|               20.3| */

-- 2.4 gender gap by school type
select
    sch.school_type,
    gender,
    round(avg(s.score_math)::numeric, 1)    as avg_math,
    round(avg(s.score_reading)::numeric, 1) as avg_reading,
    round(avg(s.score_science)::numeric, 1) as avg_science,
    count(*) as students
from students_aus s
join schools_aus sch on s.school_id = sch.school_id
where s.gender is not null
  and sch.school_type is not null
group by 1, 2
order by 1, 2;
/*school_type                 |gender|avg_math|avg_reading|avg_science|students|
----------------------------+------+--------+-----------+-----------+--------+
Private Government-dependent|Female|   482.6|      514.4|      508.7|    1942|
Private Government-dependent|Male  |   495.4|      494.2|      515.0|    1737|
Private independent         |Female|   524.0|      543.9|      544.9|    1105|
Private independent         |Male  |   536.4|      526.4|      547.6|    1187|
Public                      |Female|   466.2|      496.3|      492.3|    3311|
Public                      |Male  |   476.8|      473.5|      494.1|    3693|*/

-- -------------------------------------------------------------
-- section 3: socioeconomic equity (ESCS)
-- -------------------------------------------------------------

-- 3.1 escs quartiles vs average score
select
    ntile,
    round(avg(escs)::numeric, 2)          as avg_escs,
    round(avg(score_math)::numeric, 1)    as avg_math,
    round(avg(score_reading)::numeric, 1) as avg_reading,
    round(avg(score_science)::numeric, 1) as avg_science,
    count(*) as students
from (
    select *, ntile(4) over (order by escs) as ntile
    from students_aus
    where escs is not null
) q
group by 1
order by 1;
/* ntile|avg_escs|avg_math|avg_reading|avg_science|students|
-----+--------+--------+-----------+-----------+--------+
    1|   -0.78|   438.8|      455.0|      460.5|    3243|
    2|    0.22|   471.4|      483.1|      490.6|    3243|
    3|    0.82|   505.5|      519.0|      527.9|    3243|
    4|    1.32|   539.4|      547.6|      560.9|    3242|*/

-- 3.2 score gap between top and bottom escs quartile
with quartiles as (
    select *, ntile(4) over (order by escs) as ntile
    from students_aus
    where escs is not null
)
select
    round(avg(case when ntile = 4 then score_math end)::numeric
        - avg(case when ntile = 1 then score_math end)::numeric, 1) as math_gap,
    round(avg(case when ntile = 4 then score_reading end)::numeric
        - avg(case when ntile = 1 then score_reading end)::numeric, 1) as reading_gap,
    round(avg(case when ntile = 4 then score_science end)::numeric
        - avg(case when ntile = 1 then score_science end)::numeric, 1) as science_gap
from quartiles;
/*math_gap|reading_gap|science_gap|
--------+-----------+-----------+
   100.7|       92.6|      100.3|*/

-- 3.3 at-risk rate by escs quartile
select
    ntile,
    round(sum(case when score_math < 420 then 1 else 0 end) * 100.0 / count(*), 1) as math_at_risk,
    round(sum(case when score_reading < 407 then 1 else 0 end) * 100.0 / count(*), 1) as reading_at_risk,
    round(sum(case when score_science < 410 then 1 else 0 end) * 100.0 / count(*), 1) as science_at_risk
from (
    select *, ntile(4) over (order by escs) as ntile
    from students_aus
    where escs is not null
) q
group by 1
order by 1;
/*ntile|math_at_risk|reading_at_risk|science_at_risk|
-----+------------+---------------+---------------+
    1|        43.3|           33.1|           31.5|
    2|        29.7|           23.2|           21.8|
    3|        17.8|           13.6|           11.6|
    4|        11.6|           10.1|            8.7|*/

-- 3.4 escs vs score by school type — does private school amplify or reduce ses gap?
select
    sch.school_type,
    ntile,
    round(avg(s.score_reading)::numeric, 1) as avg_reading,
    count(*) as students
from (
    select *, ntile(4) over (order by escs) as ntile
    from students_aus
    where escs is not null
) s
join schools_aus sch on s.school_id = sch.school_id
where sch.school_type is not null
group by 1, 2
order by 1, 2;
/* school_type                 |ntile|avg_reading|students|
----------------------------+-----+-----------+--------+
Private Government-dependent|    1|      469.6|     692|
Private Government-dependent|    2|      492.1|     937|
Private Government-dependent|    3|      512.4|    1007|
Private Government-dependent|    4|      539.4|     970|
Private independent         |    1|      461.4|     183|
Private independent         |    2|      499.6|     371|
Private independent         |    3|      536.5|     658|
Private independent         |    4|      563.8|    1014|
Public                      |    1|      450.7|    2290|
Public                      |    2|      475.6|    1819|
Public                      |    3|      516.6|    1475|
Public                      |    4|      540.8|    1133| */

-- 3.5 correlation between escs and scores
select
    round(corr(escs, score_math)::numeric, 3)    as escs_math,
    round(corr(escs, score_reading)::numeric, 3) as escs_reading,
    round(corr(escs, score_science)::numeric, 3) as escs_science
from students_aus
where escs is not null;
/*escs_math|escs_reading|escs_science|
---------+------------+------------+
    0.385|       0.326|       0.356|*/

-- -------------------------------------------------------------
-- section 4: school factors
-- -------------------------------------------------------------

-- 4.1 score by school type
select
    sch.school_type,
    round(avg(s.score_math)::numeric, 1)    as avg_math,
    round(avg(s.score_reading)::numeric, 1) as avg_reading,
    round(avg(s.score_science)::numeric, 1) as avg_science,
    count(*) as students
from students_aus s
join schools_aus sch on s.school_id = sch.school_id
where sch.school_type is not null
group by 1
order by 2;
/* school_type                 |avg_math|avg_reading|avg_science|students|
----------------------------+--------+-----------+-----------+--------+
Public                      |   471.8|      484.4|      493.4|    7020|
Private Government-dependent|   488.7|      505.1|      511.8|    3685|
Private independent         |   530.4|      534.8|      546.3|    2292|*/

-- 4.2 score by location
select
    sch.location_community,
    round(avg(s.score_math)::numeric, 1)    as avg_math,
    round(avg(s.score_reading)::numeric, 1) as avg_reading,
    round(avg(s.score_science)::numeric, 1) as avg_science,
    count(*) as students
from students_aus s
join schools_aus sch on s.school_id = sch.school_id
where sch.location_community is not null
group by 1
order by 2;
/*location_community                                       |avg_math|avg_reading|avg_science|students|
---------------------------------------------------------+--------+-----------+-----------+--------+
A village, hamlet or rural area (fewer than 3 000 people)|   443.7|      454.2|      463.3|     348|
A small town (3 000 to about 15 000 people)              |   451.7|      466.0|      474.3|     916|
A town (15 000 to about 100 000 people)                  |   471.6|      488.2|      497.2|    2250|
A city (100 000 to about 1 000 000 people)               |   485.7|      500.6|      508.1|    3461|
A large city (1 000 000 to about 10 000 000 people)      |   507.8|      516.4|      525.9|    5363|*/

-- 4.3 class size vs score
select
    sch.class_size_test_language,
    round(avg(s.score_reading)::numeric, 1) as avg_reading,
    count(*) as students
from students_aus s
join schools_aus sch on s.school_id = sch.school_id
where sch.class_size_test_language is not null
group by 1
order by 1;
/* class_size_test_language|avg_reading|students|
------------------------+-----------+--------+
15 students or fewer    |      513.1|     180|
16-20 students          |      497.9|     914|
21-25 students          |      500.7|    5561|
26-30 students          |      507.0|    4234|
31-35 students          |      505.5|     195|
36-40 students          |      430.5|      18|
 */
-- 4.4 staff shortage vs score
select
    case
        when sch.shortage_educational_staff < 0 then '1. no shortage'
        when sch.shortage_educational_staff < 0.5 then '2. minor shortage'
        when sch.shortage_educational_staff < 1 then '3. moderate shortage'
        else '4. major shortage'
    end as shortage_level,
    round(avg(s.score_math)::numeric, 1)    as avg_math,
    round(avg(s.score_reading)::numeric, 1) as avg_reading,
    count(*) as students
from students_aus s
join schools_aus sch on s.school_id = sch.school_id
where sch.shortage_educational_staff is not null
group by 1
order by 1;
/*shortage_level      |avg_math|avg_reading|students|
--------------------+--------+-----------+--------+
1. no shortage      |   505.3|      517.0|    5253|
2. minor shortage   |   484.3|      496.6|    2301|
3. moderate shortage|   475.0|      488.5|    1918|
4. major shortage   |   468.3|      482.6|    1637|
 */ 

-- -------------------------------------------------------------
-- section 5: ICT & digital access
-- -------------------------------------------------------------

-- 5.1 ict computer availability vs score
select
    case
        when sch.ict_computers_availability < 0.5 then '1. low availability'
        when sch.ict_computers_availability < 0.8 then '2. moderate'
        when sch.ict_computers_availability <= 1.0 then '3. high'
        else '4. above 1 (extra devices)'
    end as computer_level,
    round(avg(s.score_math)::numeric, 1) as avg_math,
    round(avg(s.score_reading)::numeric, 1) as avg_reading,
    count(*) as students
from students_aus s
join schools_aus sch on s.school_id = sch.school_id
where sch.ict_computers_availability is not null
group by 1
order by 1;
/*computer_level            |avg_math|avg_reading|students|
--------------------------+--------+-----------+--------+
1. low availability       |   485.9|      498.3|    1258|
2. moderate               |   479.5|      495.5|     712|
3. high                   |   497.7|      510.3|    6145|
4. above 1 (extra devices)|   475.3|      489.6|    2298|
 */ 

-- 5.2 ict access by school type
select
    sch.school_type,
    round(avg(sch.ict_computers_availability)::numeric, 2) as avg_computers,
    round(avg(sch.ict_computers_with_internet)::numeric, 2) as avg_internet,
    round(avg(sch.ict_tablets_availability)::numeric, 2) as avg_tablets
from schools_aus sch
where sch.school_type is not null
  and sch.ict_computers_availability is not null
group by 1
order by 2;
/*school_type                 |avg_computers|avg_internet|avg_tablets|
----------------------------+-------------+------------+-----------+
Private independent         |         0.98|        0.99|       0.43|
Private Government-dependent|         1.01|        0.97|       0.27|
Public                      |         1.25|        0.98|       0.23|*/

-- 5.3 ict access by location — digital divide?
select
    sch.location_community,
    round(avg(sch.ict_computers_availability)::numeric, 2) as avg_computers,
    round(avg(sch.ict_computers_with_internet)::numeric, 2) as avg_internet,
    count(*) as schools
from schools_aus sch
where sch.location_community is not null
  and sch.ict_computers_availability is not null
group by 1
order by 2;
/*location_community                                       |avg_computers|avg_internet|schools|
---------------------------------------------------------+-------------+------------+-------+
A large city (1 000 000 to about 10 000 000 people)      |         1.02|        0.98|    240|
A city (100 000 to about 1 000 000 people)               |         1.12|        0.98|    145|
A town (15 000 to about 100 000 people)                  |         1.20|        0.97|    110|
A small town (3 000 to about 15 000 people)              |         1.39|        1.00|     46|
A village, hamlet or rural area (fewer than 3 000 people)|         1.64|        1.00|     17|
