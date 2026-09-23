insert into dim_product(product_code,product_name,product_group)
values ('CHK','Current Account','DEPOSIT');

insert into dim_product(product_code,product_name,product_group)
values ('SAV','Savings Account','DEPOSIT');

insert into dim_product(product_code,product_name,product_group)
values ('CRD','Credit Card','CARD');

insert into stg_customer values (1001,'Alice Morgan','RETAIL','ACTIVE','RO',date '2026-01-01');
insert into stg_customer values (1002,'Bob Green','PREMIUM','ACTIVE','RO',date '2026-01-01');
insert into stg_customer values (1003,'Carla Stone','RETAIL','ACTIVE','DE',date '2026-01-01');
insert into stg_customer values (1004,null,'RETAIL','ACTIVE','RO',date '2026-01-01');

insert into stg_account values (2001,1001,'RO49AAAA000000000001','CHK','EUR','ACTIVE',date '2024-01-10',2500);
insert into stg_account values (2002,1002,'RO49AAAA000000000002','SAV','EUR','ACTIVE',date '2023-03-05',9000);
insert into stg_account values (2003,1003,'DE49AAAA000000000003','CHK','EUR','ACTIVE',date '2025-08-20',1250);
insert into stg_account values (2004,9999,'RO49AAAA000000000004','CHK','EUR','ACTIVE',date '2026-02-01',500);

insert into stg_transaction values ('TX1001',2001,1001,date '2026-09-20','CREDIT',1000,'EUR',0);
insert into stg_transaction values ('TX1002',2001,1001,date '2026-09-21','DEBIT',150,'EUR',1.50);
insert into stg_transaction values ('TX1003',2002,1002,date '2026-09-21','CREDIT',500,'EUR',0);
insert into stg_transaction values ('TX1004',2003,1003,date '2026-09-22','DEBIT',75,'EUR',0.50);
insert into stg_transaction values ('TX_BAD_AMOUNT',2003,1003,date '2026-09-22','DEBIT',-10,'EUR',0);

commit;
