/*
================================================================================
Script: Create Bronze Layer Tables (DDL)
================================================================================
Script Purpose:
    This script creates the raw staging tables in the 'bronze' schema for the
    Deposits Reconciliation pipeline. It performs the following actions:
    - Drops existing bronze tables if they already exist.
    - Creates bronze.erp_sap_gl to stage raw SAP GL data from ERP.
    - Creates bronze.core_tm_sl to stage raw TM SL data from Core.

Scope:
    Deposits Reconciliation (Account 2121199) only.
    Bank Reconciliation tables are not yet included in this version.

Usage:
    Run once during initial setup, or re-run to rebuild bronze tables.
================================================================================
*/

IF OBJECT_ID('bronze.erp_sap_gl', 'U') IS NOT NULL
	DROP TABLE bronze.erp_sap_gl;

CREATE TABLE bronze.erp_sap_gl(
	company_code NVARCHAR(50),
	account NVARCHAR(20),
	document_number NVARCHAR(50),
	document_type NVARCHAR(10),
	posting_date DATE,
	reference_key NVARCHAR(50),
	amount DECIMAL(18, 2),
	currency NVARCHAR(10),
	transaction_code NVARCHAR(50)
);

IF OBJECT_ID('bronze.core_tm_sl', 'U') IS NOT NULL
	DROP TABLE bronze.core_tm_sl;

CREATE TABLE bronze.core_tm_sl(
	posting_date DATE,
	transaction_type_code NVARCHAR(50),
	transaction_category NVARCHAR(300),
	transaction_reversal_flag INT,
	transaction_amount DECIMAL(18, 2)
);
