-- MySQL does not permit LOAD DATA INFILE inside stored procedures.
-- Run these static statements with a MySQL client to load the bronze tables.
USE DataWarehouse;

-- Record the start time for total batch duration reporting.
SET @batch_start_epoch = UNIX_TIMESTAMP(SYSDATE(6));

-- Load the CRM customer CSV after clearing the previous table contents.
SELECT 'Loading DataWarehouse.crm_cust_info' AS status;
SET @load_start_epoch = UNIX_TIMESTAMP(SYSDATE(6));
TRUNCATE TABLE crm_cust_info;
LOAD DATA INFILE '/var/lib/mysql-files/datasets/source_crm/cust_info.csv'
INTO TABLE crm_cust_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@cst_id, @cst_key, @cst_firstname, @cst_lastname, @cst_marital_status, @cst_gndr, @cst_create_date)
SET cst_id = NULLIF(@cst_id, ''),
    cst_key = NULLIF(@cst_key, ''),
    cst_firstname = NULLIF(@cst_firstname, ''),
    cst_lastname = NULLIF(@cst_lastname, ''),
    cst_marital_status = NULLIF(@cst_marital_status, ''),
    cst_gndr = NULLIF(@cst_gndr, ''),
    cst_create_date = NULLIF(@cst_create_date, '');
SELECT CONCAT(
    'Load duration: ',
    ROUND((UNIX_TIMESTAMP(SYSDATE(6)) - @load_start_epoch) * 1000),
    ' milliseconds'
) AS status;

-- Load the CRM product CSV after clearing the previous table contents.
SELECT 'Loading DataWarehouse.crm_prd_info' AS status;
SET @load_start_epoch = UNIX_TIMESTAMP(SYSDATE(6));
TRUNCATE TABLE crm_prd_info;
LOAD DATA INFILE '/var/lib/mysql-files/datasets/source_crm/prd_info.csv'
INTO TABLE crm_prd_info
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@prd_id, @prd_key, @prd_nm, @prd_cost, @prd_line, @prd_start_dt, @prd_end_dt)
SET prd_id = NULLIF(@prd_id, ''),
    prd_key = NULLIF(@prd_key, ''),
    prd_nm = NULLIF(@prd_nm, ''),
    prd_cost = NULLIF(@prd_cost, ''),
    prd_line = NULLIF(@prd_line, ''),
    prd_start_dt = NULLIF(@prd_start_dt, ''),
    prd_end_dt = NULLIF(@prd_end_dt, '');
SELECT CONCAT(
    'Load duration: ',
    ROUND((UNIX_TIMESTAMP(SYSDATE(6)) - @load_start_epoch) * 1000),
    ' milliseconds'
) AS status;

-- Load the CRM sales CSV after clearing the previous table contents.
SELECT 'Loading DataWarehouse.crm_sales_details' AS status;
SET @load_start_epoch = UNIX_TIMESTAMP(SYSDATE(6));
TRUNCATE TABLE crm_sales_details;
LOAD DATA INFILE '/var/lib/mysql-files/datasets/source_crm/sales_details.csv'
INTO TABLE crm_sales_details
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@sls_ord_num, @sls_prd_key, @sls_cust_id, @sls_order_dt, @sls_ship_dt, @sls_due_dt, @sls_sales, @sls_quantity, @sls_price)
SET sls_ord_num = NULLIF(@sls_ord_num, ''),
    sls_prd_key = NULLIF(@sls_prd_key, ''),
    sls_cust_id = NULLIF(@sls_cust_id, ''),
    sls_order_dt = NULLIF(@sls_order_dt, ''),
    sls_ship_dt = NULLIF(@sls_ship_dt, ''),
    sls_due_dt = NULLIF(@sls_due_dt, ''),
    sls_sales = NULLIF(@sls_sales, ''),
    sls_quantity = NULLIF(@sls_quantity, ''),
    sls_price = NULLIF(@sls_price, '');
SELECT CONCAT(
    'Load duration: ',
    ROUND((UNIX_TIMESTAMP(SYSDATE(6)) - @load_start_epoch) * 1000),
    ' milliseconds'
) AS status;

-- Load the ERP customer CSV after clearing the previous table contents.
SELECT 'Loading DataWarehouse.erp_cust_az12' AS status;
SET @load_start_epoch = UNIX_TIMESTAMP(SYSDATE(6));
TRUNCATE TABLE erp_cust_az12;
LOAD DATA INFILE '/var/lib/mysql-files/datasets/source_erp/CUST_AZ12.csv'
INTO TABLE erp_cust_az12
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@cid, @bdate, @gen)
SET cid = NULLIF(@cid, ''),
    bdate = NULLIF(@bdate, ''),
    gen = NULLIF(@gen, '');
SELECT CONCAT(
    'Load duration: ',
    ROUND((UNIX_TIMESTAMP(SYSDATE(6)) - @load_start_epoch) * 1000),
    ' milliseconds'
) AS status;

-- Load the ERP location CSV after clearing the previous table contents.
SELECT 'Loading DataWarehouse.erp_loc_a101' AS status;
SET @load_start_epoch = UNIX_TIMESTAMP(SYSDATE(6));
TRUNCATE TABLE erp_loc_a101;
LOAD DATA INFILE '/var/lib/mysql-files/datasets/source_erp/LOC_A101.csv'
INTO TABLE erp_loc_a101
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@cid, @cntry)
SET cid = NULLIF(@cid, ''),
    cntry = NULLIF(@cntry, '');
SELECT CONCAT(
    'Load duration: ',
    ROUND((UNIX_TIMESTAMP(SYSDATE(6)) - @load_start_epoch) * 1000),
    ' milliseconds'
) AS status;

-- Load the ERP product category CSV after clearing the previous table contents.
SELECT 'Loading DataWarehouse.erp_px_cat_g1v2' AS status;
SET @load_start_epoch = UNIX_TIMESTAMP(SYSDATE(6));
TRUNCATE TABLE erp_px_cat_g1v2;
LOAD DATA INFILE '/var/lib/mysql-files/datasets/source_erp/PX_CAT_G1V2.csv'
INTO TABLE erp_px_cat_g1v2
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@id, @cat, @subcat, @maintenance)
SET id = NULLIF(@id, ''),
    cat = NULLIF(@cat, ''),
    subcat = NULLIF(@subcat, ''),
    maintenance = NULLIF(@maintenance, '');
SELECT CONCAT(
    'Load duration: ',
    ROUND((UNIX_TIMESTAMP(SYSDATE(6)) - @load_start_epoch) * 1000),
    ' milliseconds'
) AS status;

-- Report the total duration after all six tables have loaded.
SELECT CONCAT(
    'Total bronze load duration: ',
    ROUND((UNIX_TIMESTAMP(SYSDATE(6)) - @batch_start_epoch) * 1000),
    ' milliseconds'
) AS status;
