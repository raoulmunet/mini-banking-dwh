create or replace view v_batch_latest as
select *
from (
    select b.*, row_number() over(order by batch_id desc) rn
    from batch_run b
)
where rn=1;

create or replace view v_dq_latest as
select *
from (
    select d.*,
           row_number() over(partition by entity_name order by execution_id desc) rn
    from dq_execution d
)
where rn=1;

create or replace view v_recon_latest_summary as
select result_status,
       count(*) result_count,
       sum(abs(nvl(amount_difference,0))) total_abs_difference
from recon_result
where recon_run_id=(select max(recon_run_id) from recon_run)
group by result_status;

create or replace view v_customer_360 as
select c.customer_sk,
       c.customer_id,
       c.customer_name,
       c.customer_segment,
       c.status_code customer_status,
       a.account_id,
       a.account_number,
       a.product_code,
       a.currency_code,
       a.status_code account_status
from dim_customer c
left join dim_account a on a.customer_id=c.customer_id
where c.is_current='Y';

create or replace view v_monthly_transaction_summary as
select d.calendar_month,
       c.customer_segment,
       p.product_group,
       count(*) transaction_count,
       sum(f.signed_amount) net_amount,
       sum(f.fee_amount) total_fees
from fact_transaction f
join dim_date d on d.date_sk=f.date_sk
join dim_customer c on c.customer_sk=f.customer_sk
join dim_product p on p.product_sk=f.product_sk
group by d.calendar_month,c.customer_segment,p.product_group;
