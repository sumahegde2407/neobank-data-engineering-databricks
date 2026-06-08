# NeoBank Data Engineering Pipeline

A production-style, metadata-driven data engineering pipeline built on Databricks using Delta Lake, Autoloader, and Databricks Workflows.

---

## Overview

This project simulates a real-world banking data pipeline for a NeoBank. Data is ingested from multiple source systems, processed through Bronze → Silver → Gold layers, and surfaced as analytical tables ready for reporting and dashboarding.

The pipeline is fully metadata-driven — adding a new table requires zero code changes. Just insert a row into the metadata tables.

---

## Architecture

```
Source Systems (Delta Tables + Volume CSVs)
        ↓
    Bronze Layer    →   Raw ingestion, no transformation, audit columns added
        ↓
    Silver Layer    →   Incremental load — MERGE / APPEND / FULL based on table config
        ↓
    Gold Layer      →   Business-ready aggregations and analytical tables
```

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Databricks | Compute and job orchestration |
| Delta Lake | Storage format across all layers |
| Autoloader (cloudFiles) | Incremental file ingestion from Volumes |
| Databricks Workflows | Pipeline orchestration |
| Unity Catalog | Namespace, access control, and data governance |
| PySpark | Data processing where SQL is insufficient |
| SQL | Transformations, metadata queries, MERGE operations |

---

## Project Structure

```
neobank-data-engineering-databricks/
│
├── 01_Setup_Metadata/
│   ├── 01_Setup_Metadata.ipynb
│   ├── 02_Check_Metadata.ipynb
│   └── active_table_counts.ipynb
│
├── 02_Source_to_Silver/
│   ├── 01_Read_Tables_List.ipynb
│   ├── 02_Read_Table_Parameters.ipynb
│   ├── 03_Source_to_Bronze.ipynb
│   └── 04_Bronze_to_Silver.ipynb
│
├── 03_Silver_to_Gold/
│   ├── 01_Silver_to_Gold_Driver.ipynb
│   └── gold_transformations/
│       ├── customer_360.ipynb
│       ├── branch_performance.ipynb
│       ├── transaction_channel_summary.ipynb
│       ├── daily_bank_kpi.ipynb
│       └── risk_customer_summary.ipynb
│
└── README.md
```

---

## Metadata-Driven Framework

All pipeline behaviour is controlled by 4 metadata tables in `banking.metadata`:

| Table | Purpose |
|-------|---------|
| `tables` | Registry of all tables — source system, paths, load order, active flag |
| `table_parameters` | Key-value config per table: load_type, primary_key, watermark_column |
| `table_watermarks` | Last processed watermark value per table — enables incremental loading |
| `pipeline_runs` | Audit log — tracks INPROGRESS / SUCCESS / FAILED status per run |

**Adding a new table = one INSERT into metadata. Zero code changes.**

---

## Source Systems

| Source | Tables | Ingestion Method |
|--------|--------|-----------------|
| `delta` | customers, accounts, transactions, branches | `spark.read.table()` |
| `blob` | credit_bureau_reports, payment_gateway_logs | Autoloader (`cloudFiles`) |
| `silver` | Gold layer inputs | Direct Silver reads |

---

## Load Types

| Type | Behaviour | Tables |
|------|-----------|--------|
| `MERGE` | Upsert — update existing records, insert new ones | customers, accounts, credit_bureau_reports |
| `APPEND` | Insert only — every record is a new event | transactions, payment_gateway_logs |
| `FULL` | Truncate and reload | branches |

---

## Pipeline Results

### Silver Layer

| Table | Rows | Load Type |
|-------|------|-----------|
| customers | 4,000 | MERGE |
| accounts | 4,500 | MERGE |
| transactions | 15,000 | APPEND |
| branches | 4 | FULL |
| credit_bureau_reports | 5,000 | MERGE |
| payment_gateway_logs | 20,000 | APPEND |

### Gold Layer

| Table | Rows | Description |
|-------|------|-------------|
| customer_360 | 4,000 | Full customer view — accounts, transactions, credit score, segment |
| branch_performance | 4 | Branch-wise deposits, transactions, customer count |
| transaction_channel_summary | 5,716 | Daily gateway performance — success/fail rates, avg processing time |
| daily_bank_kpi | 396 | Daily bank-level KPIs — total transactions, balance, credit metrics |
| risk_customer_summary | 3 | Risk grade aggregations — avg credit score, overdue amounts |

---

## Workflow Design

```
Job: NeoBank_Source_to_Silver
    Task 1: Get_List_of_Tables       →  01_Read_Tables_List.py
    Task 2: Get_Table_Parameters     →  02_Read_Table_Parameters.py
    Task 3: Source_to_Bronze         →  03_Source_to_Bronze.py
    Task 4: Bronze_to_Silver         →  04_Bronze_to_Silver.py

Job: NeoBank_Silver_to_Gold
    Task 1: Get_List_of_Tables       →  01_Read_Tables_List.py
    Task 2: Silver_to_Gold           →  01_Silver_to_Gold_Driver.py
                                            → gold_transformations/{table_name}
```

---

## Key Design Decisions

**Metadata-driven framework** — table config lives in metadata, not in code. Load type, primary key, and watermark column are all read at runtime. Adding or disabling a table never touches pipeline code.

**Watermark-based incremental loading** — last processed timestamp stored in `table_watermarks`. Each run filters Bronze data using the watermark before writing to Silver. Watermark is updated only after a successful Silver load — ensuring no data loss if a run fails mid-way.

**Idempotent pipeline** — MERGE logic combined with deduplication on primary key ensures reprocessing the same data never creates duplicates in Silver.

**Audit trail** — every pipeline run is logged to `pipeline_runs` with INPROGRESS → SUCCESS / FAILED transitions. Error messages are captured on failure.

**SQL-first approach** — all transformations written in SQL. PySpark used only where SQL is insufficient: Autoloader ingestion, Delta MERGE operations, watermark aggregation.

**Separation of concerns** — each notebook has one job. Read metadata → Read parameters → Load Bronze → Load Silver. Gold transformations are isolated per table.

---

## Production Considerations

- In production, a master Databricks Workflow would chain Source-to-Silver and Silver-to-Gold jobs with dependencies and triggers
- For Each tasks (Databricks Workflows) would replace per-table manual runs, enabling parallel processing across all tables
- Data quality checks between Bronze and Silver would validate nulls, schema, and duplicates — bad records logged to a quarantine table
- Alerting via email or PagerDuty on job failure

---
