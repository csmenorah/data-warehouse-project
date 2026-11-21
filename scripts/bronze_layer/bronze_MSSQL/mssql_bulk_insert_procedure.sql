-- SQL Server
-- Create a table-valued parameter type for passing table/file pairs to the loader.
IF TYPE_ID(N'bronze.load_file_list') IS NULL
BEGIN
    EXEC(N'CREATE TYPE bronze.load_file_list AS TABLE
    (
        tb_name sysname NOT NULL,
        file_name nvarchar(255) NOT NULL
    );');
END;
GO

-- Create or update the stored procedure that loads one or more bronze tables.
CREATE OR ALTER PROCEDURE bronze.load_bronze
    @load_list bronze.load_file_list READONLY
AS
BEGIN
    SET NOCOUNT ON;

    -- Declare timing variables for both the complete batch and each table load.
    DECLARE
        @start_time datetime2,
        @end_time datetime2,
        @batch_start_time datetime2,
        @batch_end_time datetime2,
        @tb_name sysname,
        @file_name nvarchar(255),
        @qualified_table nvarchar(258),
        @sql nvarchar(max);

    -- Reject an empty batch before starting any table loads.
    IF NOT EXISTS (SELECT 1 FROM @load_list)
    BEGIN
        RAISERROR('Provide at least one table and file pair.', 16, 1);
        RETURN;
    END;

    -- Verify that every requested target exists in the bronze schema.
    IF EXISTS
    (
        SELECT 1
        FROM @load_list AS l
        WHERE NOT EXISTS
        (
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

    -- Accept only relative CSV paths beneath /var/opt/datasets.
    IF EXISTS
    (
        SELECT 1
        FROM @load_list
        WHERE file_name IS NULL
           OR file_name = N''
           OR file_name LIKE N'/%'
           OR file_name LIKE N'%..%'
           OR file_name LIKE N'%[^A-Za-z0-9_./-]%'
           OR LOWER(RIGHT(file_name, 4)) <> N'.csv'
    )
    BEGIN
        RAISERROR('Each file must be a relative CSV path beneath /var/opt/datasets.', 16, 1);
        RETURN;
    END;

    -- Iterate over the validated table/file pairs in a local, forward-only cursor.
    DECLARE load_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT tb_name, file_name
        FROM @load_list;

    SET @batch_start_time = SYSDATETIME();

    PRINT '================================================';
    PRINT 'Loading Bronze Layer';
    PRINT '================================================';

    OPEN load_cursor;
    FETCH NEXT FROM load_cursor INTO @tb_name, @file_name;

    BEGIN TRY
        -- Process each pair until the cursor reaches the end of the input.
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @qualified_table = N'bronze.' + QUOTENAME(@tb_name);

            PRINT '------------------------------------------------';
            PRINT 'Loading ' + @qualified_table;
            PRINT 'Source: /var/opt/datasets/' + @file_name;
            PRINT '------------------------------------------------';

            -- Construct dynamic SQL because table names cannot be bound as identifiers.
            SET @sql =
                N'TRUNCATE TABLE ' + @qualified_table + N';' + CHAR(10) +
                N'BULK INSERT ' + @qualified_table +
                N' FROM ''/var/opt/datasets/' +
                REPLACE(@file_name, N'''', N'''''') +
                N''' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', TABLOCK);';

            -- Measure only the actual truncate and bulk insert operation.
            SET @start_time = SYSDATETIME();
            EXEC sys.sp_executesql @sql;
            SET @end_time = SYSDATETIME();

            PRINT '>> Load Duration: ' +
                  CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS nvarchar(20)) +
                  ' milliseconds';

            -- Advance to the next table/file pair.
            FETCH NEXT FROM load_cursor INTO @tb_name, @file_name;
        END;

        SET @batch_end_time = SYSDATETIME();

        PRINT '==========================================';
        PRINT 'Loading Bronze Layer is completed';
        PRINT '   - Total Load Duration: ' +
              CAST(DATEDIFF(MILLISECOND, @batch_start_time, @batch_end_time) AS nvarchar(20)) +
              ' milliseconds';
        PRINT '==========================================';
    END TRY
    BEGIN CATCH
        -- Report the current bulk-load failure without continuing to later pairs.
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOADING';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS nvarchar(20));
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS nvarchar(20));
        PRINT '==========================================';

        -- Close and release the cursor before rethrowing the original error.
        CLOSE load_cursor;
        DEALLOCATE load_cursor;
        THROW;
    END CATCH

    -- Always release cursor resources after the batch succeeds or fails.
    CLOSE load_cursor;
    DEALLOCATE load_cursor;
END;
GO

-- Example call: add pairs to the table-valued parameter, then execute the procedure.
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
