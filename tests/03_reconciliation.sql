select *
from v_recon_latest_summary
order by result_status;

select transaction_ref,result_status,source_amount,dwh_amount,amount_difference,details
from recon_result
where recon_run_id=(select max(recon_run_id) from recon_run)
order by transaction_ref;
