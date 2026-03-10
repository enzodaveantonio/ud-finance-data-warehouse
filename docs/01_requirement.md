# Project Requirements
## Finance Data Warehouse — Deposits & Bank Reconciliation MVP
### Union Digital Bank | Finance Controllership

---

## Data Engineering: Building the Finance Data Warehouse

### Objective
Develop a Finance Data Warehouse using SQL Server to consolidate subledger and general ledger data, automating the manual reconciliation process currently performed by the Financial Controllership team and reducing daily reconciliation time by an estimated 60–70%.

### Specifications

- **Data Sources:** Import data from two source systems — TM Subledger (via QuickSight CSV export) and SAP General Ledger (via SAP CSV export) — provided as flat CSV files for MVP Phase 1.
- **Data Quality:** Cleanse and resolve data quality issues prior to analysis, including duplicate detection, null amount checks, reversal flag validation, and transaction code format standardization.
- **Integration:** Combine both sources into a single reconciliation output model designed for daily variance analysis, joining on transaction code and posting date.
- **Scope:** Focus on the latest dataset only; historization of data is not required for MVP Phase 1. Truncate-and-insert pattern applies.
- **Documentation:** Provide clear documentation of the data model — including staging table schemas, transformation logic, and reconciliation output structure — to support both the Financial Controller and the Data Engineering team during handover.

---

## Data Analysis: Reconciliation Reporting

### Objective
Develop SQL-based reconciliation outputs to deliver daily visibility into:

- **Deposits Reconciliation** — TM Subledger vs. SAP GL variance per transaction code per day (Account 2121199, Savings Deposits)
- **Bank Reconciliation** — SOA vs. SAP GL variance per line item per bank account per day (8 UBP accounts + 3 BSP accounts)
- **Exception Reporting** — Flagging unmatched, variance, TM-only, and SAP-only transactions for controller review

These outputs replace the manual Excel reconciliation currently performed daily, empowering the Financial Controllership team with automatically generated, audit-ready reports.

---

## Constraints

- **Platform:** SQL Server Express (local sandbox). Migration to Amazon Redshift to be handled by the Data Engineering team post-handover.
- **Access:** CSV files loaded locally. No direct connection to Data Hub, QuickSight, or SAP in MVP phase.
- **Timeline:** MVP to be completed and validated by Jena / Tricia before internship end (~March 28, 2026).
- **Historization:** Not in scope for Phase 1. Each run truncates and reloads the output tables.
- **Excluded sources:** Sunline (loans), Union Bank parent-dependent systems — excluded due to unvalidated data quality.

---

For architecture details, refer to `docs/architecture.md`.  
For reconciliation logic, refer to `deposits_recon.sql` and `bank_recon.sql`.
