begin execute immediate 'drop package pkg_dwh_load'; exception when others then null; end;
/
begin execute immediate 'drop package pkg_lineage'; exception when others then null; end;
/
begin execute immediate 'drop package pkg_recon'; exception when others then null; end;
/
begin execute immediate 'drop package pkg_dq'; exception when others then null; end;
/
begin execute immediate 'drop package pkg_batch'; exception when others then null; end;
/
begin execute immediate 'drop view v_monthly_transaction_summary'; exception when others then null; end;
/
begin execute immediate 'drop view v_customer_360'; exception when others then null; end;
/
begin execute immediate 'drop view v_recon_latest_summary'; exception when others then null; end;
/
begin execute immediate 'drop view v_dq_latest'; exception when others then null; end;
/
begin execute immediate 'drop view v_batch_latest'; exception when others then null; end;
/
begin execute immediate 'drop view v_lineage_objects'; exception when others then null; end;
/
begin execute immediate 'drop table fact_account_balance purge'; exception when others then null; end;
/
begin execute immediate 'drop table fact_transaction purge'; exception when others then null; end;
/
begin execute immediate 'drop table dim_date purge'; exception when others then null; end;
/
begin execute immediate 'drop table dim_product purge'; exception when others then null; end;
/
begin execute immediate 'drop table dim_account purge'; exception when others then null; end;
/
begin execute immediate 'drop table dim_customer purge'; exception when others then null; end;
/
begin execute immediate 'drop table stg_transaction purge'; exception when others then null; end;
/
begin execute immediate 'drop table stg_account purge'; exception when others then null; end;
/
begin execute immediate 'drop table stg_customer purge'; exception when others then null; end;
/
begin execute immediate 'drop table recon_result purge'; exception when others then null; end;
/
begin execute immediate 'drop table recon_run purge'; exception when others then null; end;
/
begin execute immediate 'drop table dq_violation purge'; exception when others then null; end;
/
begin execute immediate 'drop table dq_execution purge'; exception when others then null; end;
/
begin execute immediate 'drop table dq_rule purge'; exception when others then null; end;
/
begin execute immediate 'drop table rejected_row purge'; exception when others then null; end;
/
begin execute immediate 'drop table error_log purge'; exception when others then null; end;
/
begin execute immediate 'drop table job_run purge'; exception when others then null; end;
/
begin execute immediate 'drop table batch_run purge'; exception when others then null; end;
/
begin execute immediate 'drop type lineage_tab_nt force'; exception when others then null; end;
/
begin execute immediate 'drop type lineage_row_ot force'; exception when others then null; end;
/
