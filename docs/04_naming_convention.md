# Naming Convention
## Finance Data Warehouse — Union Digital Bank | Finance Controllership

---

## Overview

Consistent naming is the first line of defense against confusion during handover, debugging, and audit. Every table, column, stored procedure, and key in this warehouse follows a predictable, readable pattern — so that any data engineer, financial controller, or auditor can understand the structure without needing to ask.

All names use **snake_case** (lowercase, words separated by underscores). No spaces. No special characters. No abbreviations unless listed below.

---

## Bronze Layer — Raw Ingestion Tables

Bronze tables preserve source data exactly as received. Names must reflect the origin system and the entity name — no renaming, no interpretation.

**Pattern:**
```
<source_system>_<entity>
```

| Segment | Description | Example Values |
|---|---|---|
| `<source_system>` | Name of the source system, abbreviated | `tm`, `sap` |
| `<entity>` | Exact entity or export name from the source system | `sl`, `gl` |

**Examples:**

| Table Name | Description |
|---|---|
| `tm_sl` | TM Subledger raw export from QuickSight |
| `sap_gl` | SAP General Ledger raw export |
| `treasury_soa` | Statement of Account files from Treasury Ops (bank recon) |

> **Rule:** Do not rename or interpret entities at the Bronze layer. If SAP exports a file called `gl`, the Bronze table is `sap_gl` — not `sap_general_ledger` or `sap_transactions`. The name must be traceable back to the source without ambiguity.

---

## Silver Layer — Cleansed Tables

Silver tables contain cleaned and standardized versions of Bronze data. Names follow the same source system + entity pattern to maintain traceability — the only difference is the data inside has been transformed.

**Pattern:**
```
<source_system>_<entity>
```

| Segment | Description | Example Values |
|---|---|---|
| `<source_system>` | Same source system prefix as Bronze | `tm`, `sap` |
| `<entity>` | Same entity name as Bronze | `sl`, `gl` |

**Examples:**

| Table Name | Description |
|---|---|
| `tm_sl` | Cleansed TM Subledger — duplicates removed, amounts normalized, reversal flag validated |
| `sap_gl` | Cleansed SAP GL — nulls resolved, transaction codes trimmed, dates standardized |
| `treasury_soa` | Cleansed SOA — format standardized across all 8 UBP + 3 BSP accounts |

> **Rule:** Bronze and Silver tables for the same entity share the same name. They are distinguished by their schema or layer context — not by their table name. In SQL Server Express (MVP), prefix queries with the schema or database name to distinguish them. In production (Redshift), Bronze lives in `finance_bronze` schema and Silver in `finance_silver`.

---

## Gold Layer — Business-Ready Tables & Views

Gold tables are built for business consumption. Names must be immediately meaningful to a financial controller — not a data engineer. Use business-aligned category prefixes instead of source system names.

**Pattern:**
```
<category>_<entity>
```

| Segment | Description | Example Values |
|---|---|---|
| `<category>` | Role of the table in the business model | `recon`, `summary`, `report` |
| `<entity>` | Business-meaningful name describing the content | `deposits`, `bank`, `exceptions` |

**Category Prefixes:**

| Prefix | Meaning | When to Use |
|---|---|---|
| `recon` | Reconciliation output | Line-level TM vs SAP or SOA vs SAP comparison tables |
| `summary` | Aggregated daily or monthly totals | Daily variance summaries, day-level status |
| `report` | Final reporting views for dashboards | CFO-facing or QuickSight-ready views |

**Examples:**

| Table / View Name | Description |
|---|---|
| `recon_deposits` | Line-level deposits recon output — TM SL vs SAP GL per transaction code per day |
| `recon_bank` | Line-level bank recon output — SOA vs SAP GL per line item per account per day |
| `summary_deposits_daily` | Daily aggregated deposits recon — total TM net vs total SAP, day status |
| `summary_bank_daily` | Daily aggregated bank recon — total SOA vs total SAP per account |
| `report_exceptions` | Filtered view of all non-MATCHED rows across both recon outputs |

