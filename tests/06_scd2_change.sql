set serveroutput on

-- Simulate a customer segment change.
update stg_customer
set customer_segment='PREMIUM',
    effective_date=date '2026-09-23'
where customer_id=1001;

commit;

declare
    l_batch_id number;
begin
    l_batch_id := pkg_batch.start_batch('SCD2_CUSTOMER_CHANGE_TEST');
    pkg_dwh_load.load_customers(l_batch_id);
    pkg_batch.finish_batch(l_batch_id,'SUCCESS');
end;
/

select customer_id,
       customer_name,
       customer_segment,
       valid_from,
       valid_to,
       is_current
from dim_customer
where customer_id=1001
order by valid_from;
