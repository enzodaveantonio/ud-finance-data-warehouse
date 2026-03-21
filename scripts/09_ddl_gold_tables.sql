/*
================================================================================
Script: Create Gold Layer Tables (DDL)
================================================================================
Script Purpose:
    This script creates the business-ready analytical tables in the 'gold'
    schema for the Deposits Reconciliation pipeline. It performs the
    following actions:
    - Drops existing gold tables if they already exist.
    - Creates gold.fact_deposits_movement to store unified transaction-level
      data from both SAP (silver.erp_sap_je) and TM (silver.core_tm_sl_aggregates).
    - Creates gold.dim_transaction_codes to store transaction code metadata
      and classification logic for both SAP and TM systems.
    - Supports reconciliation analysis by maintaining:
        >> Transaction-level granularity for drill-down capabilities
        >> Source system attribution (SAP vs TM)
        >> Reversal flags (Normal vs Reversal transactions)
        >> Account numbers for filtering by deposit type
    - Adds metadata columns:
        is_active        BIT        -- flag for active/inactive codes
        date_created     DATETIME2  -- auto-populated on insert

Scope:
    Deposits Reconciliation covering:
    - Savings Deposits (Account 2121199)
    - Time Deposits (Account 2141101)
    Bank Reconciliation tables are not yet included in this version.

Usage:
    Run once during initial setup, or re-run to rebuild gold tables.
    Tables are populated by the gold.load_gold stored procedure.
================================================================================
*/

/*
================================================================================
1. If the system detects that 'gold.fact_deposits_movement' exists, DROP TABLE removes the table. After, it creates another table named 'gold.fact_deposits_movement'
================================================================================
*/

IF OBJECT_ID('gold.fact_deposits_movement', 'U') IS NOT NULL
	DROP TABLE gold.fact_deposits_movement;

CREATE TABLE gold.fact_deposits_movement(
	posting_date DATE,
	sap_transaction_code NVARCHAR(50),
	sap_account_num NVARCHAR(50),
	sap_amount_dr DECIMAL(18,2),
	sap_amount_cr DECIMAL(18,2),
	sap_deposit_reversal NVARCHAR(20),
	tm_transaction_code NVARCHAR(50),
	tm_amount_dr DECIMAL(18,2),
	tm_amount_cr DECIMAL(18,2),
	tm_deposit_reversal NVARCHAR(50),
	source_system NVARCHAR (20)
);

/*
================================================================================
2. If the system detects that 'gold.dim_transaction_codes' exists, DROP TABLE removes the table. After, it creates another table named 'gold.dim_transaction_codes'
================================================================================
*/

IF OBJECT_ID('gold.dim_transaction_codes', 'U') IS NOT NULL
	DROP TABLE gold.dim_transaction_codes;

CREATE TABLE gold.dim_transaction_codes(
	transaction_code NVARCHAR(50),
	transaction_base_code NVARCHAR(100),
	normal_or_reversal NVARCHAR(50),
	source_system NVARCHAR(50),
	is_active BIT DEFAULT 1,
	date_created DATETIME2 DEFAULT GETDATE()

);
