CREATE OR REPLACE PROCEDURE bl_cl.load_dwh()
LANGUAGE plpgsql
AS
$$
BEGIN

    CALL bl_cl.log_etl(
        'load_dwh',
        0,
        'DWH load started.'
    );

    ----------------------------------------------------------------
    -- BL_3NF
    ----------------------------------------------------------------
    CALL bl_cl.load_ce_dates();
    CALL bl_cl.load_ce_geographies();
    CALL bl_cl.load_ce_customers();
    CALL bl_cl.load_ce_products_scd();
    CALL bl_cl.load_ce_stores();
    CALL bl_cl.load_ce_employees();
    CALL bl_cl.load_ce_sales();

    ----------------------------------------------------------------
    -- DATA MART
    ----------------------------------------------------------------
    CALL bl_cl.load_dim_time_day();
    CALL bl_cl.load_dim_customer();
    CALL bl_cl.load_dim_store();
    CALL bl_cl.load_dim_employee();
    CALL bl_cl.load_dim_products_scd();
    CALL bl_cl.load_fct_sales_dd();

    CALL bl_cl.log_etl(
        'load_dwh',
        0,
        'DWH load completed successfully.'
    );

EXCEPTION
    WHEN OTHERS THEN

        CALL bl_cl.log_etl(
            'load_dwh',
            0,
            SQLERRM
        );

        RAISE;

END;
$$;

CALL bl_cl.load_dwh();

