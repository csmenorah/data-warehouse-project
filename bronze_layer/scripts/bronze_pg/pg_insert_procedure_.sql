-- Create a composite type for one table and file pair.
DO $$
BEGIN
    IF to_regtype('bronze.load_file_pair') IS NULL THEN
        CREATE TYPE bronze.load_file_pair AS (
            tb_name text,
            file_name text
        );
    END IF;
END;
$$;

-- Create or replace the procedure that loads multiple table/file pairs.
CREATE OR REPLACE PROCEDURE bronze.load_bronze(
    p_load_list bronze.load_file_pair[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_item bronze.load_file_pair;
    v_table_exists boolean;
    v_file_path text;
BEGIN
    -- Reject a null or empty list.
    IF p_load_list IS NULL OR cardinality(p_load_list) = 0 THEN
        RAISE EXCEPTION 'Provide at least one table and file pair.';
    END IF;

    -- Process each table/file pair.
    FOREACH v_item IN ARRAY p_load_list LOOP
        -- Confirm the target is a table in the bronze schema.
        SELECT EXISTS (
            SELECT 1
            FROM pg_catalog.pg_class AS c
            JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
            WHERE n.nspname = 'bronze'
              AND c.relname = v_item.tb_name
              AND c.relkind IN ('r', 'p')
        )
        INTO v_table_exists;

        IF NOT v_table_exists THEN
            RAISE EXCEPTION 'Table bronze.% does not exist.', v_item.tb_name;
        END IF;

        -- Accept only relative CSV paths beneath the datasets directory.
        IF v_item.file_name IS NULL
           OR v_item.file_name !~ '^[A-Za-z0-9_./-]+[.]csv$'
           OR v_item.file_name LIKE '/%'
           OR v_item.file_name LIKE '%..%' THEN
            RAISE EXCEPTION
                'File must be a relative CSV path beneath /var/lib/postgresql/datasets.';
        END IF;

        v_file_path := '/var/lib/postgresql/datasets/' || v_item.file_name;

        -- Truncate the target and import the CSV with its header row.
        EXECUTE format('TRUNCATE TABLE %I.%I', 'bronze', v_item.tb_name);

        EXECUTE format(
            'COPY %I.%I FROM %L WITH (FORMAT CSV, HEADER TRUE, DELIMITER %L)',
            'bronze',
            v_item.tb_name,
            v_file_path,
            ','
        );
    END LOOP;
END;
$$;

-- Example call.
-- CALL bronze.load_bronze(ARRAY[
--     ROW('crm_cust_info', 'source_crm/cust_info.csv')::bronze.load_file_pair,
--     ROW('crm_prd_info', 'source_crm/prd_info.csv')::bronze.load_file_pair,
--     ROW('crm_sales_details', 'source_crm/sales_details.csv')::bronze.load_file_pair,
--     ROW('erp_cust_az12', 'source_erp/CUST_AZ12.csv')::bronze.load_file_pair,
--     ROW('erp_loc_a101', 'source_erp/LOC_A101.csv')::bronze.load_file_pair,
--     ROW('erp_px_cat_g1v2', 'source_erp/PX_CAT_G1V2.csv')::bronze.load_file_pair
-- ]);