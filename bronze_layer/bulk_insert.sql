-- SQLBook: Code
truncate table bronze.crm_cust_info;

bulk insert bronze.crm_cust_info
from '/var/opt/datasets/source_crm/cust_info.csv'
with (
    firstrow = 2,
    fieldterminator = ',',
    tablock
);