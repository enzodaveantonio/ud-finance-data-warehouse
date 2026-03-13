/*
================================================================================
Script: Create Silver Layer Tables (DDL)
================================================================================
Script Purpose:
    This script creates the cleaned and transformed tables in the 'silver'
    schema for the Deposits Reconciliation pipeline. It performs the
    following actions:
    - Drops existing silver tables if they already exist.
    - Creates silver.erp_sap_je to store cleaned SAP Journal Entries data
      from bronze.erp_sap_je.
    - Creates silver.core_tm_sl_aggregates to store cleaned TM SL aggregates
      data from bronze.core_tm_sl_aggregates.
    - Adds enrichment columns for data quality flags and business context.
    - Adds metadata columns:
        dwh_create_date  DATETIME2  -- auto-populated on insert
        dwh_source_file  NVARCHAR   -- source file name for audit trail

Scope:
    Deposits Reconciliation (Account 2121199) only.
    Bank Reconciliation tables are not yet included in this version.

Usage:
    Run once during initial setup, or re-run to rebuild silver tables.
================================================================================
*/

/*
================================================================================
1. If the system detects that 'silver.erp_sap_je' exists, DROP TABLE removes the table. After, it creates another table named 'silver.erp_sap_je'
================================================================================
*/

IF OBJECT_ID('silver.erp_sap_je', 'U') IS NOT NULL
	DROP TABLE silver.erp_sap_je;

CREATE TABLE silver.erp_sap_je(
	cleared_open_items_symbol NVARCHAR(50),
	company_code NVARCHAR(20),
	account NVARCHAR(20),
	document_number NVARCHAR(50),
	document_type NVARCHAR(10),
	document_type_description NVARCHAR(100),
	is_reversal NVARCHAR(5),
	document_date DATE,
	posting_date DATE,
	is_prior_period_adjustment NVARCHAR(5),
	reference_key_3 NVARCHAR(50),
	amount_dr DECIMAL(18, 2),
	amount_cr DECIMAL(18, 2),
	local_currency NVARCHAR(10),
	tax_code NVARCHAR(10),
	clearing_document NVARCHAR(30),
	je_text NVARCHAR(300),
	profit_center NVARCHAR(10),
	cost_center NVARCHAR(10),
	transaction_code NVARCHAR(50),
	is_deposit_reversal NVARCHAR(10),
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_source_file NVARCHAR(255)
);

/*
================================================================================
2. If the system detects that 'silver.core_tm_sl_aggregates' exists, DROP TABLE removes the table. After, it creates another table named 'silver.core_tm_sl_aggregates'
================================================================================
*/


IF OBJECT_ID('silver.core_tm_sl_aggregates', 'U') IS NOT NULL
	DROP TABLE silver.core_tm_sl_aggregates;

CREATE TABLE silver.core_tm_sl_aggregates(
	transaction_posting_date DATE,
	transaction_code NVARCHAR(100),
	total_amount_dr DECIMAL(18, 2),
	total_amount_cr DECIMAL(18, 2),
	reversal_flag_0 DECIMAL(18, 2),
	reversal_flag_1 DECIMAL(18, 2),
	is_dr_cr_balanced NVARCHAR(10),
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_source_file NVARCHAR(255)
);

USE UDFinanceWarehouse



