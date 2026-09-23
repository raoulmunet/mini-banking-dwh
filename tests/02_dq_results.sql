select execution_id,entity_name,status,rules_executed,violations_found,dq_score
from dq_execution
order by execution_id;

select v.violation_id,
       e.entity_name,
       r.rule_code,
       v.business_key,
       v.severity
from dq_violation v
join dq_execution e on e.execution_id=v.execution_id
join dq_rule r on r.rule_id=v.rule_id
order by v.violation_id;
