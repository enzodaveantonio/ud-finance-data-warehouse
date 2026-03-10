# Finance Data Warehouse — MVP
### Union Digital Bank · Finance Controllership
> ⚠️ **Private Repository** — This repository contains proprietary financial systems documentation and transformation logic belonging to Union Digital Bank. Access is granted exclusively for recruitment and portfolio review purposes. Do not distribute, reproduce, or reuse any part of this codebase without explicit written permission.

---

## Overview

This repository contains the **MVP version** of UnionDigital Bank's Finance Data Warehouse — a SQL-based reconciliation engine built to automate the manual deposits and bank reconciliation process currently performed daily by the Financial Controllership team.

The MVP was designed, architected, and built by a single intern as a proof-of-concept, scoped intentionally to validate the reconciliation logic before full production deployment on the organization's existing Data Hub (Amazon Redshift). It is not the production system. It is the specification and working prototype that the Data Engineering team will migrate and scale.

**Problem it solves:** The FinCon team spends an estimated 5 hours per day manually extracting data from two source systems (TM Subledger via QuickSight and SAP General Ledger), copy-pasting figures into Excel, and computing variances by hand. This warehouse eliminates that process — ingesting the same CSV exports, running the reconciliation logic automatically, and generating the output in seconds.

**Estimated impact:** 60–70% reduction in manual reconciliation effort · Financial reports generated from hours to seconds · Single source of truth for deposits and bank reconciliation.

---

## ⚠️ MVP Scope & Limitations

This repository represents **Phase 1 MVP only**. The following constraints apply intentionally:

- **Platform:** SQL Server Express (local sandbox). Production target is Amazon Redshift.
- **Ingestion:** CSV flat files loaded via `BULK INSERT`. No live API or pipeline connections.
- **Historization:** Not implemented. Each run uses truncate-and-insert — latest dataset only.
- **Transformation tool:** Plain T-SQL. Production will use dbt Core.
- **Scheduling:** Manual execution. Production will use Airflow or dbt Cloud.
- **Scope:** Deposits reconciliation (TM SL vs SAP GL) and bank reconciliation (SOA vs SAP GL). Loans, procurement, and intercompany are out of scope for Phase 1.
- **Sample data:** CSV files in `/data/samples/` contain representative synthetic data only. No real customer or transaction data is stored in this repository.

---

## Architecture

This warehouse follows a **Medallion Architecture** with three progressive layers:

```
┌──────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                          │
│         TM Subledger (QuickSight)  ·  SAP General Ledger     │
│                Treasury Ops SOAs  ·  BSP SOAs                │
└───────────────────────┬──────────────────────────────────────┘
                        │ CSV Export (manual, MVP)
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                     BRONZE LAYER (T1)                        │
│              Raw ingestion — no transformation               │
│           staging_tm_sl  ·  staging_sap_gl                   │
│           staging_treasury_soa  ·  staging_sap_bank          │
└───────────────────────┬──────────────────────────────────────┘
                        │ load_silver
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                     SILVER LAYER (T2)                        │
│         Cleansed · Standardized · Validated                  │
│             clean_tm_sl  ·  clean_sap_gl                     │
│             clean_treasury_soa  ·  clean_sap_bank            │
└───────────────────────┬──────────────────────────────────────┘
                        │ load_gold
                        ▼
┌──────────────────────────────────────────────────────────────┐
│                      GOLD LAYER (T3)                         │
│           Business-ready · Finance-restricted                │
│     recon_deposits  ·  summary_deposits_daily                │
│     recon_bank  ·  summary_bank_daily  ·  report_exceptions  │
└──────────────────────────────────────────────────────────────┘
```

For the full architecture diagram, data flow, and data catalog, refer to the `/docs` folder.

---

## Repository Structure

