drop database nhs_ae;
create database if not exists nhs_ae;
use nhs_ae;


-- Create a staging table matching the csv
CREATE TABLE if not exists  stg_ae (
    Code VARCHAR(20),
    Region VARCHAR(100),
    Name VARCHAR(255),
    Attend_Type1 INT,
    Attend_Type2 INT,
    Attend_Type3 INT,
    Attend_Total INT,
    Within4Hr_Type1 INT,
    Within4Hr_Type2 INT,
    Within4Hr_Type3 INT,
    Within4Hr_Total INT,
    Over4Hr_Type1 INT,
    Over4Hr_Type2 INT,
    Over4Hr_Type3 INT,
    Over4Hr_Total INT,
    Adm_AE_Type1 INT,
    Adm_AE_Type2 INT,
    Adm_AE_Type3 INT,
    Adm_AE_Total INT,
    Adm_Other INT,
    Adm_Total INT,
    DecisionToAdm_Wait_4to12Hr INT,
    DecisionToAdm_Wait_Over12Hr INT,
    Month VARCHAR(20),
    Year INT
);

Show variables like 'secure_file_priv';

Load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/master_dataset.csv'
into table stg_ae
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
ignore 1 lines
(Code, Region, Name, 
Attend_Type1, Attend_Type2,Attend_Type3,Attend_Total, 
Within4Hr_Type1, Within4Hr_Type2,Within4Hr_Type3, Within4Hr_Total,
Over4Hr_Type1,Over4Hr_Type2, Over4Hr_Type3, Over4Hr_Total,
Adm_AE_Type1,Adm_AE_Type2,Adm_AE_Type3,Adm_AE_Total,
Adm_Other,Adm_Total,
DecisionToAdm_Wait_4to12Hr,DecisionToAdm_Wait_Over12Hr,
Month, Year);

SELECT 
    *
FROM
    stg_ae
LIMIT 50;

-- simple dimension date table

CREATE TABLE dim_date (
    date_id INT AUTO_INCREMENT PRIMARY KEY,
    date_val DATE UNIQUE,
    year_val INT,
    month_num INT,
    month_name VARCHAR(20),
    year_month_str VARCHAR(7)
);


insert into dim_date(date_val,year_val,month_num,month_name,year_month_str)
select distinct
 str_to_date(concat(Year, '-', Month, '-01'), '%Y-%M-%d') as date_val,
 Year as year_val,
 month(str_to_date(concat(Year, '-', Month, '-01'), '%Y-%M-%d')) as month_num,
 Month as month_name,
 date_format(str_to_date(concat(Year, '-', Month, '-01'), '%Y-%M-%d'), '%Y-%m') as year_month_str
from stg_ae;


select * from dim_date;

create table dim_provider(
	provider_id int auto_increment primary key,
    code varchar(20),
	Name Varchar (255),
    Region Varchar(100)
);

insert into dim_provider(Code, Name, Region)
select 
Code, Max(Name) as Name, Max(Region) as Region
from stg_ae
where Code is not Null
Group by Code;

SELECT 
    *
FROM
    dim_provider;

-- fact table

CREATE TABLE fact_ae (
    fact_id int auto_increment primary key,
    date_id int,
    provider_id int,
    Attend_Type1 INT,
    Attend_Type2 INT,
    Attend_Type3 INT,
    Attend_Total INT,
    Within4Hr_Type1 INT,
    Within4Hr_Type2 INT,
    Within4Hr_Type3 INT,
    Within4Hr_Total INT,
    Over4Hr_Type1 INT,
    Over4Hr_Type2 INT,
    Over4Hr_Type3 INT,
    Over4Hr_Total INT,
    Adm_AE_Type1 INT,
    Adm_AE_Type2 INT,
    Adm_AE_Type3 INT,
    Adm_AE_Total INT,
    Adm_Other INT,
    Adm_Total INT,
    DecisionToAdm_Wait_4to12Hr INT,
    DecisionToAdm_Wait_Over12Hr INT,
    constraint fk_fact_date foreign key(date_id)
    references dim_date(date_id),
    constraint fk_fact_provider foreign key (provider_id)
    references dim_provider(provider_id)
);


insert into fact_ae(
    date_id,
    provider_id,
    Attend_Type1,
    Attend_Type2,
    Attend_Type3,
    Attend_Total,
    Within4Hr_Type1,
    Within4Hr_Type2,
    Within4Hr_Type3,
    Within4Hr_Total,
    Over4Hr_Type1,
    Over4Hr_Type2,
    Over4Hr_Type3,
    Over4Hr_Total,
    Adm_AE_Type1,
    Adm_AE_Type2,
    Adm_AE_Type3,
    Adm_AE_Total,
    Adm_Other,
    Adm_Total,
    DecisionToAdm_Wait_4to12Hr,
    DecisionToAdm_Wait_Over12Hr)
