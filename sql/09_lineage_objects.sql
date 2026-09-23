create or replace type lineage_row_ot as object (
    dependency_depth number,
    object_name varchar2(128),
    object_type varchar2(30),
    referenced_name varchar2(128),
    referenced_type varchar2(30),
    dependency_type varchar2(30)
);
/

create or replace type lineage_tab_nt as table of lineage_row_ot;
/

create or replace view v_lineage_objects as
select object_name,object_type,status,created,last_ddl_time
from user_objects
where object_type in (
    'TABLE','VIEW','MATERIALIZED VIEW','PACKAGE','PACKAGE BODY',
    'PROCEDURE','FUNCTION','TRIGGER'
);
