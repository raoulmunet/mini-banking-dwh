select *
from v_monthly_transaction_summary
order by calendar_month,customer_segment,product_group;

select c.customer_name,
       a.account_number,
       b.balance_amount,
       b.currency_code
from fact_account_balance b
join dim_account a on a.account_sk=b.account_sk
join dim_customer c
  on c.customer_id=a.customer_id
 and c.is_current='Y'
order by c.customer_name,a.account_number;

select customer_id,customer_name,customer_segment,valid_from,valid_to,is_current
from dim_customer
order by customer_id,valid_from;
