/*
================================================================================
Script: Load Gold Layer Tables
================================================================================
Script Purpose:
    This script loads business-ready data into the 'gold' schema for the 
    Deposits Reconciliation pipeline. It performs the following actions:
    - Inserts unified transaction data from silver.erp_sap_je and 
      silver.core_tm_sl_aggregates into gold.fact_deposits_movement.
    - Inserts transaction code metadata into gold.dim_transaction_codes.
    - Applies the following transformations:
        >> Fact Table (gold.fact_deposits_movement):
           - Combines SAP and TM deposits transactions via UNION ALL
           - Filters SAP data to deposits-related transaction codes only
           - Maintains source system attribution (SAP vs TM)
           - Preserves transaction-level granularity for drill-down analysis
        >> Dimension Table (gold.dim_transaction_codes):
           - Extracts distinct transaction codes from both SAP and TM systems
           - Derives transaction_base_code (code without reversal indicator)
           - Marks source_system as 'SAP', 'TM', or 'Both' based on overlap
           - Links Normal/Reversal classification from silver layer
    - Enables reconciliation reporting and variance analysis at daily/monthly levels.
    - Supports filtering by account number, transaction code, and reversal status.

Scope:
    Deposits Reconciliation only.
    Covers both Savings Deposits (2121199) and Time Deposits (2141101).
    Bank Reconciliation tables are not yet included in this version.

Usage:
    Run after the Silver Layer has been successfully loaded.
    Re-runnable — gold tables are truncated before each load.
    EXEC gold.load_gold
================================================================================
*/

/* 
TABLE OF CONTENTS
1. Loading the Gold Layer and Getting the Batch Start/End Time
2. Truncating and Inserting Data into: 'gold.fact_deposits_movement'
3. Truncating and Inserting Data into: 'gold.dim_transaction_codes'
*/


CREATE OR ALTER PROCEDURE gold.load_gold AS

BEGIN

/*
===================================================================================
1. Loading the Gold Layer and Getting the Batch Start/End Time
===================================================================================
*/

	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '==========================================================================';
		PRINT 'Loading: Gold (T3) Layer';
		PRINT '==========================================================================';

/*
===================================================================================
2. Truncating and Inserting Data into: 'gold.fact_deposits_movement'
===================================================================================
*/

	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: gold.fact_deposits_movement';

	TRUNCATE TABLE gold.fact_deposits_movement;

	PRINT '>> Inserting Data into: gold.fact_deposits_movement';

	INSERT INTO gold.fact_deposits_movement(
    posting_date,
    sap_transaction_code,
    sap_account_num,
	sap_amount_dr,
	sap_amount_cr,
	sap_deposit_reversal,
	tm_transaction_code,
	tm_amount_dr,
	tm_amount_cr,
	tm_deposit_reversal,
	source_system
	)

SELECT
	posting_date,
	transaction_code	AS	sap_transaction_code,
	account				AS	sap_account_num,
	amount_dr			AS	sap_amount_dr,
	amount_cr			AS	sap_amount_cr,
	is_deposit_reversal	AS	sap_deposit_reversal,
	NULL				AS	tm_transaction_code,
	NULL				AS	tm_amount_dr,
	NULL				AS	tm_amount_cr,
	NULL				AS	tm_deposit_reversal,
	'SAP'				AS	source_system

FROM silver.erp_sap_je
WHERE transaction_code LIKE 'IPTKOTCR%' OR transaction_code LIKE 'IPTKOTDR%' OR transaction_code LIKE 'ITMDIPCD%'
        OR transaction_code LIKE 'ITMDIPCR%' OR transaction_code LIKE 'ITMDIPDR%' OR transaction_code LIKE 'RPTKBPDR%' OR
        transaction_code LIKE 'RPTKCICR%' OR transaction_code LIKE 'RPTKCODR%' OR transaction_code LIKE 'RPTKRMCR%' OR
        transaction_code LIKE 'RPTKSMDR%' OR transaction_code LIKE 'RTMDACCD%' OR transaction_code LIKE 'RTMDACDR%' OR
        transaction_code LIKE 'RTMDETCD%' OR transaction_code LIKE 'RTMDETCR%' OR transaction_code LIKE 'RTMDETDR%' OR
        transaction_code LIKE 'RTMDMDDR%' OR transaction_code LIKE 'RTMDOPCR%' OR transaction_code LIKE 'RTMDOPDR%' OR
        transaction_code LIKE 'RVDCOPDR%'