> **Rule:** Gold names must be readable by a non-technical stakeholder. If a financial controller cannot understand what `recon_deposits` contains from its name alone, rename it.

---

## Surrogate Keys

All primary keys in dimension or reference tables use the `_key` suffix. Surrogate keys are system-generated integers — they have no business meaning and must never be exposed to end users as a reportable field.

**Pattern:**
```
<table_name>_key
```

| Segment | Description |
|---|---|
| `<table_name>` | Name of the table the key belongs to |
| `_key` | Suffix indicating this is a surrogate key |

**Examples:**

| Column Name | Table | Description |
|---|---|---|
| `transaction_key` | Any recon table | Surrogate key for a unique transaction record |
| `account_key` | Account reference table | Surrogate key for a bank account dimension |
| `recon_key` | `recon_deposits` | Surrogate key for a reconciliation output row |

> **Rule:** Never use a business identifier (e.g., `transaction_type_code`, `account_number`) as a primary key in Gold layer tables. Surrogate keys insulate the warehouse from upstream source system changes.

---

## Technical Columns

All system-generated metadata columns use the `dwh_` prefix. These columns are never sourced from the original CSV files — they are created by the warehouse load process to support traceability, debugging, and audit.

**Pattern:**
```
dwh_<column_name>
```

| Segment | Description |
|---|---|
| `dwh_` | Prefix exclusively for warehouse-generated metadata |
| `<column_name>` | Descriptive name indicating the column's purpose |

**Standard Technical Columns (applied to all layers):**

| Column Name | Data Type | Description |
|---|---|---|
| `dwh_load_date` | `DATE` | Date the record was loaded into this layer |
| `dwh_load_id` | `INT IDENTITY` | Auto-incremented surrogate row identifier |
| `dwh_source_file` | `VARCHAR(255)` | Name of the source CSV file loaded (for Bronze) |
| `dwh_created_at` | `DATETIME` | Timestamp of row creation |
| `dwh_is_valid` | `TINYINT` | Data quality flag — 1 = passed checks, 0 = failed |

> **Rule:** No business user should ever need to filter, group, or report on a `dwh_` column. If a `dwh_` column is appearing in a Gold layer output, it is a design error.

---

## Stored Procedures

All stored procedures responsible for loading data into a layer follow a single, predictable pattern. Anyone who opens the database for the first time must immediately know what each procedure does without reading its code.

**Pattern:**
```
load_<layer>
```

| Segment | Description |
|---|---|
| `load_` | Prefix indicating this procedure performs a data load |
| `<layer>` | The target layer: `bronze`, `silver`, or `gold` |

**Examples:**

| Procedure Name | Description |
|---|---|
| `load_bronze` | Truncates and reloads all Bronze staging tables from CSV source files |
| `load_silver` | Truncates and rebuilds all Silver cleansed tables from Bronze |
| `load_gold` | Truncates and rebuilds all Gold reconciliation outputs from Silver |

> **Rule:** Each stored procedure is responsible for exactly one layer. `load_bronze` must never write to Silver tables, and `load_silver` must never read directly from CSV files. Layer boundaries are enforced through procedure scope.

---

## Quick Reference Summary

| Object | Pattern | Example |
|---|---|---|
| Bronze table | `<source_system>_<entity>` | `sap_gl`, `tm_sl` |
| Silver table | `<source_system>_<entity>` | `sap_gl`, `tm_sl` |
| Gold table / view | `<category>_<entity>` | `recon_deposits`, `summary_bank_daily` |
| Surrogate key | `<table_name>_key` | `recon_key`, `account_key` |
| Technical column | `dwh_<column_name>` | `dwh_load_date`, `dwh_is_valid` |
| Stored procedure | `load_<layer>` | `load_bronze`, `load_silver`, `load_gold` |

---

For layer design details, refer to `docs/02_data_management_approach.md`.
For table schemas, refer to `deposits_recon.sql` and `bank_recon.sql`.
