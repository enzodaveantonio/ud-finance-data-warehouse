/*
================================================================================
Script: Load Silver Layer Tables
================================================================================
Script Purpose:
    This script loads cleaned and transformed data into the 'silver' schema
    for the Deposits Reconciliation pipeline. It performs the following actions:
    - Inserts cleansed and enriched SAP Journal Entries data from
      bronze.erp_sap_je into silver.erp_sap_je.
    - Inserts validated TM SL Aggregates data from
      bronze.core_tm_sl_aggregates into silver.core_tm_sl_aggregates.
    - Applies the following transformations:
        >> Standardizes cleared_open_items_symbol to readable labels
        >> Converts amount_in_local_currency from NVARCHAR to DECIMAL
        >> Adds document_type_description based on SAP document type codes
        >> Adds is_reversal flag (Yes/No)
        >> Adds is_prior_period_adjustment flag (Yes/No)
        >> Adds is_dr_cr_balanced flag (Yes/No) for TM SL aggregates
    - Filters out rows with NULL values in critical columns.
    - Populates dwh_source_file metadata column for audit trail.

Scope:
    Deposits Reconciliation (Account 2121199) only.
    Bank Reconciliation tables are not yet included in this version.

Usage:
    Run after the Bronze Layer has been successfully loaded.
    Re-runnable — silver tables are truncated before each load.
    EXEC silver.load_silver
================================================================================
*/

/*
============================================================
1. Insert the transformed, cleansed, & normalized data into 'silver.erp_sap_je'
Transformations: amount conversion, document type classification, reversal flag, prior period adjustment flag
============================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS

BEGIN

/*
===================================================================================
1. Loading the Silver Layer and Getting the Batch Start/End Time
===================================================================================
*/

	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '==========================================================================';
		PRINT 'Loading: Silver (T2) Layer';
		PRINT '==========================================================================';

/*
===================================================================================
2. Truncating and Inserting Data into: 'silver.erp_sap_je'
===================================================================================
*/
	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.erp_sap_je';

	TRUNCATE TABLE silver.erp_sap_je;

	PRINT '>> Inserting Data into: silver.erp_sap_je';


    INSERT INTO silver.erp_sap_je(
        cleared_open_items_symbol,
        company_code,
        account,
        document_number,
        document_type,
        document_type_description,
        is_reversal,
        document_date,
        posting_date,
        is_prior_period_adjustment,
        reference_key_3,
        amount_in_local_currency,
        local_currency,
        tax_code,
        clearing_document,
        je_text,
        profit_center,
        cost_center,
        transaction_code,
        dwh_source_file
    )

    SELECT
        CASE WHEN cleared_open_items_symbol IS NULL THEN 'Open'
             WHEN cleared_open_items_symbol LIKE '%Cleared%' THEN 'Cleared'
             WHEN cleared_open_items_symbol LIKE '%Posted%' THEN 'Posted'
             ELSE cleared_open_items_symbol
        END AS  cleared_open_items_symbol,
	    company_code,
	    account,
	    document_number,
	    UPPER(document_type) AS document_type,

        CASE
            WHEN document_type = 'SA' THEN 'Manual Journal Entry'
            WHEN document_type = 'ZA' THEN 'Automated Journal Entry'
            WHEN document_type = 'SB' THEN 'Batch Journal Entry'
            WHEN document_type = 'AB' THEN 'Reversal - Journal Entry'
            WHEN document_type = 'KR' THEN 'Vendor Invoice'
            WHEN document_type = 'KZ' THEN 'Vendor Payment'
            WHEN document_type = 'WE' THEN 'Goods Receipt'
            WHEN document_type = 'RE' THEN 'MIR7 - Park'
            WHEN document_type = 'KA' THEN 'Reversal - Vendor Invoice'
            ELSE 'Unknown'
        END AS document_type_description,

	    CASE WHEN document_type IN ('AB', 'KA') THEN 'Yes'
		    ELSE 'No'
	    END AS is_reversal,

        document_date,
        posting_date,
	    CASE WHEN DATEDIFF(month, document_date, posting_date) > 0 THEN 'Yes'
		    ELSE 'No'
	    END AS is_prior_period_adjustment,
        reference_key_3,

        CAST(REPLACE(amount_in_local_currency, ',', '') AS DECIMAL(18, 2)) AS amount_in_local_currency,
        local_currency,
        tax_code,
        clearing_document,
        je_text,
        profit_center,
        cost_center,
        transaction_code,
        'sap_je.csv' AS dwh_source_file


    FROM bronze.erp_sap_je

    WHERE company_code IS NOT NULL
      AND document_number IS NOT NULL
      AND document_type IS NOT NULL
      AND posting_date IS NOT NULL
      AND account IS NOT NULL


    SET @end_time = GETDATE();
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
	PRINT '==========================================================================';

/*
===================================================================================
3. Truncating and Inserting Data into: silver.core_tm_sl_aggregates
===================================================================================
*/

	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.core_tm_sl_aggregates';
		
	TRUNCATE TABLE silver.core_tm_sl_aggregates;

	PRINT '>> Inserting Data into: silver.core_tm_sl_aggregates';



INSERT INTO silver.core_tm_sl_aggregates(
    transaction_posting_date,
    transaction_code,
    total_amount_dr,
    total_amount_cr,
    reversal_flag_0,
    reversal_flag_1,
    is_dr_cr_balanced,
    dwh_source_file
)


SELECT  
    transaction_posting_date,
    transaction_code,
    total_amount_dr,
    total_amount_cr,
    reversal_flag_0,
    reversal_flag_1,

    CASE WHEN total_amount_dr = total_amount_cr THEN 'Yes'
        ELSE 'No'
    END AS is_dr_cr_balanced,
    'tm_sl_aggregates.csv' AS dwh_source_file



FROM bronze.core_tm_sl_aggregates
WHERE transaction_posting_date IS NOT NULL AND transaction_posting_date > '2020-01-01' AND transaction_posting_date < GETDATE()
  AND transaction_code IS NOT NULL
  AND total_amount_dr IS NOT NULL AND total_amount_dr >= 0
  AND total_amount_cr IS NOT NULL AND total_amount_cr >= 0 
  AND reversal_flag_0 IS NOT NULL AND reversal_flag_0 >= 0
  AND reversal_flag_1 IS NOT NULL AND reversal_flag_1 >= 0

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

