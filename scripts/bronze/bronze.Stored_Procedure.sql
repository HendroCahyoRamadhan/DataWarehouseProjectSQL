/*
======================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
======================================================================================
Script Purpose:
	This stored procedure loads data into the "bronze' schema from external .csv files.
	It performs the following actions:
	- Truncates the bronze tables before loading data.
	- Uses the BULK INSERT command to load data from .csv files to bronze tables.

Parameters:
	  None
	This stored procedure does not accept any parameters or return any values.

Usage Example:
	EXEC bronze.load_bronzelayer
======================================================================================
*/


CREATE   PROCEDURE bronze.load_bronzelayer AS
DECLARE @start_time DATETIME, @end_time DATETIME, @start_batch_time DATETIME, @end_batch_time DATETIME;
BEGIN
	BEGIN TRY
		SET @start_batch_time = GETDATE();
		PRINT '=================================================='
		PRINT 'Loading Bronze Layer'
		PRINT '=================================================='

		PRINT '--------------------------------------------------'
		PRINT 'Loading CRM Tables'
		PRINT '--------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT'>> Truncating Table bronze.crm_cust_info'
		TRUNCATE TABLE bronze.crm_cust_info

		PRINT'>> Inserting Data Into : bronze.crm_cust_info'
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Sql\dwh_project\datasets\source_crm\cust_info.csv'
		WITH
		(
			FIRSTROW = 2,
			FIELDTERMINATOR = ','
		)
		;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'



		SET @start_time = GETDATE();
		PRINT'>> Truncating Table bronze.crm_prd_info'
		TRUNCATE TABLE bronze.crm_prd_info

		PRINT'>> Inserting Data Into : bronze.crm_prd_info'
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Sql\dwh_project\datasets\source_crm\prd_info.csv'
		WITH
		(
			FIRSTROW = 2,
			FIELDTERMINATOR = ','
		)
		;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'



		SET @start_time = GETDATE();
		PRINT'>> Truncating Table bronze.crm_sales_details'
		TRUNCATE TABLE bronze.crm_sales_details

		PRINT'>> Inserting Data Into : bronze.crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Sql\dwh_project\datasets\source_crm\sales_details.csv'
		WITH
		(
			FIRSTROW = 2,
			FIELDTERMINATOR = ','
		)
		;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'



		PRINT '--------------------------------------------------'
		PRINT 'Loading ERP Tables'
		PRINT '--------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT'>> Truncating Table bronze.erp_cust_az12'
		TRUNCATE TABLE bronze.erp_cust_az12

		PRINT'>> Inserting Data Into : bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Sql\dwh_project\datasets\source_erp\CUST_AZ12.csv'
		WITH
		(
			FIRSTROW = 2,
			FIELDTERMINATOR = ','
		)
		;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'



		SET @start_time = GETDATE();
		PRINT'>> Truncating Table bronze.erp_loc_a101'
		TRUNCATE TABLE bronze.erp_loc_a101

		PRINT'>> Inserting Data Into : bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Sql\dwh_project\datasets\source_erp\LOC_A101.csv'
		WITH
		(
			FIRSTROW = 2,
			FIELDTERMINATOR = ','
		)
		;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'



		SET @start_time = GETDATE();
		PRINT'>> Truncating Table bronze.erp_px_cat_g1v2'
		TRUNCATE TABLE bronze.erp_px_cat_g1v2

		PRINT'>> Inserting Data Into : bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Sql\dwh_project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH
		(
			FIRSTROW = 2,
			FIELDTERMINATOR = ','
		)
		;
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'

		SET @end_batch_time = GETDATE()
		PRINT '=================================================='
		PRINT '>> Loading Bronze Layer Duration: ' + CAST(DATEDIFF(second, @start_batch_time, @end_batch_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================================='
	END TRY
	BEGIN CATCH
		PRINT '=================================================='
		PRINT 'ERROR OCCURED DUING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '=================================================='
	END CATCH
END
;
GO
