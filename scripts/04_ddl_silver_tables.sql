
/*
================================================================================
Script: Create Silver Layer Tables (DDL)
================================================================================
Script Purpose:
    This script creates the raw staging tables in the 'silver' schema for the
    Deposits Reconciliation pipeline. It performs the following actions:
    - Drops existing silver tables if they already exist.
    - Creates silver.erp_sap_gl to stage raw SAP GL data from ERP.
    - Creates silver.core_tm_sl to stage raw TM SL data from Core.
	- Creates metadata columns: 
		>> dwh_create_date DATETIME2 DEFAULT GETDATE(),
		>> dwh_load_id INT IDENTITY(1,1),
		>> dwh_source_file NVARCHAR(255)

Scope:
    Deposits Reconciliation (Account 2121199) only.
    Bank Reconciliation tables are not yet included in this version.

Usage:
    Run once during initial setup, or re-run to rebuild silver tables.
================================================================================
*/


/*
================================================================================
1. Drop the table 'silver.erp_sap_gl' and then creates a new table with metadata columns
================================================================================
*/
IF OBJECT_ID('silver.erp_sap_gl', 'U') IS NOT NULL
	DROP TABLE silver.erp_sap_gl;

CREATE TABLE silver.erp_sap_gl(
	company_code NVARCHAR(50),
	account NVARCHAR(20),
	document_number NVARCHAR(50),
	document_type NVARCHAR(10),
	posting_date DATE,
	reference_key NVARCHAR(50),
	amount DECIMAL(18, 2),
	currency NVARCHAR(10),
	transaction_code NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_load_id INT IDENTITY(1,1),
    dwh_source_file NVARCHAR(255)
);

/*
================================================================================
2. Drop the table 'silver.core_tm_sl' and then creates a new table with metadata columns
================================================================================
*/

IF OBJECT_ID('silver.core_tm_sl', 'U') IS NOT NULL
	DROP TABLE silver.core_tm_sl;

CREATE TABLE silver.core_tm_sl(
	posting_date DATE,
	transaction_type_code NVARCHAR(50),
	transaction_category NVARCHAR(300),
	transaction_reversal_flag INT,
	transaction_amount DECIMAL(18, 2),
	dwh_create_date DATETIME2 DEFAULT GETDATE(),
    dwh_load_id INT IDENTITY(1,1),
    dwh_source_file NVARCHAR(255)
);
