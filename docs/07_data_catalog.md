# Finance Data Warehouse — Data Catalog
**Version:** 1.0 | **Scope:** MVP — Deposits Reconciliation (Account 2121199) | **Bank Reconciliation:** Not yet included

---

## Overview

This document describes the table schemas, column definitions, and data lineage for the Finance Data Warehouse. The warehouse follows a medallion architecture with Bronze, Silver, and Gold layers. The current MVP scope covers the Deposits Reconciliation pipeline, comparing SAP ERP journal entries (account 2121199) against Core Banking TM SL aggregate data.

---

## Architecture

| Layer | Tables | Purpose |
|-------|--------|---------|
| Bronze | erp_sap_je, core_tm_sl_aggregates | Raw data as-is from source systems. No transformations. |
| Silver | erp_sap_je, core_tm_sl_aggregates | Cleaned, transformed, enriched. All accounts retained. |
| Gold | fact_deposits_movement (VIEW) | Business-ready. Filtered to deposits scope. UNION ALL of SAP + TM rows. |

---

## Data Sources

| Source | System | Extracted By | Delivery Method |
|--------|--------|--------------|-----------------|
| SAP Journal Entries | SAP ERP | FINCON | CSV export from SAP |
| TM SL Aggregates | Core Banking / Data Hub | FINCON | CSV download from Data Hub |

---

## Bronze Layer

> Raw staging tables. Data loaded as-is with no transformations. Metadata columns (`dwh_create_date`, `dwh_source_file`) appended on load.

### 1. bronze.erp_sap_je

- **Purpose:** Stores raw SAP Journal Entries as-is from the ERP system. No transformations applied. Source of truth for all SAP financial data across all accounts.

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| cleared_open_items_symbol | NVARCHAR(50) | SAP icon code indicating clearing status of the line item (e.g. `@5B\|QCleared@`, `@01\QPosted@`). Raw SAP export value. |
| company_code | NVARCHAR(20) | SAP company code identifying the legal entity. Expected value: `UDI`. |
| account | NVARCHAR(20) | SAP GL account number (7 digits). Account `2121199` = Savings Deposits. Used as primary filter for Deposits Reconciliation. |
| document_number | NVARCHAR(50) | Unique SAP document identifier per journal entry. Can appear multiple times for multi-line entries (debit and credit legs). |
| document_type | NVARCHAR(10) | SAP document type code. `ZA` = Automated, `SA` = Manual, `SB` = Batch, `AB` = Reversal, `KR` = Vendor Invoice, `KZ` = Vendor Payment, `WE` = Goods Receipt, `RE` = MIR7 Park, `KA` = Reversal-Vendor Invoice. |
| document_date | DATE | Date the original document was created in SAP. May differ from `posting_date` for prior period adjustments. |
| posting_date | DATE | Date the entry was posted to the General Ledger. Primary date used for reconciliation. |
| reference_key_3 | NVARCHAR(50) | SAP Reference Key 3 field. Standard length is 16 characters. Some entries may have non-standard lengths or alphanumeric values. |
| amount_in_local_currency | NVARCHAR(30) | Transaction amount stored as string to preserve raw SAP format (e.g. `1,256,633.43`). Negative = Credit, Positive = Debit. Converted to DECIMAL in silver layer. |
| local_currency | NVARCHAR(10) | Currency of the transaction. Expected value: `PHP` (Philippine Peso). |
| tax_code | NVARCHAR(10) | SAP tax code. Mostly NULL. `I0` = Input VAT, only appears on procurement document types (`RE`, `KR`). |
| clearing_document | NVARCHAR(30) | Reference to the clearing document number when an entry has been matched/offset. NULL = open/uncleared item. |
| je_text | NVARCHAR(300) | Free-text description of the journal entry. Contains reversal references (e.g. `Reversal on QPRH A000012716`) for `SB` document types. |
| profit_center | NVARCHAR(10) | 3-digit SAP profit center code representing a business unit or branch (e.g. 109, 111, 113). NULL for some document types. |
| cost_center | NVARCHAR(10) | 3-digit SAP cost center code. NULL for most entries in account 2121199. |
| transaction_code | NVARCHAR(50) | SAP Reference field mapped as transaction code. For account 2121199 `ZA` entries, contains structured codes (e.g. `IPTKOTCR00002B0`) used to join with TM SL. For other accounts, may contain free-text values. |

---

### 2. bronze.core_tm_sl_aggregates