```
finance-data-warehouse/
│
├── README.md                          ← You are here
│
├── docs/
│   ├── requirements.md                ← Project requirements & scope
│   ├── data_management_approach.md    ← Why Data Warehouse + Medallion Architecture
│   ├── naming_convention.md           ← Naming rules for all objects
│   ├── architecture_diagram.png       ← Full system architecture (draw.io export)
│   ├── data_flow_diagram.png          ← Bronze → Silver → Gold data flow
│   └── data_catalog.md                ← All tables, columns, types, and descriptions
│
├── data/
│   └── samples/                       ← Synthetic sample CSVs (no real data)
│       ├── staging_tm_sl.csv
│       └── staging_sap_gl.csv
│
├── scripts/
│   ├── bronze/
│   │   └── load_bronze.sql            ← Stored procedure: raw ingestion from CSV
│   ├── silver/
│   │   └── load_silver.sql            ← Stored procedure: cleansing & standardization
│   └── gold/
│       └── deposits_recon.sql         ← Stored procedure: reconciliation logic & output
│
└── tests/
    └── validation_checks.sql          ← Row count, null, and variance sanity checks
```

---

## Data Sources

| Source | System | Format | Layer | Scope |
|---|---|---|---|---|
| TM Subledger | QuickSight (Data Hub) | CSV export | Bronze → Silver | Deposits recon |
| SAP General Ledger | SAP ERP | CSV export | Bronze → Silver | Deposits recon + Bank recon |
| Treasury Ops SOA | SharePoint (manual) | CSV / Excel | Bronze → Silver | Bank recon |
| BSP SOA | BSP portal (manual) | CSV / Excel | Bronze → Silver | Bank recon |

---

## How to Run (MVP)

> Requires: SQL Server Express · SQL Server Management Studio (SSMS)

**Step 1 — Set up the database**
```sql
CREATE DATABASE FinanceWarehouse;
```

**Step 2 — Place CSV files**

Copy sample CSV files from `/data/samples/` into a local folder (e.g., `C:\finw\`).

**Step 3 — Run scripts in order**
```
1. scripts/bronze/load_bronze.sql      ← Load raw CSVs into staging tables
2. scripts/silver/load_silver.sql      ← Cleanse and standardize
3. scripts/gold/deposits_recon.sql     ← Generate reconciliation output
4. tests/validation_checks.sql         ← Verify output integrity
```

Each script is self-contained and includes inline comments explaining every step.

---

## Tech Stack

| Tool | Role | MVP | Production |
|---|---|---|---|
| SQL Server Express | Database engine | ✅ | ❌ |
| Amazon Redshift | Database engine | ❌ | ✅ |
| T-SQL | Transformation language | ✅ | Partial |
| dbt Core | Transformation framework | ❌ | ✅ |
| BULK INSERT | Data ingestion | ✅ | ❌ |
| Airbyte | Pipeline ingestion | ❌ | ✅ |
| SSMS | Query interface | ✅ | ❌ |
| Amazon QuickSight | Reporting & dashboards | ❌ | ✅ |

---

## Production Handover Notes

This MVP is designed to be portable. The reconciliation logic written in T-SQL translates directly to Redshift's PostgreSQL dialect with minimal syntax changes. The primary migration tasks for the Data Engineering team are:

1. Re-implement `load_bronze` as Airbyte pipelines from QuickSight and SAP connectors
2. Convert `load_silver` CTEs into dbt Core Silver models under `finance_silver` schema
3. Convert `load_gold` logic into dbt Gold models under `finance_gold` schema with RBAC
4. Schedule dbt runs via Airflow for daily T+1 refresh
5. Connect `recon_deposits` and `recon_bank` Gold tables to QuickSight dashboards

The SQL in this repository is the functional specification for those dbt models.

---

## About

**Built by:** Enzo De La Peña · Data Finance Intern · Union Digital Bank (Dec 2025 – Mar 2026)

**Supervised by:** Jef Lacson (CFO) · Vince (Data Finance SME) · Vic (Data Architecture & Engineering Lead)

**Validated by:** Jena & Tricia · Financial Controllership Team

*This project was scoped, architected, documented, and built independently as part of a Finance Transformation internship. The production deployment will be handled by the UD Data Engineering team post-internship.*
