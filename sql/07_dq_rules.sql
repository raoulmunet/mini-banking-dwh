insert into dq_rule(rule_code,entity_name,target_table,key_expression,failure_condition,severity)
values('CUST_NAME_NOT_NULL','CUSTOMER','STG_CUSTOMER','to_char(customer_id)','customer_name is null','ERROR');

insert into dq_rule(rule_code,entity_name,target_table,key_expression,failure_condition,severity)
values('CUST_STATUS_VALID','CUSTOMER','STG_CUSTOMER','to_char(customer_id)',
       'status_code not in (''ACTIVE'',''INACTIVE'')','ERROR');

insert into dq_rule(rule_code,entity_name,target_table,key_expression,failure_condition,severity)
values('ACCOUNT_CUSTOMER_EXISTS','ACCOUNT','STG_ACCOUNT','to_char(account_id)',
       'not exists (select 1 from stg_customer c where c.customer_id=stg_account.customer_id and c.customer_name is not null)','ERROR');

insert into dq_rule(rule_code,entity_name,target_table,key_expression,failure_condition,severity)
values('TX_AMOUNT_POSITIVE','TRANSACTION','STG_TRANSACTION','transaction_ref','amount <= 0','ERROR');

insert into dq_rule(rule_code,entity_name,target_table,key_expression,failure_condition,severity)
values('TX_CURRENCY_VALID','TRANSACTION','STG_TRANSACTION','transaction_ref',
       'currency_code not in (''EUR'',''USD'',''RON'')','ERROR');

insert into dq_rule(rule_code,entity_name,target_table,key_expression,failure_condition,severity)
values('TX_DATE_NOT_FUTURE','TRANSACTION','STG_TRANSACTION','transaction_ref',
       'transaction_date > trunc(sysdate)','ERROR');

commit;
