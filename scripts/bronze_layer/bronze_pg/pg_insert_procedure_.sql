-- PostgreSQL
-- Create a composite type for each table and CSV file pair passed to the loader.
DO $$
BEGIN
    IF to_regtype('bronze.load_file_pair') IS NULL THEN
        CREATE TYPE bronze.load_file_pair AS
        (
            tb_name text,
            file_name text
        );
    END IF;
END;
$$;

-- Create or replace the stored procedure that loads one or more bronze tables.
CREATE OR REPLACE PROCEDURE bronze.load_bronze(
    p_load_list bronze.load_file_pair[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_item bronze.load_file_pair;
    v_table_exists boolean;
    v_file_path text;
    v_qualified_table text;
    v_start_time timestamptz;
    v_end_time timestamptz;
    v_batch_start_time timestamptz;
    v_batch_end_time timestamptz;
    v_load_duration_ms bigint;
BEGIN
    -- Reject a null or empty array before starting any table loads.
    IF p_load_list IS NULL OR cardinality(p_load_list) = 0 THEN
        RAISE EXCEPTION 'Provide at least one table and file pair.';
    END IF;

    -- Validate every target table before loading any of them.
    FOREACH v_item IN ARRAY p_load_list LOOP
        SELECT EXISTS
        (
            SELECT 1
            FROM pg_catalog.pg_class AS c
            INNER JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
            WHERE n.nspname = 'bronze'
              AND c.relname = v_item.tb_name
              AND c.relkind IN ('r', 'p')
        )
        INTO v_table_exists;

        IF NOT v_table_exists THEN
            RAISE EXCEPTION 'A requested table does not exist in the bronze schema: bronze.%',
                v_item.tb_name;
        END IF;

        -- Accept only relative CSV paths beneath /var/lib/postgresql/datasets.
        IF v_item.file_name IS NULL
           OR v_item.file_name = ''
           OR v_item.file_name LIKE '/%'
           OR v_item.file_name LIKE '%..%'
           OR lower(v_item.file_name) !~ '^[a-z0-9_./-]+[.]csv$'
        THEN
            RAISE EXCEPTION
                'Each file must be a relative CSV path beneath /var/lib/postgresql/datasets.';
        END IF;
    END LOOP;

    -- Record the complete batch start time.
    v_batch_start_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '================================================';

    -- Process each validated table/file pair.
    FOREACH v_item IN ARRAY p_load_list LOOP
        v_qualified_table := format('%I.%I', 'bronze', v_item.tb_name);
        v_file_path := '/var/lib/postgresql/datasets/' || v_item.file_name;

        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE 'Loading %', v_qualified_table;
        RAISE NOTICE 'Source: %', v_file_path;
        RAISE NOTICE '------------------------------------------------';

        -- Measure only the truncate-and-copy operation for this pair.
        v_start_time := clock_timestamp();

        BEGIN
            -- Truncate the target table before starting the load.
            EXECUTE format('TRUNCATE TABLE %I.%I', 'bronze', v_item.tb_name);

            -- Copy the CSV server-side with the header row excluded.
            EXECUTE format(
                'COPY %I.%I FROM %L WITH (FORMAT CSV, HEADER TRUE, DELIMITER %L)',
                'bronze',
                v_item.tb_name,
                v_file_path,
                ','
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '==========================================';
            RAISE NOTICE 'ERROR OCCURRED DURING BRONZE LAYER LOADING';
            RAISE NOTICE 'Table: %', v_qualified_table;
            RAISE NOTICE 'Error: %', SQLERRM;
            RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
            RAISE NOTICE '==========================================';
            RAISE;
        END;

        v_end_time := clock_timestamp();
        v_load_duration_ms :=
            EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::bigint;

        RAISE NOTICE '>> Load Duration: % milliseconds', v_load_duration_ms;
    END LOOP;

    -- Report the total batch duration after every pair succeeds.
    v_batch_end_time := clock_timestamp();
    v_load_duration_ms :=
        EXTRACT(MILLISECONDS FROM (v_batch_end_time - v_batch_start_time))::bigint;

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Bronze Layer is completed';
    RAISE NOTICE '   - Total Load Duration: % milliseconds', v_load_duration_ms;
    RAISE NOTICE '==========================================';
END;
$$;

-- Example call: add pairs to the composite array, then execute the procedure.
-- CALL bronze.load_bronze(ARRAY[
--     ROW('crm_cust_info', 'source_crm/cust_info.csv')::bronze.load_file_pair,
--     ROW('crm_prd_info', 'source_crm/prd_info.csv')::bronze.load_file_pair,
--     ROW('crm_sales_details', 'source_crm/sales_details.csv')::bronze.load_file_pair,
--     ROW('erp_cust_az12', 'source_erp/CUST_AZ12.csv')::bronze.load_file_pair,
--     ROW('erp_loc_a101', 'source_erp/LOC_A101.csv')::bronze.load_file_pair,
--     ROW('erp_px_cat_g1v2', 'source_erp/PX_CAT_G1V2.csv')::bronze.load_file_pair
-- ]);