-- SQLBook: Code
-- Active: 1795163957081@@127.0.0.1@1433@DataWarehouse
-- Active: 1795163957081@@127.0.0.1@1433@DataWarehouse
-- SQL Server
-- Create the table-valued parameter type once to hold each table and CSV path.
IF TYPE_ID(N'bronze.load_file_list') IS NULL
BEGIN
    EXEC(N'CREATE TYPE bronze.load_file_list AS TABLE (
        tb_name sysname NOT NULL,
        file_name nvarchar(255) NOT NULL
    );');
END;
GO
-- Create or update the procedure that loads all table/file pairs in one call.
CREATE OR ALTER PROCEDURE bronze.load_bronze
    @load_list bronze.load_file_list READONLY
AS
BEGIN
    -- Suppress row-count messages so callers receive only relevant results.
    SET NOCOUNT ON;

    -- Reject an empty batch before starting any table loads.
    IF NOT EXISTS (SELECT 1 FROM @load_list)
    BEGIN
        RAISERROR('Provide at least one table and file pair.', 16, 1);
        RETURN;
    END;

    -- Verify every requested target exists in the bronze schema.
    IF EXISTS (
        SELECT 1
        FROM @load_list AS l
        WHERE NOT EXISTS (
            SELECT 1
            FROM sys.tables AS t
            INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
            WHERE s.name = N'bronze'
              AND t.name = l.tb_name
        )
    )
    BEGIN
        RAISERROR('A requested table does not exist in the bronze schema.', 16, 1);
        RETURN;
    END;

    -- Accept only relative CSV paths beneath the configured datasets directory.
    IF EXISTS (
        SELECT 1
        FROM @load_list
        WHERE file_name = N''
           OR file_name LIKE N'/%'
           OR file_name LIKE N'%..%'
           OR file_name LIKE N'%[^A-Za-z0-9_./-]%'
           OR LOWER(RIGHT(file_name, 4)) <> N'.csv'
    )
    BEGIN
        RAISERROR('Each file must be a relative CSV path beneath /var/opt/datasets.', 16, 1);
        RETURN;
    END;

    -- Declare variables used to build and execute one load command at a time.
    DECLARE
        @tb_name sysname,
        @file_name nvarchar(255),
        @qualified_table nvarchar(258),
        @sql nvarchar(max);

    -- Iterate over the validated table and file pairs.
    DECLARE load_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT tb_name, file_name
        FROM @load_list;

    -- Start the loop with the first requested pair.
    OPEN load_cursor;
    FETCH NEXT FROM load_cursor INTO @tb_name, @file_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Quote the table identifier and build its truncate-and-import command.
        SET @qualified_table = N'bronze.' + QUOTENAME(@tb_name);
        SET @sql =
            N'TRUNCATE TABLE ' + @qualified_table + N';' + CHAR(10) +
            N'BULK INSERT ' + @qualified_table +
            N' FROM ''/var/opt/datasets/' +
            REPLACE(@file_name, N'''', N'''''') +
            N''' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', TABLOCK);';

        -- Execute the command, then advance to the next pair.
        EXEC sys.sp_executesql @sql;
        FETCH NEXT FROM load_cursor INTO @tb_name, @file_name;
    END;

    -- Release the cursor resources after all pairs have been processed.
    CLOSE load_cursor;
    DEALLOCATE load_cursor;
END;

-- Example call: populate a table-valued parameter with pairs, then run the loader.
-- DECLARE @files bronze.load_file_list;
-- INSERT INTO @files (tb_name, file_name)
-- VALUES
--     (N'crm_cust_info', N'source_crm/cust_info.csv'),
--     (N'crm_prd_info', N'source_crm/prd_info.csv'),
--     (N'crm_sales_details', N'source_crm/sales_details.csv'),
--     (N'erp_cust_az12', N'source_erp/CUST_AZ12.csv'),
--     (N'erp_loc_a101', N'source_erp/LOC_A101.csv'),
--     (N'erp_px_cat_g1v2', N'source_erp/PX_CAT_G1V2.csv');
-- EXEC bronze.load_bronze @load_list = @files;
