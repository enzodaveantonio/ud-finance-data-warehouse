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
        >> SAP Transformations:
           - Standardizes cleared_open_items_symbol to readable labels
           - Converts amount_in_local_currency from NVARCHAR to DECIMAL
           - Splits amounts into amount_dr and amount_cr columns
           - Adds document_type_description based on SAP document type codes
           - Adds is_deposit_reversal flag (Reversal/Normal/NULL)
           - Adds is_prior_period_adjustment flag (Yes/No)
           - Strips trailing reversal indicator (0 or 1) from transaction_code
        >> TM Transformations:
           - Converts transaction_category codes (0/1) to labels (Debit/Credit)
           - Converts transaction_reversal_flag codes (0/1) to labels (Normal/Reversal)
           - Splits transaction_total_amount into tm_amount_dr and tm_amount_cr
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
TABLE OF CONTENTS
1. Loading the Silver Layer and Getting the Batch Start/End Time
2. Truncating and Inserting Data into: 'silver.erp_sap_je'
3. Truncating and Inserting Data into: 'silver.core_tm_sl_aggregates'

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
        document_date,
        posting_date,
        is_prior_period_adjustment,
        reference_key_3,
        amount_dr,
        amount_cr,
        local_currency,
        tax_code,
        clearing_document,
        je_text,
        profit_center,
        cost_center,
        transaction_code,
        is_deposit_reversal,
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
            ELSE 'N/A'
        END AS document_type_description,

        document_date,
        posting_date,
	    CASE WHEN DATEDIFF(month, document_date, posting_date) > 0 THEN 'Yes'
		    ELSE 'No'
	    END AS is_prior_period_adjustment,
        reference_key_3,

        CASE WHEN CAST(REPLACE(amount_in_local_currency, ',', '') AS DECIMAL(18,2)) > 0
            THEN CAST(REPLACE(amount_in_local_currency, ',', '') AS DECIMAL(18,2))
            ELSE NULL
        END AS amount_dr,

        CASE WHEN CAST(REPLACE(amount_in_local_currency, ',', '') AS DECIMAL(18,2)) < 0
            THEN ABS(CAST(REPLACE(amount_in_local_currency, ',', '') AS DECIMAL(18,2)))
            ELSE NULL
        END AS amount_cr,

        local_currency,
        tax_code,
        clearing_document,
        je_text,
        profit_center,
        cost_center,
        
        CASE WHEN transaction_code LIKE 'IPTKOTCR%' OR transaction_code LIKE 'IPTKOTDR%' OR transaction_code LIKE 'ITMDIPCD%'
            OR transaction_code LIKE 'ITMDIPCR%' OR transaction_code LIKE 'ITMDIPDR%' OR transaction_code LIKE 'RPTKBPDR%' OR
            transaction_code LIKE 'RPTKCICR%' OR transaction_code LIKE 'RPTKCODR%' OR transaction_code LIKE 'RPTKRMCR%' OR
            transaction_code LIKE 'RPTKSMDR%' OR transaction_code LIKE 'RTMDACCD%' OR transaction_code LIKE 'RTMDACDR%' OR
            transaction_code LIKE 'RTMDETCD%' OR transaction_code LIKE 'RTMDETCR%' OR transaction_code LIKE 'RTMDETDR%' OR
            transaction_code LIKE 'RTMDMDDR%' OR transaction_code LIKE 'RTMDOPCR%' OR transaction_code LIKE 'RTMDOPDR%' OR
            transaction_code LIKE 'RVDCOPDR%'
       
            THEN LEFT(transaction_code, LEN(transaction_code)-1)
            ELSE transaction_code
        END AS transaction_code,

        CASE WHEN (transaction_code LIKE 'IPTKOTCR%' OR transaction_code LIKE 'IPTKOTDR%' OR transaction_code LIKE 'ITMDIPCD%'
            OR transaction_code LIKE 'ITMDIPCR%' OR transaction_code LIKE 'ITMDIPDR%' OR transaction_code LIKE 'RPTKBPDR%' OR
            transaction_code LIKE 'RPTKCICR%' OR transaction_code LIKE 'RPTKCODR%' OR transaction_code LIKE 'RPTKRMCR%' OR
            transaction_code LIKE 'RPTKSMDR%' OR transaction_code LIKE 'RTMDACCD%' OR transaction_code LIKE 'RTMDACDR%' OR
            transaction_code LIKE 'RTMDETCD%' OR transaction_code LIKE 'RTMDETCR%' OR transaction_code LIKE 'RTMDETDR%' OR
            transaction_code LIKE 'RTMDMDDR%' OR transaction_code LIKE 'RTMDOPCR%' OR transaction_code LIKE 'RTMDOPDR%' OR
            transaction_code LIKE 'RVDCOPDR%')
            AND RIGHT(transaction_code, 1) = '1' THEN 'Reversal'
            
            WHEN (transaction_code LIKE 'IPTKOTCR%' OR transaction_code LIKE 'IPTKOTDR%' OR transaction_code LIKE 'ITMDIPCD%'
            OR transaction_code LIKE 'ITMDIPCR%' OR transaction_code LIKE 'ITMDIPDR%' OR transaction_code LIKE 'RPTKBPDR%' OR
            transaction_code LIKE 'RPTKCICR%' OR transaction_code LIKE 'RPTKCODR%' OR transaction_code LIKE 'RPTKRMCR%' OR
            transaction_code LIKE 'RPTKSMDR%' OR transaction_code LIKE 'RTMDACCD%' OR transaction_code LIKE 'RTMDACDR%' OR
            transaction_code LIKE 'RTMDETCD%' OR transaction_code LIKE 'RTMDETCR%' OR transaction_code LIKE 'RTMDETDR%' OR
            transaction_code LIKE 'RTMDMDDR%' OR transaction_code LIKE 'RTMDOPCR%' OR transaction_code LIKE 'RTMDOPDR%' OR
            transaction_code LIKE 'RVDCOPDR%')
            AND RIGHT(transaction_code, 1) = '0' THEN 'Normal'
            ELSE NULL
        END AS is_deposit_reversal,

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
3. Truncating and Inserting Data into: 'silver.core_tm_sl_aggregates'
===================================================================================
*/

	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.core_tm_sl_aggregates';
		
	TRUNCATE TABLE silver.core_tm_sl_aggregates;

	PRINT '>> Inserting Data into: silver.core_tm_sl_aggregates';


