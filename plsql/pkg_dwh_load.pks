create or replace package pkg_dwh_load as
    procedure load_dates(p_from date,p_to date);
    procedure load_customers(p_batch_id number);
    procedure load_accounts(p_batch_id number);
    procedure load_transactions(p_batch_id number);
    procedure load_balances(p_batch_id number);
    procedure run_full_load;
end pkg_dwh_load;
/
