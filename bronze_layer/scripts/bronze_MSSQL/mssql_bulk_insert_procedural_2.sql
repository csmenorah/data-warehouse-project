CREATE OR ALTER PROCEDURE bronze.load_bronze
    @tb_name SYSNAME,
    @file_name NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @full_path NVARCHAR(4000);

    -- Build the full file path safely
    SET @full_path = N'/var/opt/datasets/source_crm/' + REPLACE(@file_name, '''', '''''');

    -- Build dynamic T-SQL with a safely quoted table name
    SET @sql = N'TRUNCATE TABLE bronze.' + QUOTENAME(@tb_name) + N';' + CHAR(13) + CHAR(10) +
               N'BULK INSERT bronze.' + QUOTENAME(@tb_name) + N' ' +
               N'FROM ' + QUOTENAME(@full_path, '''') + N' ' +
               N'WITH (' +
               N'    FIRSTROW = 2,' +
               N'    FIELDTERMINATOR = '','',' +
               N'    TABLOCK' +
               N');';

    EXEC sp_executesql @sql;
END;
GO

-- SQL Server
CREATE OR ALTER PROCEDURE bronze.load_bronze
    @tb_name sysname,
    @file_name nvarchar(255)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.tables AS t
        INNER JOIN sys.schemas AS s 
        ON s.schema_id = t.schema_id
        WHERE s.name = N'bronze'
          AND t.name = @tb_name
    )
    BEGIN
        THROW 50001, 'The requested table does not exist in the bronze schema.', 1;
    END;

    IF @file_name IS NULL
       OR @file_name = N''
       OR @file_name LIKE N'%[^A-Za-z0-9_.-]%'
       OR LOWER(RIGHT(@file_name, 4)) <> N'.csv'
    BEGIN
        THROW 50002, 'Provide a CSV filename without a directory path.', 1;
    END;

    DECLARE @qualified_table nvarchar(258) = N'bronze.' + QUOTENAME(@tb_name);
    DECLARE @sql nvarchar(max) =
        N'TRUNCATE TABLE ' + @qualified_table + N';' + CHAR(10) +
        N'BULK INSERT ' + @qualified_table +
        N' FROM ''/var/opt/datasets/source_crm/' +
        REPLACE(@file_name, N'''', N'''''') +
        N''' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', TABLOCK);';

    EXEC sys.sp_executesql @sql;
END;
