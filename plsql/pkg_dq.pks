create or replace package pkg_dq as
    function run_entity(p_batch_id number,p_entity_name varchar2) return number;
end pkg_dq;
/