- **Purpose:** Stores raw TM SL (Treasury Management Subledger) aggregate data extracted from the Core Banking Data Hub. Contains daily aggregated deposit movements per transaction code.

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| transaction_posting_date | DATE | Date of the deposit transaction as recorded in the Core Banking system. |
| transaction_code | NVARCHAR(100) | Structured transaction type code from Core Banking (e.g. `IPTKOTCR00001`, `ITMDIPDR00002A`). Primary join key for reconciliation with SAP. |
| total_amount_dr | DECIMAL(18,2) | Total debit amount for the transaction code on the given date. Always equals `total_amount_cr` in balanced entries. |
| total_amount_cr | DECIMAL(18,2) | Total credit amount for the transaction code on the given date. Always equals `total_amount_dr` in balanced entries. |
| reversal_flag_0 | DECIMAL(18,2) | Sum of original (non-reversed) transaction amounts for the code on the given date (`reversal_flag = 0` in raw subledger). |
| reversal_flag_1 | DECIMAL(18,2) | Sum of reversed transaction amounts for the code on the given date (`reversal_flag = 1` in raw subledger). Mostly zero; non-zero indicates a reversal occurred. |

---

## Silver Layer

> Cleaned and enriched tables. Data quality filters applied. Enrichment flags added. Amount fields converted to DECIMAL. All accounts retained — business-level filtering happens at gold.

### 3. silver.erp_sap_je

- **Purpose:** Cleaned, transformed, and enriched version of `bronze.erp_sap_je`. Applies data quality filters, standardizes values, converts amount to DECIMAL, and adds enrichment flags for reconciliation. Contains all accounts — filtering by account happens at the gold layer.

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| cleared_open_items_symbol | NVARCHAR(50) | Standardized clearing status. Translated from raw SAP icon codes: NULL → `Open`, `%Cleared%` → `Cleared`, `%Posted%` → `Posted`. |
| company_code | NVARCHAR(20) | SAP company code. Rows with NULL `company_code` are excluded during silver load. |
| account | NVARCHAR(20) | SAP GL account number. Rows with NULL `account` are excluded during silver load. |
| document_number | NVARCHAR(50) | SAP document number. Rows with NULL `document_number` are excluded during silver load. |
| document_type | NVARCHAR(10) | SAP document type code. Uppercased during transformation. Rows with NULL `document_type` are excluded. |
| document_type_description | NVARCHAR(100) | Human-readable document type label. `ZA` = Automated Journal Entry, `SA` = Manual Journal Entry, `SB` = Batch Journal Entry, `AB` = Reversal - Journal Entry, `KR` = Vendor Invoice, `KZ` = Vendor Payment, `WE` = Goods Receipt, `RE` = MIR7 - Park, `KA` = Reversal - Vendor Invoice. |
| is_reversal | NVARCHAR(5) | Y/N flag indicating if the entry is a reversal. `Yes` for document types `AB`, `KA`, `SB`. |
| document_date | DATE | Original document creation date in SAP. |
| posting_date | DATE | GL posting date. Rows with NULL `posting_date` are excluded during silver load. |
| is_prior_period_adjustment | NVARCHAR(5) | Y/N flag. `Yes` when `document_date` and `posting_date` are in different months, indicating a prior period adjustment entry. |
| reference_key_3 | NVARCHAR(50) | SAP Reference Key 3. Retained as-is from bronze for traceability. |
| amount_in_local_currency | DECIMAL(18,2) | Transaction amount converted from NVARCHAR to DECIMAL. Commas stripped during conversion. Negative = Credit, Positive = Debit. |
| amount_dr | DECIMAL(18,2) | Debit amount. Positive `amount_in_local_currency` values only. NULL for credit entries. |
| amount_cr | DECIMAL(18,2) | Credit amount. Absolute value of negative `amount_in_local_currency` values. NULL for debit entries. |
| local_currency | NVARCHAR(10) | Transaction currency. Expected value: `PHP`. |
| tax_code | NVARCHAR(10) | SAP tax code. Retained as-is. Mostly NULL. |
| clearing_document | NVARCHAR(30) | Clearing document reference. NULL for open/uncleared items. |
| je_text | NVARCHAR(300) | Journal entry description. Retained as-is from bronze. |
| profit_center | NVARCHAR(10) | SAP profit center code (branch/business unit). |
| cost_center | NVARCHAR(10) | SAP cost center code. |
| transaction_code | NVARCHAR(50) | SAP transaction code (Reference field). For account 2121199, contains structured deposit codes with a trailing digit (e.g. `IPTKOTCR00002B0`). Trailing digit stripped at gold layer for reconciliation. |
| is_deposit_reversal | NVARCHAR(5) | Y/N flag specific to deposit transaction codes (`IPTKOT%`, `ITMDIP%`, `RTMDET%`). `Yes` if trailing digit = `1` (reversal). Pending confirmation with Jena. |
| dwh_create_date | DATETIME2 | Auto-populated timestamp when the row was inserted into the silver table. Default: `GETDATE()`. |
| dwh_source_file | NVARCHAR(255) | Source file name for audit trail (e.g. `sap_je.csv`). |

---

### 4. silver.core_tm_sl_aggregates

