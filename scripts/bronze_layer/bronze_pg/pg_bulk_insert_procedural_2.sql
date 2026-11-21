-- PostgreSQL equivalent of the single-table loader variants.
-- This overload accepts one table name and one relative CSV path.
CREATE OR REPLACE PROCEDURE bronze.load_bronze(
    p_tb_name text,
    p_file_name text
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_table_exists boolean;
    v_qualified_table text;
    v_file_path text;
BEGIN
    -- Validate the target table in the bronze schema.
    SELECT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_class AS c
        INNER JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'bronze'
          AND c.relname = p_tb_name
          AND c.relkind IN ('r', 'p')
    )
    INTO v_table_exists;

    IF NOT v_table_exists THEN
        RAISE EXCEPTION 'The requested table does not exist in the bronze schema: bronze.%', p_tb_name;
    END IF;

    -- Reject null, absolute, traversal, or non-CSV paths.
    IF p_file_name IS NULL
       OR p_file_name = ''
       OR p_file_name LIKE '/%'
       OR p_file_name LIKE '%..%'
       OR lower(p_file_name) !~ '^[a-z0-9_./-]+[.]csv$'
    THEN
        RAISE EXCEPTION 'Provide a relative CSV filename beneath /var/lib/postgresql/datasets.';
    END IF;

    v_qualified_table := format('%I.%I', 'bronze', p_tb_name);
    v_file_path := '/var/lib/postgresql/datasets/' || p_file_name;

    RAISE NOTICE 'Loading % from %', v_qualified_table, v_file_path;

    -- Truncate the target table and copy the CSV server-side.
    EXECUTE format('TRUNCATE TABLE %I.%I', 'bronze', p_tb_name);

    EXECUTE format(
        'COPY %I.%I FROM %L WITH (FORMAT CSV, HEADER TRUE, DELIMITER %L)',
        'bronze',
        p_tb_name,
        v_file_path,
        ','
    );
END;
$$;

-- Example:
-- CALL bronze.load_bronze('crm_cust_info', 'source_crm/cust_info.csv');
