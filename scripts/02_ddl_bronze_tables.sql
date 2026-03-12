/*
================================================================================
Script: Create Bronze Layer Tables (DDL)
================================================================================
Script Purpose:
    This script creates the raw staging tables in the 'bronze' schema for the
    Deposits Reconciliation pipeline. It performs the following actions:
    - Drops existing bronze tables if they already exist.
    - Creates bronze.erp_sap_gl to stage raw SAP GL data from ERP.
    - Creates bronze.core_tm_sl_aggregates to stage raw TM SL data from Core.

Scope:
    Deposits Reconciliation (Account 2121199) only.
    Bank Reconciliation tables are not yet included in this version.

Usage:
    Run once during initial setup, or re-run to rebuild bronze tables.
================================================================================
*/

/*
================================================================================
1. If the system detects that 'bronze.erp_sap_je' exists, DROP TABLE removes the table. After, it creates another table named 'bronze.erp_sap_je'
================================================================================
*/

IF OBJECT_ID('bronze.erp_sap_je', 'U') IS NOT NULL
	DROP TABLE bronze.erp_sap_je;

CREATE TABLE bronze.erp_sap_je(
	cleared_open_items_symbol NVARCHAR(50),
	company_code NVARCHAR(20),
	account NVARCHAR(20),
	document_number NVARCHAR(50),
	document_type NVARCHAR(10),
	document_date DATE,
	posting_date DATE,
	reference_key_3 NVARCHAR(50),
	amount_in_local_currency NVARCHAR(30),
	local_currency NVARCHAR(10),
	tax_code NVARCHAR(10),
	clearing_document NVARCHAR(30),
	je_text NVARCHAR(300),
	profit_center NVARCHAR(10),
	cost_center NVARCHAR(10),
	transaction_code NVARCHAR(50)
);

/*
================================================================================
2. If the system detects that 'bronze.core_tm_sl_aggregates' exists, DROP TABLE removes the table. After, it creates another table named 'bronze.core_tm_sl_aggregates'
================================================================================
*/


IF OBJECT_ID('bronze.core_tm_sl_aggregates', 'U') IS NOT NULL
	DROP TABLE bronze.core_tm_sl_aggregates;

CREATE TABLE bronze.core_tm_sl_aggregates(
	transaction_posting_date DATE,
	transaction_code NVARCHAR(100),
	total_amount_dr DECIMAL(18, 2),
	total_amount_cr DECIMAL(18, 2),
	reversal_flag_0 DECIMAL(18, 2),
	reversal_flag_1 DECIMAL(18, 2)
);
