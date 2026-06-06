/*
=====================================================================

Stored Procedure: Load Silver Layer (Bronze -> Silver)

=====================================================================

Script Purpose:

    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.

Actions Performed:

    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:

    None.

    This stored procedure does not accept any parameters or return any values.

Usage Example:

    EXEC Silver.load_silver;

=====================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN 

	DECLARE @start_time DATETIME, @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME ;

      	BEGIN TRY 

		SET	@batch_start_time = GETDATE();

		PRINT '==============================================';
		PRINT 'Loading Silver  Layer';
		PRINT '==============================================';

		PRINT '----------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '----------------------------------------------';

    SET @start_time = GETDATE();
     
    PRINT '>> Truncating Table: silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    PRINT '>> Inserting Data Into: silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info (
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
    
       CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            ELSE 'n/a'
        END AS cst_marital_status,

        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            ELSE 'n/a'
        END AS cst_gndr,

        cst_create_date

    FROM (

        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last

        FROM bronze.crm_cust_info

        WHERE cst_id IS NOT NULL

    ) t WHERE flag_last = 1 

    SET @end_time = GETDATE();

	PRINT '>> LOAD DURATION : ' + CAST (DATEDIFF(SECOND,@start_time , @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>>-----------------------------------------------------------------'

	
    
    SET @start_time = GETDATE();
     
    PRINT '>> Truncating Table: silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;

    PRINT '>> Inserting Data Into: silver.crm_prd_info';
    INSERT INTO silver.crm_prd_info (
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
        REPLACE (SUBSTRING (prd_key, 1,5),'-','_') AS cat_id,
        SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
        prd_nm,
        ISNULL(prd_cost, 0 ) as prd_cost,
       Case when upper(TRIM(prd_line))='M' then 'Mountain'
       when upper(TRIM(prd_line))='R' then 'Road'
       when upper(TRIM(prd_line))='S' then 'Other Sales'
       when upper(TRIM(prd_line))='T' then 'Touring'
       ELSE 'n/a'
    END prd_line,
        CAST(prd_start_dt As DATE) as prd_start_dt,
        Lead(prd_start_dt) over(partition by prd_key Order by prd_start_dt) AS prd_end_dt
    FROM bronze.crm_prd_info  

    SET @end_time = GETDATE();

	PRINT '>> LOAD DURATION : ' + CAST (DATEDIFF(SECOND,@start_time , @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>>-----------------------------------------------------------------'



	SET @start_time = GETDATE();


    PRINT '>> Truncating Table: silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;

    PRINT '>> Inserting Data Into: silver.crm_sales_details';
    INSERT INTO silver.crm_sales_details (
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

        CASE
            WHEN sls_order_dt = 0
                 OR LEN(sls_order_dt) != 8
            THEN NULL

            ELSE CAST(
                    CAST(sls_order_dt AS VARCHAR)
                 AS DATE)

        END AS sls_order_dt,

        CASE
            WHEN sls_ship_dt = 0
                 OR LEN(sls_ship_dt) != 8
            THEN NULL

            ELSE CAST(
                    CAST(sls_ship_dt AS VARCHAR)
                 AS DATE)

        END AS sls_ship_dt,

        CASE
            WHEN sls_due_dt = 0
                 OR LEN(sls_due_dt) != 8
            THEN NULL

            ELSE CAST(
                    CAST(sls_due_dt AS VARCHAR)
                 AS DATE)

        END AS sls_due_dt,

        CASE
            WHEN sls_sales IS NULL
                 OR sls_sales <= 0
                 OR sls_sales != sls_quantity * ABS(sls_price)

            THEN sls_quantity * sls_price

            ELSE sls_sales

        END AS sls_sales,

        sls_quantity,

        CASE
            WHEN sls_price IS NULL
                 OR sls_price <= 0
       
            THEN sls_sales / NULLIF(sls_quantity, 0)

            ELSE sls_price

        END AS sls_price
    
    FROM bronze.crm_sales_details;

    SET @end_time = GETDATE();

	PRINT '>> LOAD DURATION : ' + CAST (DATEDIFF(SECOND,@start_time , @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>>-----------------------------------------------------------------'



    PRINT '----------------------------------------------';
	PRINT 'Loading ERP Tables';
	PRINT '----------------------------------------------';

	--ERP  INSERT 

	SET @start_time = GETDATE();

    PRINT '>> Truncating Table: silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;

    PRINT '>> Inserting Data Into: silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    select 
    case when cid like 'NAS%'then SUBSTRING(cid,4,LEN(cid))
        else cid
    end as  new_cid,
    case when bdate > GETDATE() then NULL 
    else bdate 
    end as bdate, 
    case 
    when  UPPER(trim(gen))  in ( 'M' , 'Male') then 'Male'
    when UPPER(trim(gen)) in ( 'F','Female') then 'Female'
    else 'n/a'
    end as gen
    from bronze.erp_cust_az12
    
    SET @end_time = GETDATE();

	PRINT '>> LOAD DURATION : ' + CAST (DATEDIFF(SECOND,@start_time , @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>>-----------------------------------------------------------------'


	SET @start_time = GETDATE();
     


    PRINT '>> Truncating Table: silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;

    PRINT '>> Inserting Data Into: silver.erp_loc_a101';
    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    select 
    replace(cid,'-','') as cid,
    case when trim(cntry)= 'DE' then 'Germany'
    when trim(cntry) in ('US', 'USA')  THEN 'United States' 
    when trim(cntry)='' or cntry is NULL then 'n/a'
    else trim(cntry) 
    end cntry 
    from bronze.erp_loc_a101  

     SET @end_time = GETDATE();

	PRINT '>> LOAD DURATION : ' + CAST (DATEDIFF(SECOND,@start_time , @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>>-----------------------------------------------------------------'


	SET @start_time = GETDATE();


    PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    select  id, 
    cat, 
    subcat,
    maintenance 
    from bronze.erp_px_cat_g1v2
     
    SET @end_time = GETDATE();

			PRINT '>> LOAD DURATION : ' + CAST (DATEDIFF(SECOND,@start_time , @end_time) AS NVARCHAR) + 'seconds';
			PRINT '>>-----------------------------------------------------------------'

			SET @batch_end_time = GETDATE();
			
			PRINT '==============================================';
			PRINT 'Loading Silver Layer is Completed';
			PRINT '    - Total Load Duration: ' 
				  + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR)
				  + ' seconds';
			PRINT '==============================================';
	
	END TRY

	BEGIN CATCH

		PRINT '==============================================';
		PRINT 'ERROR OCCURED DURING LOADING Silver LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '==============================================';

	END CATCH


END


EXEC silver.load_silver
