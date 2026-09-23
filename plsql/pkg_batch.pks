create or replace package pkg_batch as
    function start_batch(p_batch_name varchar2) return number;
    function start_job(p_batch_id number,p_job_name varchar2) return number;

    procedure finish_job(
        p_job_run_id number,
        p_status varchar2,
        p_rows_read number default 0,
        p_rows_inserted number default 0,
        p_rows_updated number default 0,
        p_rows_rejected number default 0
    );

    procedure finish_batch(p_batch_id number,p_status varchar2);

    procedure log_error(
        p_batch_id number,p_job_run_id number,p_module varchar2,
        p_error_code number,p_error_msg varchar2,p_backtrace varchar2
    );

    procedure reject_row(
        p_batch_id number,p_job_run_id number,p_entity_name varchar2,
        p_source_key varchar2,p_reason varchar2,p_payload clob default null
    );
end pkg_batch;
/
