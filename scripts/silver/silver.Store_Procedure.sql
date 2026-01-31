/*
==================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
==================================================================================
Script Purpose:
	This Stored Procedure performs the ETL (Extract, Transform, Load) process to 
	populate the 'silver' schema tables from the 'bronze' schema.
Actions performed:
	- Truncates silver tables.
	- Insert transformed and cleansed data from bronze into silver tables.

Parameters:
	None.
	This store procedure does not accept any parameters or return any values.

Usage Example:
	EXEC silver.load_silverlayer
==================================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silverlayer AS
DECLARE @start_time DATETIME, @end_time DATETIME, @start_batch_time DATETIME, @end_batch_time DATETIME;
BEGIN
	BEGIN TRY
	SET @start_batch_time = GETDATE();
	PRINT '=================================================='
	PRINT 'Loading Silver Layer'
	PRINT '=================================================='
	PRINT '--------------------------------------------------'
	PRINT 'Loading CRM Tables'
	PRINT '--------------------------------------------------'
	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;
	PRINT '>> Loading Data into Table: silver.crm_cust_info';
	INSERT INTO silver.crm_cust_info
		(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
		)
	SELECT
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
			 WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
			 ELSE 'Unknown'
		END AS cst_marital_status, -- Normalize marital status to readable format
		CASE WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
			 WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
			 ELSE 'n/a'
		END AS cst_gndr, -- Normalize gender status to readable format
		cst_create_date
	FROM
	(
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
	)t
	WHERE flag = 1 ;-- Select the Newest data per customers
	SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'

      
	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;
	PRINT '>> Loading Data into Table: silver.crm_prd_info';
	INSERT INTO silver.crm_prd_info
		(
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt		
		)
	SELECT
		prd_id,
		REPLACE(SUBSTRING(prd_key,1,5),'-', '_') AS cat_id, -- Extract category id
		SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,		-- Extract product key
		prd_nm,
		COALESCE(prd_cost, 785) AS prd_cost, -- 785 from AVG cost for the simillar product the HL Road Frame
		CASE TRIM(UPPER(prd_line))
			 WHEN 'R' THEN 'Road'
			 WHEN 'M' THEN 'Mountain'
			 WHEN 'T' THEN 'Touring'
			 WHEN 'S' THEN 'Other Sales'
			 ELSE 'n/a'
		END AS prd_line, -- Map product line codes into descriptive value
		CAST(prd_start_dt AS DATE) AS prd_start_dt,
		CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE)
		AS prd_end_dt -- Calculate end date as one day before the next start date
	FROM bronze.crm_prd_info;
	SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'


	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;
	PRINT '>> Loading Data into Table: silver.crm_sales_details';
	INSERT INTO silver.crm_sales_details
		(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
		)
	SELECT
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE	WHEN sls_order_dt < 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		END AS sls_order_dt,
		CASE	WHEN sls_ship_dt < 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		END AS sls_ship_dt,
		CASE	WHEN sls_due_dt < 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		END AS sls_due_dt,
		CASE	WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
		END AS sls_sales, -- Recalculate sales if original values is missing or incorrect
		sls_quantity,
		CASE	WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price
		END AS sls_price -- Derive price if orginial values is invalid
	FROM bronze.crm_sales_details;
	SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'


		PRINT '--------------------------------------------------'
		PRINT 'Loading ERP Tables'
		PRINT '--------------------------------------------------'


	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;
	PRINT '>> Loading Data into Table: silver.erp_cust_az12';
	INSERT INTO silver.erp_cust_az12
		(
		cid,
		bdate,
		gen
		)
	SELECT
		 CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) -- Remove NAS prefix if present
			  ELSE cid
		 END AS cid,
		 CASE WHEN bdate > GETDATE() THEN NULL
			 ELSE bdate
		 END AS bdate, -- Set future birthdate into NULLS
		 CASE WHEN TRIM(UPPER(gen)) IN ('F', 'Female') THEN 'Female'
			 WHEN TRIM(UPPER(gen)) IN ('M', 'Male') THEN 'Male'
			 ELSE 'n/a'
		 END AS gen -- Normalize gender values and handle unknown cases
	FROM bronze.erp_cust_az12;
	SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'


	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101;
	PRINT '>> Loading Data into Table: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101
		(
		cid,
		cntry
		)
	SELECT
		 REPLACE(cid,'-','') AS cst_key,
	CASE WHEN cntry IN ('USA', 'US','United States') THEN 'United State'
		 WHEN cntry IN ('DE', 'Germany') THEN 'Germany'
		 WHEN cntry IS NULL OR cntry = ' ' THEN 'n/a'
		 ELSE cntry
	END AS cntry -- Normalize and Handle missing or blank country code
	FROM bronze.erp_loc_a101;
	SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'


	SET @start_time = GETDATE();
	PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	PRINT '>> Loading Data into Table: silver.erp_px_cat_g1v2';
	INSERT INTO silver.erp_px_cat_g1v2
		(id,
		cat,
		subcat,
		maintenance
		)
	SELECT
		id,
		cat,
		subcat,
		maintenance
	FROM bronze.erp_px_cat_g1v2;


	SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------------------'
		SET @end_batch_time = GETDATE()
		PRINT '=================================================='
		PRINT '>> Loading Silver Layer Duration: ' + CAST(DATEDIFF(second, @start_batch_time, @end_batch_time) AS NVARCHAR) + ' seconds';
		PRINT '=================================================='
	END TRY
	BEGIN CATCH
		PRINT '=================================================='
		PRINT 'ERROR OCCURED DUING LOADING SILVER LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '=================================================='
	END CATCH
END
