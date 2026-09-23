set serveroutput on

-- Introduce a controlled DWH mismatch to demonstrate reconciliation.
update fact_transaction
set amount=149
where transaction_ref='TX1002';

commit;

declare
    l_batch_id number;
begin
    select max(batch_id) into l_batch_id from batch_run;
    pkg_recon.run_reconciliation(l_batch_id);
end;
/

select transaction_ref,
       result_status,
       source_amount,
       dwh_amount,
       amount_difference
from recon_result
where recon_run_id=(select max(recon_run_id) from recon_run)
  and transaction_ref='TX1002';

rollback;
