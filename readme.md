# NHS A&E Provider-Level Monthly Performance Dataset (2018–2025)

Cleaned, harmonised dataset combining monthly NHS A&E (Type 1, 2, 3) provider performance data from 2018 to 2025.

## Purpose

This repository contains processed and standardised monthly A&E attendance, 4-hour performance, admission, and decision-to-admit waiting time data at **provider / trust level**.

Raw files (Excel) were originally published by NHS England / NHS Digital and follow a relatively consistent — but not identical — layout across years. This pipeline:

- reads monthly files (2018–2025)
- skips metadata rows
- flattens multi-level headers
- removes percentage columns
- standardises column names
- adds `Month` + `Year` metadata
- concatenates everything into one clean dataset

## Final Output

**File**          | Description
-----------------|------------------------------------------------------
`Cleaned/master_dataset.csv` | Combined, cleaned dataset (~all providers × 96 months)

## Column Descriptions

Column                            | Description
----------------------------------|-------------------------------------------------------------------------
`Code`                            | Provider / Trust code (e.g. RA701, RAL01, …)
`Region`                          | NHS region / area (varies by year)
`Name`                            | Provider / Trust name
`Attend_Type1` / `Type2` / `Type3` / `Total` | Total attendances by A&E type
`Within4Hr_Type1` … `Within4Hr_Total` | Number seen & discharged/admitted within 4 hours
`Over4Hr_Type1` … `Over4Hr_Total` | Number breaching 4-hour standard
`Adm_AE_Type1` … `Adm_AE_Total`  | Admissions from A&E (Type 1/2/3)
`Adm_Other` / `Adm_Total`         | Other admissions + grand total admissions
`DecisionToAdm_Wait_4to12Hr`      | Decision to admit → admitted within 4–12 hours
`DecisionToAdm_Wait_Over12Hr`     | Decision to admit → admitted after 12 hours
`Month`                           | Full month name (January–December)
`Year`                            | 2018–2025

## Repository Structure

```text
├── Raw/
│   ├── 2018/
│   │   ├── January.xls
│   │   ├── February.xls
│   │   └── ...
│   ├── 2019/
│   └── ... (up to 2025)
├── Cleaned/
│   └── master_dataset.csv
└── README.md