UNION ALL

SELECT 
	transaction_posting_date	AS	posting_date,
	NULL					AS	sap_transaction_code,
	NULL					AS	sap_account_num,
	NULL					AS	sap_amount_dr,
	NULL					AS	sap_amount_cr,
	NULL					AS	sap_deposit_reversal,
	transaction_type_code	AS	tm_transaction_code,
	tm_amount_dr			AS	tm_amount_dr,
	tm_amount_cr			AS	tm_amount_cr,
	transaction_reversal_flag	AS	tm_reversal_flag,
	'TM'					AS	source_system

FROM silver.core_tm_sl_aggregates
ORDER BY posting_date

SET @end_time = GETDATE();
PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
PRINT '==========================================================================';

/*
===================================================================================
2. Truncating and Inserting Data into: 'gold.dim_transaction_code'
===================================================================================
*/

SET @start_time = GETDATE();
PRINT '>> Truncating Table: gold.dim_transaction_codes';

TRUNCATE TABLE gold.dim_transaction_codes;

PRINT '>> Inserting Data into: gold.dim_transaction_codes';

WITH sap_codes AS (
	SELECT DISTINCT
		transaction_code,
		is_deposit_reversal
        
	FROM silver.erp_sap_je
    WHERE transaction_code IS NOT NULL
    AND (transaction_code LIKE 'IPTKOTCR%' OR transaction_code LIKE 'IPTKOTDR%' 
           OR transaction_code LIKE 'ITMDIPCD%' OR transaction_code LIKE 'ITMDIPCR%' 
           OR transaction_code LIKE 'ITMDIPDR%' OR transaction_code LIKE 'RPTKBPDR%'
           OR transaction_code LIKE 'RPTKCICR%' OR transaction_code LIKE 'RPTKCODR%' 
           OR transaction_code LIKE 'RPTKRMCR%' OR transaction_code LIKE 'RPTKSMDR%'
           OR transaction_code LIKE 'RTMDACCD%' OR transaction_code LIKE 'RTMDACDR%'
           OR transaction_code LIKE 'RTMDETCD%' OR transaction_code LIKE 'RTMDETCR%' 
           OR transaction_code LIKE 'RTMDETDR%' OR transaction_code LIKE 'RTMDMDDR%'
           OR transaction_code LIKE 'RTMDOPCR%' OR transaction_code LIKE 'RTMDOPDR%' 
           OR transaction_code LIKE 'RVDCOPDR%')
),
tm_codes AS (
    SELECT DISTINCT
        transaction_type_code AS transaction_code,
        transaction_reversal_flag
    FROM silver.core_tm_sl_aggregates
    WHERE transaction_type_code IS NOT NULL
)

INSERT INTO gold.dim_transaction_codes (
    transaction_code,
    transaction_base_code,
    normal_or_reversal,
    source_system
)

SELECT
    COALESCE(s.transaction_code, t.transaction_code) AS transaction_code,
    
    LEFT(COALESCE(s.transaction_code, t.transaction_code), LEN(COALESCE(s.transaction_code, t.transaction_code)) - 1) AS transaction_base_code,
    COALESCE(s.is_deposit_reversal, t.transaction_reversal_flag) AS normal_or_reversal,
    
    CASE WHEN s.transaction_code IS NOT NULL AND t.transaction_code IS NOT NULL THEN 'Both'
        WHEN s.transaction_code IS NOT NULL THEN 'SAP'
        WHEN t.transaction_code IS NOT NULL THEN 'TM'
    END AS source_system
FROM sap_codes s
FULL OUTER JOIN tm_codes t
    ON s.transaction_code = t.transaction_code;

SET @end_time = GETDATE();
PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
PRINT '==========================================================================';

	SET @batch_end_time = GETDATE();
		PRINT '==========================================================================';
		PRINT 'Loading the Silver Layer is Complete.';
		PRINT 'Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================================================';
	END TRY
	BEGIN CATCH
		PRINT '==========================================================================';
		PRINT 'ERROR OCCURRED WHILE LOADING THE SILVER LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '==========================================================================';
	END CATCH
END
