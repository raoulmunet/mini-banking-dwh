create or replace package body pkg_batch as

    procedure assert_status(p_status varchar2) is
    begin
        if p_status not in ('RUNNING','SUCCESS','PARTIAL','FAILED') then
            raise_application_error(-20001,'Invalid status: '||p_status);
        end if;
    end;

    function start_batch(p_batch_name varchar2) return number is
        l_id number;
    begin
        insert into batch_run(batch_name,status)
        values(p_batch_name,'RUNNING')
        returning batch_id into l_id;
        commit;
        return l_id;
    end;

    function start_job(p_batch_id number,p_job_name varchar2) return number is
        l_id number;
    begin
        insert into job_run(batch_id,job_name,status)
        values(p_batch_id,p_job_name,'RUNNING')
        returning job_run_id into l_id;
        commit;
        return l_id;
    end;

    procedure finish_job(
        p_job_run_id number,p_status varchar2,
        p_rows_read number default 0,p_rows_inserted number default 0,
        p_rows_updated number default 0,p_rows_rejected number default 0
    ) is
        l_batch_id number;
    begin
        assert_status(p_status);

        update job_run
           set status=p_status,
               finished_at=systimestamp,
               rows_read=p_rows_read,
               rows_inserted=p_rows_inserted,
               rows_updated=p_rows_updated,
               rows_rejected=p_rows_rejected
         where job_run_id=p_job_run_id
        returning batch_id into l_batch_id;

        update batch_run
           set rows_read=rows_read+p_rows_read,
               rows_inserted=rows_inserted+p_rows_inserted,
               rows_updated=rows_updated+p_rows_updated,
               rows_rejected=rows_rejected+p_rows_rejected
         where batch_id=l_batch_id;
        commit;
    end;

    procedure finish_batch(p_batch_id number,p_status varchar2) is
    begin
        assert_status(p_status);
        update batch_run
           set status=p_status,
               finished_at=systimestamp
         where batch_id=p_batch_id;
        commit;
    end;

    procedure log_error(
        p_batch_id number,p_job_run_id number,p_module varchar2,
        p_error_code number,p_error_msg varchar2,p_backtrace varchar2
    ) is
        pragma autonomous_transaction;
    begin
        insert into error_log(
            batch_id,job_run_id,module_name,error_code,error_message,backtrace
        )
        values(
            p_batch_id,p_job_run_id,p_module,p_error_code,
            substr(p_error_msg,1,4000),substr(p_backtrace,1,4000)
        );
        commit;
    end;

    procedure reject_row(
        p_batch_id number,p_job_run_id number,p_entity_name varchar2,
        p_source_key varchar2,p_reason varchar2,p_payload clob default null
    ) is
        pragma autonomous_transaction;
    begin
        insert into rejected_row(
            batch_id,job_run_id,entity_name,source_key,reject_reason,payload
        )
        values(
            p_batch_id,p_job_run_id,p_entity_name,p_source_key,p_reason,p_payload
        );
        commit;
    end;

end pkg_batch;
/
