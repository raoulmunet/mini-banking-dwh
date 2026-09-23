set serveroutput on

begin
    pkg_dwh_load.run_full_load;
end;
/

select batch_id,batch_name,status,rows_read,rows_inserted,rows_updated,rows_rejected
from batch_run
order by batch_id desc
fetch first 1 row only;
