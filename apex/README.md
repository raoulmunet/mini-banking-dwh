# Oracle APEX Build Guide — Mini Banking DWH

Suggested application name:

```text
Mini Banking DWH Monitor
```

## Page 1 — Executive Dashboard

Recommended KPI cards:

```sql
select
    (select count(*) from dim_customer where is_current='Y') customers,
    (select count(*) from dim_account) accounts,
    (select count(*) from fact_transaction) transactions,
    (select nvl(sum(balance_amount),0) from fact_account_balance
      where date_sk=(select max(date_sk) from fact_account_balance)) total_balance
from dual
```

Add charts for:

- transactions by month;
- net amount by customer segment;
- balances by product;
- latest DQ scores;
- latest reconciliation outcome.

## Page 2 — Batch Monitoring

Interactive Report:

```sql
select *
from batch_run
order by batch_id desc
```

Drill down to:

```sql
select *
from job_run
where batch_id=:P2_BATCH_ID
order by job_run_id
```

## Page 3 — Data Quality

Cards from:

```sql
select entity_name,dq_score,violations_found,status
from v_dq_latest
order by entity_name
```

Violations report:

```sql
select e.entity_name,
       r.rule_code,
       v.business_key,
       v.severity,
       v.violation_message,
       v.detected_at
from dq_violation v
join dq_execution e on e.execution_id=v.execution_id
join dq_rule r on r.rule_id=v.rule_id
order by v.violation_id desc
```

## Page 4 — Reconciliation

Donut chart:

```sql
select result_status label,
       result_count value
from v_recon_latest_summary
```

Detailed report:

```sql
select *
from recon_result
where recon_run_id=(select max(recon_run_id) from recon_run)
order by transaction_ref
```

## Page 5 — Customer 360

Interactive Report on:

```sql
select *
from v_customer_360
order by customer_name,account_number
```

## Page 6 — Account Balances

```sql
select a.account_number,
       p.product_name,
       d.calendar_date,
       f.balance_amount,
       f.currency_code
from fact_account_balance f
join dim_account a on a.account_sk=f.account_sk
join dim_product p on p.product_code=a.product_code
join dim_date d on d.date_sk=f.date_sk
order by d.calendar_date desc,a.account_number
```

## Page 7 — Transaction Explorer

```sql
select f.transaction_ref,
       d.calendar_date,
       c.customer_name,
       a.account_number,
       p.product_name,
       f.transaction_type,
       f.amount,
       f.signed_amount,
       f.fee_amount,
       f.currency_code
from fact_transaction f
join dim_date d on d.date_sk=f.date_sk
join dim_customer c on c.customer_sk=f.customer_sk
join dim_account a on a.account_sk=f.account_sk
join dim_product p on p.product_sk=f.product_sk
order by d.calendar_date desc,f.transaction_sk desc
```

## Page 8 — Lineage / Impact Analysis

Create item `P8_OBJECT_NAME`.

```sql
select *
from table(
    pkg_lineage.downstream(
        p_object_name=>:P8_OBJECT_NAME,
        p_max_depth=>20
    )
)
order by dependency_depth,object_name
```

Add a second region for upstream dependencies.

## Run Full Load button

PL/SQL process:

```plsql
begin
    pkg_dwh_load.run_full_load;
    apex_application.g_print_success_message :=
        'Mini Banking DWH load completed.';
end;
```

The mockup in `docs/assets/apex-dashboard-concept.svg` is a design concept only. Replace it with real screenshots after deployment.
