-- PostgreSQL example invocation for bronze.load_bronze.
-- The procedure expects an array of bronze.load_file_pair composite values.
CALL bronze.load_bronze(ARRAY[
    ROW('crm_cust_info', 'source_crm/cust_info.csv')::bronze.load_file_pair,
    ROW('crm_prd_info', 'source_crm/prd_info.csv')::bronze.load_file_pair,
    ROW('crm_sales_details', 'source_crm/sales_details.csv')::bronze.load_file_pair,
    ROW('erp_cust_az12', 'source_erp/CUST_AZ12.csv')::bronze.load_file_pair,
    ROW('erp_loc_a101', 'source_erp/LOC_A101.csv')::bronze.load_file_pair,
    ROW('erp_px_cat_g1v2', 'source_erp/PX_CAT_G1V2.csv')::bronze.load_file_pair
]);