- **Purpose:** Cleaned and validated version of `bronze.core_tm_sl_aggregates`. Filters out invalid dates and NULL values. Adds a DR/CR balance check flag. Data from the Core Banking lakehouse is generally clean — this layer serves as a validation confirmation layer.

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| transaction_posting_date | DATE | Posting date of the TM transaction. Filtered to exclude NULLs and dates before 2020-01-01 or in the future. |
| transaction_code | NVARCHAR(100) | Structured deposit transaction code (e.g. `IPTKOTCR00001`). Primary join key for gold layer reconciliation. Filtered to exclude NULLs. |
| total_amount_dr | DECIMAL(18,2) | Total debit amount for the code on the given date. Filtered to exclude NULLs and negatives. |
| total_amount_cr | DECIMAL(18,2) | Total credit amount for the code on the given date. Filtered to exclude NULLs and negatives. |
| reversal_flag_0 | DECIMAL(18,2) | Sum of original transaction amounts (non-reversed). Filtered to exclude NULLs and negatives. |
| reversal_flag_1 | DECIMAL(18,2) | Sum of reversed transaction amounts. Mostly zero. Non-zero indicates a reversal occurred on that date for the code. |
| is_dr_cr_balanced | NVARCHAR(5) | Data quality flag. `Yes` when `total_amount_dr = total_amount_cr`. `No` flags a potential data quality issue from the source system. |
| dwh_create_date | DATETIME2 | Auto-populated timestamp when the row was inserted into the silver table. Default: `GETDATE()`. |
| dwh_source_file | NVARCHAR(255) | Source file name for audit trail (e.g. `tm_sl_aggregates.csv`). |

---

## Gold Layer

> Business-ready views. Scoped to Deposits Reconciliation. SAP and TM data combined using UNION ALL for side-by-side comparison. Recon aggregation and variance analysis performed downstream on top of this view.

### 5. gold.fact_deposits_movement (VIEW)

- **Purpose:** Gold layer view combining SAP and TM deposit movements using UNION ALL. Each row is tagged with its source system. SAP rows contain deposit-related transaction codes only (`IPTKOT%`, `ITMDIP%`, `RTMDET%`). TM rows contain all aggregate entries from silver. The recon comparison is performed after this view by aggregating and comparing by `posting_date` and `transaction_code`.

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| posting_date | DATE | Transaction posting date. From `posting_date` (SAP) or `transaction_posting_date` (TM). |
| transaction_code | NVARCHAR(100) | Unified transaction code. SAP codes have trailing digit stripped using `LEFT(transaction_code, LEN-1)`. TM codes used as-is. Enables `GROUP BY` for recon aggregation. |
| source_system | NVARCHAR(5) | `SAP` or `TM` — identifies which source system the row came from. Used for filtering and recon reporting. |
| sap_amount_dr | DECIMAL(18,2) | SAP debit amount from `silver.erp_sap_je`. NULL for TM rows. |
| sap_amount_cr | DECIMAL(18,2) | SAP credit amount from `silver.erp_sap_je`. NULL for TM rows. |
| sap_deposit_reversal | NVARCHAR(5) | `is_deposit_reversal` flag inherited from silver. `Yes` for deposit reversal entries. NULL for TM rows. |
| tm_amount_dr | DECIMAL(18,2) | TM total debit amount from `silver.core_tm_sl_aggregates`. NULL for SAP rows. |
| tm_amount_cr | DECIMAL(18,2) | TM total credit amount from `silver.core_tm_sl_aggregates`. NULL for SAP rows. |
| tm_not_reversal_amount | DECIMAL(18,2) | TM `reversal_flag_0` — sum of original (non-reversed) amounts. NULL for SAP rows. |
| tm_reversal_amount | DECIMAL(18,2) | TM `reversal_flag_1` — sum of reversed amounts. Mostly zero. NULL for SAP rows. |

---

## Notes & Open Items

| # | Item | Status |
|---|------|--------|
| 1 | SAP `transaction_code` trailing digit rule — confirm with Jena if trailing `0` = original and `1` = reversal for ALL deposit codes | ⏳ Pending — Jena |
| 2 | TM SL aggregates to be replaced with actual subledger data from Data Hub in future version | 📋 Planned — Post MVP |
| 3 | Bank Reconciliation tables (`trea_ubp_cash_soa`, `bsp_cash_soa`) not yet included | 📋 Planned — Post MVP |
| 4 | Finnacle (Loans) data to be added per CFO request | ⏳ Pending — Scope TBD |
| 5 | Profit center to branch mapping — confirm with Jena if 109/111/113 correspond to specific branches | ⏳ Pending — Jena |
| 6 | Incremental loading strategy for monthly SAP files — replace TRUNCATE with watermark-based MERGE | 📋 Planned — Post MVP |

---

*CONFIDENTIAL — Internal Use Only | UnionDigital Bank Inc. | Finance Data Warehouse v1.0*
