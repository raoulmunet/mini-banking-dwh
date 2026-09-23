create or replace package body pkg_lineage as

    function downstream(
        p_object_name varchar2,
        p_max_depth number default 10
    ) return lineage_tab_nt pipelined
    is
    begin
        for r in (
            select level dependency_depth,
                   d.name object_name,
                   d.type object_type,
                   d.referenced_name,
                   d.referenced_type,
                   d.dependency_type
            from user_dependencies d
            start with upper(d.referenced_name)=upper(p_object_name)
            connect by nocycle
                prior d.name=d.referenced_name
                and prior d.type=d.referenced_type
            and level<=p_max_depth
        )
        loop
            pipe row(lineage_row_ot(
                r.dependency_depth,r.object_name,r.object_type,
                r.referenced_name,r.referenced_type,r.dependency_type
            ));
        end loop;
        return;
    end;

    function upstream(
        p_object_name varchar2,
        p_max_depth number default 10
    ) return lineage_tab_nt pipelined
    is
    begin
        for r in (
            select level dependency_depth,
                   d.name object_name,
                   d.type object_type,
                   d.referenced_name,
                   d.referenced_type,
                   d.dependency_type
            from user_dependencies d
            start with upper(d.name)=upper(p_object_name)
            connect by nocycle
                prior d.referenced_name=d.name
                and prior d.referenced_type=d.type
            and level<=p_max_depth
        )
        loop
            pipe row(lineage_row_ot(
                r.dependency_depth,r.object_name,r.object_type,
                r.referenced_name,r.referenced_type,r.dependency_type
            ));
        end loop;
        return;
    end;

end pkg_lineage;
/
