# Medallion Architecture — Layer Design
## Finance Data Warehouse · Union Digital Bank | Finance Controllership
> Deposits Reconciliation & Bank Reconciliation MVP · SQL Server Express → Amazon Redshift

---

## Data Flow

```
🥉 Bronze Layer  ──────────►  🥈 Silver Layer  ──────────►  🥇 Gold Layer
  T1 · Raw Ingestion            T2 · Cleansed Data           T3 · Business-Ready Output
```

---

## Layer Comparison

| | 🥉 Bronze Layer · T1 · Raw Ingestion | 🥈 Silver Layer · T2 · Cleansed Data | 🥇 Gold Layer · T3 · Business-Ready Output |
|---|---|---|---|
| **Objective** | Preserve source data exactly as received from TM Subledger and SAP GL — no changes, no filtering. Serves as the audit trail and debugging baseline. | Cleanse, standardize, and enrich raw data to produce a trusted, joinable dataset. Resolves quality issues before any business logic is applied. | Deliver reconciliation-ready outputs for daily controller review. Replaces the manual Excel process with automatically generated, audit-ready reports. |
| **Object Type** | Tables | Tables | Views / Tables |
| **Load Method** | Full Load — Truncate & Insert on each run. CSV files loaded via `BULK INSERT`. | Full Load — Truncate & Insert from Bronze. Rebuilds clean dataset each run. | Derived — Generated from Silver via `INSERT`. No direct load from source. |
| **Data Transformation** | None — as-is from source | • **Cleaning** — remove duplicates, nulls<br>• **Standardization** — date formats, currency, casing<br>• **Normalization** — trim transaction codes for consistent joining<br>• **Derived Columns** — reversal flag separation, DR/CR sign convention<br>• **Enrichment** — account labels, transaction category mapping | • **Integration** — TM SL joined to SAP GL on transaction code + posting date<br>• **Aggregation** — sum by transaction code per day; daily totals<br>• **Business Logic** — variance calculation, `MATCHED` / `VARIANCE` / `TM ONLY` / `SAP ONLY` status flags |
| **Data Modeling** | None — as-is | None — flat cleaned tables | • **Flat Reconciliation Tables** — one row per transaction code per day<br>• **Aggregated Summary** — one row per day with totals and day status<br>• **Exception View** — filtered to non-`MATCHED` rows only |
| **Tables (MVP)** | `staging_tm_sl`<br>`staging_sap_gl` | `clean_tm_sl`<br>`clean_sap_gl` | `recon_deposits_output`<br>`recon_deposits_summary`<br>`recon_bank_output` |
| **Target Audience** | Data Engineers | Data Engineers · Data Analysts | Financial Controllers · Finance Head · CFO |
| **Access Control** | Finance + Data Engineering — Read-only after load. No manual edits permitted. | Finance + Data Engineering — Read-only. Rebuilt on each run. | Finance Only — RBAC-restricted. No direct write access by other tribes. |
| **Production (Redshift)** | T1 Schema — Airbyte pipelines from QuickSight + SAP connectors | T2 Schema — dbt Core models with automated data quality checks | Finance T3 Schema — dbt Gold models · QuickSight dashboards · RBAC enforced |

---

## Layer Detail

### 🥉 Bronze Layer — Raw Ingestion

The Bronze layer stores data exactly as it arrives from the source system. No transformation, no filtering, no business logic applied. Every row from the TM Subledger CSV and the SAP GL CSV is loaded here without modification.

**Why it matters for Finance:** If a reconciliation exception is disputed — by an auditor, by another tribe, or by BSP — the Bronze layer is the evidence trail. It proves what the source system said on that day, before any transformation touched it. The Bronze layer is not a technical nicety; it is a regulatory requirement in disguise.

```
Sources                         Bronze Tables
──────────────────────          ──────────────────────
TM Subledger (QuickSight)  →    staging_tm_sl
SAP General Ledger         →    staging_sap_gl
Treasury Ops SOA           →    staging_treasury_soa
SAP Bank GL                →    staging_sap_bank
```

---

### 🥈 Silver Layer — Cleansed Data

The Silver layer applies transformation logic to resolve data quality issues found in Bronze. A reconciliation output is only as trustworthy as the data underneath it — the Silver layer ensures that every variance surfaced in Gold is a real variance, not a data artifact.

**Transformations applied:**

| Transformation | Description |
|---|---|
| Cleaning | Remove duplicate rows; resolve null amounts |
| Standardization | Normalize date formats (`YYYY-MM-DD`); enforce `PHP` currency; uppercase transaction codes |
| Normalization | Trim whitespace from transaction codes to ensure consistent joining with SAP |
| Derived Columns | Separate `transaction_reversal_flag = 1` rows; standardize DR/CR sign convention |
| Enrichment | Map account numbers to account labels; apply transaction category descriptions |

```
Bronze Tables                   Silver Tables
──────────────────────          ──────────────────────
staging_tm_sl          →        clean_tm_sl
staging_sap_gl         →        clean_sap_gl
```

---

### 🥇 Gold Layer — Business-Ready Output

The Gold layer contains the final, business-facing output tables. These are the tables that the Financial Controller opens, reviews, and acts on. Column names are chosen to map directly to what the controller already looks for in the manual Excel reconciliation.

**Output tables:**

| Table | Description |
|---|---|
| `recon_deposits_output` | Line-level deposits recon — TM SL vs SAP GL per transaction code per day. Status: `MATCHED` / `VARIANCE` / `TM ONLY` / `SAP ONLY` |
| `recon_deposits_summary` | Daily aggregated deposits recon — total TM net vs total SAP, overall day status |
| `recon_bank_output` | Line-level bank recon — Treasury SOA vs SAP GL per line item per account per day |
| `report_exceptions` | Filtered view of all non-`MATCHED` rows across both recon outputs, ordered by variance magnitude |

---

## MVP vs. Production Mapping

| Dimension | MVP (SQL Server Express) | Production (Redshift + Data Hub) |
|---|---|---|
| Bronze | `staging_*` tables, CSV `BULK INSERT` | T1 schema, Airbyte pipelines |
| Silver | CTEs inside recon query | T2 schema, dbt Core models |
| Gold | `recon_*` output tables | Finance T3 schema, RBAC-restricted |
| Transformation tool | Plain T-SQL | dbt Core |
| Scheduling | Manual re-run | Airflow or dbt Cloud |
| Access control | Local sandbox | Redshift RBAC |
| Validation | Controller compares to Excel | Automated dbt data quality tests |

> The SQL written in this MVP is the functional specification for the dbt models Vic's team will build in production. The reconciliation logic does not change — only the platform and the tooling change.

---

*Finance Data Warehouse MVP · v1.0 · Union Digital Bank · 2026*
*SQL written here becomes the dbt specification for production.*
