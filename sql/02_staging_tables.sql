create table stg_customer (
    customer_id number,
    customer_name varchar2(200),
    customer_segment varchar2(30),
    status_code varchar2(20),
    country_code varchar2(2),
    effective_date date
);

create table stg_account (
    account_id number,
    customer_id number,
    account_number varchar2(34),
    product_code varchar2(30),
    currency_code varchar2(3),
    status_code varchar2(20),
    opened_date date,
    current_balance number(18,2)
);

create table stg_transaction (
    transaction_ref varchar2(100),
    account_id number,
    customer_id number,
    transaction_date date,
    transaction_type varchar2(20),
    amount number(18,2),
    currency_code varchar2(3),
    fee_amount number(18,2)
);
