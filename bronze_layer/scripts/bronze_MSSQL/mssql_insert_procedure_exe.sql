-- Example call: populate a table-valued parameter with pairs, then run the loader.
DECLARE @files bronze.load_file_list;
INSERT INTO @files (tb_name, file_name)
VALUES
    (N'crm_cust_info', N'source_crm/cust_info.csv'),
    (N'crm_prd_info', N'source_crm/prd_info.csv'),
    (N'crm_sales_details', N'source_crm/sales_details.csv'),
    (N'erp_cust_az12', N'source_erp/CUST_AZ12.csv'),
    (N'erp_loc_a101', N'source_erp/LOC_A101.csv'),
    (N'erp_px_cat_g1v2', N'source_erp/PX_CAT_G1V2.csv');
EXEC bronze.load_bronze @load_list = @files;