select 
	d.date_id,
    p.provider_id,
    s.Attend_Type1, s.Attend_Type2, s.Attend_Type3, s.Attend_Total,
    s.Within4Hr_Type1, s.Within4Hr_Type2, s.Within4Hr_Type3, s.Within4Hr_Total,
    s.Over4Hr_Type1, s.Over4Hr_Type2, s.Over4Hr_Type3, s.Over4Hr_Total,
    s.Adm_AE_Type1,  s.Adm_AE_Type2,  s.Adm_AE_Type3,  s.Adm_AE_Total,
    s.Adm_Other, s.Adm_Total,
    s.DecisionToAdm_Wait_4to12Hr, s.DecisionToAdm_Wait_Over12Hr
from stg_ae s
join dim_date d
on d.date_val= str_to_date(concat(s.Year,'-',s.Month, '-01'),'%Y-%M-%d')
join dim_provider p
on p.Code=s.Code;


select * from fact_ae limit 100;


-- create views with useful metrics
-- 4 hr performance and admission ratios

CREATE VIEW vw_ae_metrics AS
SELECT
    f.fact_id,
    d.date_val,
    d.year_val,
    d.month_num,
    d.month_name,
    d.year_month_str,
    p.provider_id,
    p.Code,
    p.Name,
    p.Region,
    f.Attend_Type1,
    f.Attend_Type2,
    f.Attend_Type3,
    f.Attend_Total,
    f.Within4Hr_Total,
    f.Over4Hr_Total,
    f.Adm_AE_Total,
    f.Adm_Other,
    f.Adm_Total,
    f.DecisionToAdm_Wait_4to12Hr,
    f.DecisionToAdm_Wait_Over12Hr,
    CASE
        WHEN f.Attend_Total > 0
        THEN ROUND(100.0 * f.Within4Hr_Total / f.Attend_Total, 2)
        ELSE NULL
    END AS Pct_Within4Hr,
    CASE
        WHEN f.Attend_Total > 0
        THEN ROUND(100.0 * f.Adm_AE_Total / f.Attend_Total, 2)
        ELSE NULL
    END AS Pct_Attendances_Admitted,
    CASE
        WHEN f.Adm_AE_Total > 0
        THEN ROUND(100.0 * f.DecisionToAdm_Wait_4to12Hr / f.Adm_AE_Total, 2)
        ELSE NULL
    END AS Pct_Adm_Wait_4to12Hr,
    CASE
        WHEN f.Adm_AE_Total > 0
        THEN ROUND(100.0 * f.DecisionToAdm_Wait_Over12Hr / f.Adm_AE_Total, 2)
        ELSE NULL
    END AS Pct_Adm_Wait_Over12Hr
FROM fact_ae f
JOIN dim_date d     ON f.date_id = d.date_id
JOIN dim_provider p ON f.provider_id = p.provider_id;

select * from vw_ae_metrics;

-- trust specific time series analysis
SELECT
    year_month_str,
    Attend_Total,
    Pct_Within4Hr,
    Pct_Adm_Wait_4to12Hr,
    Pct_Adm_Wait_Over12Hr
FROM vw_ae_metrics
WHERE Name = 'Barts Health NHS Trust'
ORDER BY date_val;

-- London region monthly totals
SELECT 
    year_month_str,
    SUM(Attend_Total) AS London_Attendances,
    ROUND(100.0 * SUM(Within4Hr_Total) / NULLIF(SUM(Attend_Total), 0),
            2) AS London_Pct_Within4Hr
FROM
    vw_ae_metrics
WHERE
    Region LIKE 'NHS England London%'
        OR Region LIKE 'London Commissioning%'
GROUP BY year_month_str
ORDER BY year_month_str;

-- Provider avg monthly performance last 12 month

SELECT
    Name,
    Region,
    AVG(Attend_Total) AS Avg_Monthly_Attendances,
    ROUND(
        100.0 * SUM(Within4Hr_Total) / NULLIF(SUM(Attend_Total), 0),
        2
    ) AS Pct_Within4Hr_LastYear
FROM vw_ae_metrics
WHERE year_val = 2025
GROUP BY Name, Region
HAVING SUM(Attend_Total) > 5000
ORDER BY Pct_Within4Hr_LastYear DESC;

-- volume vs performance
SELECT
    Name,
    year_month_str,
    Attend_Total,
    Pct_Within4Hr
FROM vw_ae_metrics;



-- creating a table to hold forecasted data from python:

create table fact_ae_forecast(
id int auto_increment primary key,
scope varchar(50),
date_val date,
yhat double,
yhat_lower double,
yhat_upper double
);

select  * from fact_ae_forecast_tmp;

delete from fact_ae_forecast where scope='national';

insert into fact_ae_forecast (scope,date_val,yhat,yhat_lower,yhat_upper)
select scope, ds,yhat,yhat_lower, yhat_upper 
from fact_ae_forecast_tmp;

select * from fact_ae_forecast;
