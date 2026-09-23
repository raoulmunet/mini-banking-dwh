create or replace package body pkg_dq as

    function run_entity(p_batch_id number,p_entity_name varchar2) return number
    is
        l_exec_id number;
        l_sql varchar2(32767);
        l_cnt number;
        l_rules number := 0;
        l_viol number := 0;
        l_rows number := 0;
        l_key varchar2(1000);
        l_cur sys_refcursor;
        l_score number;
        l_table varchar2(128);
    begin
        insert into dq_execution(batch_id,entity_name,status)
        values(p_batch_id,upper(p_entity_name),'RUNNING')
        returning execution_id into l_exec_id;
        commit;

        for r in (
            select *
            from dq_rule
            where entity_name=upper(p_entity_name)
              and enabled_flag='Y'
            order by rule_id
        )
        loop
            l_rules := l_rules + 1;
            l_table := dbms_assert.sql_object_name(r.target_table);

            if l_rows=0 then
                l_sql := 'select count(*) from '||l_table;
                execute immediate l_sql into l_rows;
            end if;

            l_sql := 'select count(*) from '||l_table||' where '||r.failure_condition;
            execute immediate l_sql into l_cnt;
            l_viol := l_viol+l_cnt;

            if l_cnt>0 then
                l_sql := 'select '||r.key_expression||' from '||l_table||
                         ' where '||r.failure_condition;
                open l_cur for l_sql;
                loop
                    fetch l_cur into l_key;
                    exit when l_cur%notfound;
                    insert into dq_violation(
                        execution_id,rule_id,business_key,severity,violation_message
                    )
                    values(
                        l_exec_id,r.rule_id,l_key,r.severity,r.rule_code
                    );
                end loop;
                close l_cur;
            end if;
        end loop;

        l_score := round(greatest(0,100-(l_viol/greatest(l_rows*l_rules,1)*100)),2);

        update dq_execution
           set status='COMPLETED',
               finished_at=systimestamp,
               rules_executed=l_rules,
               violations_found=l_viol,
               dq_score=l_score
         where execution_id=l_exec_id;
        commit;

        return l_exec_id;
    exception
        when others then
            begin
                if l_cur%isopen then close l_cur; end if;
            exception
                when invalid_cursor then null;
            end;

            update dq_execution
               set status='FAILED',
                   finished_at=systimestamp
             where execution_id=l_exec_id;
            commit;
            raise;
    end;

end pkg_dq;
/