INSERT INTO silver.core_tm_sl_aggregates(
    transaction_posting_date,
    transaction_type_code,
    transaction_category,
    transaction_reversal_flag,
    tm_amount_dr,
    tm_amount_cr,
    dwh_source_file
)

SELECT  
    transaction_posting_date,
    transaction_type_code,

    -- remove transaction category and replace with text
    CASE WHEN transaction_category = '0' THEN 'Debit'
        WHEN transaction_category = '1' THEN 'Credit'
        ELSE NULL
    END AS transaction_category,

    CASE WHEN transaction_reversal_flag = '0' THEN 'Normal'
        WHEN transaction_reversal_flag = '1' THEN 'Reversal'
        ELSE NULL
    END AS transaction_reversal_flag,
    -- transaction amount: separate into dr & cr
    CASE WHEN transaction_category = '0' THEN transaction_total_amount
        ELSE NULL
    END AS tm_amount_dr,
    CASE WHEN transaction_category = '1' THEN transaction_total_amount
        ELSE NULL
    END AS tm_amount_cr,

    'tm_sl_aggregates.csv' AS dwh_source_file


FROM bronze.core_tm_sl_aggregates
WHERE transaction_posting_date IS NOT NULL AND transaction_posting_date > '2020-01-01' AND transaction_posting_date < GETDATE()
  AND transaction_type_code IS NOT NULL
ORDER BY transaction_posting_date


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

