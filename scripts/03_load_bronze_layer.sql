
/*
===================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===================================================================================
Script Purpose:
	This stored procedure loads the data into the 'bronze' schema from external CSV files.
	It performs the ff actions:
	- Truncates the bronze tables before loading data.
	- Uses the 'BULK INSERT' command to load data from csv files to bronze tables.

	Parameters:
	None.
	This stored procedure does not accept any parameters or return any value.

	Usage Example:
		EXEC bronze.load_bronze;
===================================================================================



NOTE: This script does not yet contain the tables for bank reconciliation. It will be added shortly once deposits recon logic is finished.
*/



CREATE OR ALTER PROCEDURE bronze.load_bronze AS

BEGIN

/*
===================================================================================
1. Loading the Bronze Layer and Getting the Batch Start/End Time
===================================================================================
*/

	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '==========================================================================';
		PRINT 'Loading: Bronze (T1) Layer';
		PRINT '==========================================================================';

/*
===================================================================================
2. Truncating and Inserting Data into: 'bronze.erp_sap_je'
===================================================================================
*/
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_sap_je';

		TRUNCATE TABLE bronze.erp_sap_je;

		PRINT '>> Inserting Data into: bronze.erp_sap_je';

		BULK INSERT bronze.erp_sap_je
		FROM 'C:\Drive\3. Data Engineering\4. Finance Data Warehouse\csv files\erp\sap_je.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			FORMAT = 'CSV', -- Always include this for CSV files 
			ROWTERMINATOR = '\n',
			FIELDQUOTE = '"' -- Had to include this because some amounts in SAP are formatted as strings (e.g., "-1,950,511.34")
		);
		
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================================================';

/*
===================================================================================
3. Truncating and Inserting Data into: bronze.core_tm_sl_aggregates
===================================================================================
*/
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.core_tm_sl_aggregates';
		
		TRUNCATE TABLE bronze.core_tm_sl_aggregates;

		PRINT '>> Inserting Data into: bronze.core_tm_sl_aggregates';
		BULK INSERT bronze.core_tm_sl_aggregates
		FROM 'C:\Drive\3. Data Engineering\4. Finance Data Warehouse\csv files\core\tm_sl_aggregates.csv'
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a'
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================================================';

		SET @batch_end_time = GETDATE();
		PRINT '==========================================================================';
		PRINT 'Loading the Bronze Layer is Complete.';
		PRINT 'Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================================================';
	END TRY
	BEGIN CATCH
		PRINT '==========================================================================';
		PRINT 'ERROR OCCURRED WHILE LOADING THE BRONZE LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '==========================================================================';
	END CATCH
END
