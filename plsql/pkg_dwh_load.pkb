create or replace package body pkg_dwh_load as

    procedure load_dates(p_from date,p_to date) is
        l_date date := trunc(p_from);
    begin
        while l_date<=trunc(p_to) loop
            merge into dim_date d
            using (
                select to_number(to_char(l_date,'YYYYMMDD')) date_sk,
                       l_date calendar_date,
                       to_number(to_char(l_date,'DD')) calendar_day,
                       to_char(l_date,'YYYY-MM') calendar_month,
                       to_number(to_char(l_date,'YYYY')) calendar_year,
                       trim(to_char(l_date,'Month')) month_name,
                       to_number(to_char(l_date,'Q')) quarter_no
                from dual
            ) s
            on (d.date_sk=s.date_sk)
            when not matched then insert(
                date_sk,calendar_date,calendar_day,calendar_month,
                calendar_year,month_name,quarter_no
            ) values(
                s.date_sk,s.calendar_date,s.calendar_day,s.calendar_month,
                s.calendar_year,s.month_name,s.quarter_no
            );
            l_date := l_date+1;
        end loop;
        commit;
    end;

    procedure load_customers(p_batch_id number) is
        l_job number;
        l_read number:=0;
        l_ins number:=0;
        l_upd number:=0;
        l_current_count number;
        l_changed number;
    begin
        l_job := pkg_batch.start_job(p_batch_id,'LOAD_CUSTOMERS');

        for r in (
            select *
            from stg_customer
            where customer_id is not null
              and customer_name is not null
              and status_code in ('ACTIVE','INACTIVE')
        )
        loop
            l_read := l_read+1;

            select count(*)
            into l_current_count
            from dim_customer
            where customer_id=r.customer_id
              and is_current='Y';

            if l_current_count=0 then
                insert into dim_customer(
                    customer_id,customer_name,customer_segment,status_code,
                    country_code,valid_from,valid_to,is_current
                )
                values(
                    r.customer_id,r.customer_name,r.customer_segment,r.status_code,
                    r.country_code,r.effective_date,null,'Y'
                );
                l_ins := l_ins+1;
            else
                select count(*)
                into l_changed
                from dim_customer
                where customer_id=r.customer_id
                  and is_current='Y'
                  and (
                      nvl(customer_name,'#')<>nvl(r.customer_name,'#')
                      or nvl(customer_segment,'#')<>nvl(r.customer_segment,'#')
                      or nvl(status_code,'#')<>nvl(r.status_code,'#')
                      or nvl(country_code,'#')<>nvl(r.country_code,'#')
                  );

                if l_changed>0 then
                    update dim_customer
                       set valid_to=r.effective_date-1,
                           is_current='N'
                     where customer_id=r.customer_id
                       and is_current='Y';

                    insert into dim_customer(
                        customer_id,customer_name,customer_segment,status_code,
                        country_code,valid_from,valid_to,is_current
                    )
                    values(
                        r.customer_id,r.customer_name,r.customer_segment,r.status_code,
                        r.country_code,r.effective_date,null,'Y'
                    );
                    l_upd := l_upd+1;
                    l_ins := l_ins+1;
                end if;
            end if;
        end loop;

        commit;
        pkg_batch.finish_job(l_job,'SUCCESS',l_read,l_ins,l_upd,0);
    exception
        when others then
            rollback;
            pkg_batch.log_error(
                p_batch_id,l_job,'LOAD_CUSTOMERS',
                sqlcode,sqlerrm,dbms_utility.format_error_backtrace
            );
            pkg_batch.finish_job(l_job,'FAILED');
            raise;
    end;

    procedure load_accounts(p_batch_id number) is
        l_job number;
        l_read number:=0;
        l_ins number:=0;
        l_upd number:=0;
        l_exists number;
    begin
        l_job := pkg_batch.start_job(p_batch_id,'LOAD_ACCOUNTS');

        for r in (
            select a.*
            from stg_account a
            where exists (
                select 1
                from stg_customer c
                where c.customer_id=a.customer_id
                  and c.customer_name is not null
            )
        )
        loop
            l_read := l_read+1;
            select count(*) into l_exists
            from dim_account
            where account_id=r.account_id;

            merge into dim_account d
            using (
                select r.account_id account_id,
                       r.account_number account_number,
                       r.customer_id customer_id,
                       r.product_code product_code,
                       r.currency_code currency_code,
                       r.status_code status_code,
                       r.opened_date opened_date
                from dual
            ) s
            on (d.account_id=s.account_id)
            when matched then update set
                d.account_number=s.account_number,
                d.customer_id=s.customer_id,
                d.product_code=s.product_code,
                d.currency_code=s.currency_code,
                d.status_code=s.status_code,
                d.opened_date=s.opened_date
            when not matched then insert(
                account_id,account_number,customer_id,product_code,
                currency_code,status_code,opened_date
            ) values(
                s.account_id,s.account_number,s.customer_id,s.product_code,
                s.currency_code,s.status_code,s.opened_date
            );

            if l_exists=0 then l_ins:=l_ins+1; else l_upd:=l_upd+1; end if;
        end loop;

        commit;
        pkg_batch.finish_job(l_job,'SUCCESS',l_read,l_ins,l_upd,0);
    exception
        when others then
            rollback;
            pkg_batch.log_error(
                p_batch_id,l_job,'LOAD_ACCOUNTS',
                sqlcode,sqlerrm,dbms_utility.format_error_backtrace
            );
            pkg_batch.finish_job(l_job,'FAILED');
            raise;
    end;

    procedure load_transactions(p_batch_id number) is
        l_job number;
        l_read number:=0;
        l_ins number:=0;
        l_rej number:=0;
        l_customer_sk number;
        l_account_sk number;
        l_product_sk number;
        l_exists number;
    begin
        l_job := pkg_batch.start_job(p_batch_id,'LOAD_TRANSACTIONS');

        for r in (select * from stg_transaction)
        loop
            l_read := l_read+1;

            if r.amount<=0
               or r.currency_code not in ('EUR','USD','RON')
               or r.transaction_date>trunc(sysdate)
            then
                l_rej := l_rej+1;
                pkg_batch.reject_row(
                    p_batch_id,l_job,'TRANSACTION',r.transaction_ref,
                    'Transaction failed business validation'
                );
                continue;
            end if;

            begin
                select customer_sk
                into l_customer_sk
                from dim_customer
                where customer_id=r.customer_id
                  and is_current='Y';

                select a.account_sk,p.product_sk
                into l_account_sk,l_product_sk
                from dim_account a
                join dim_product p on p.product_code=a.product_code
                where a.account_id=r.account_id;
            exception
                when no_data_found then
                    l_rej := l_rej+1;
                    pkg_batch.reject_row(
                        p_batch_id,l_job,'TRANSACTION',r.transaction_ref,
                        'Missing dimension member'
                    );
                    continue;
            end;

            select count(*) into l_exists
            from fact_transaction
            where transaction_ref=r.transaction_ref;

            if l_exists=0 then
                insert into fact_transaction(
                    transaction_ref,customer_sk,account_sk,product_sk,date_sk,
                    transaction_type,amount,signed_amount,fee_amount,currency_code
                )
                values(
                    r.transaction_ref,l_customer_sk,l_account_sk,l_product_sk,
                    to_number(to_char(r.transaction_date,'YYYYMMDD')),
                    r.transaction_type,r.amount,
                    case when r.transaction_type='DEBIT' then -r.amount else r.amount end,
                    nvl(r.fee_amount,0),r.currency_code
                );
                l_ins := l_ins+1;
            end if;
        end loop;

        commit;
        pkg_batch.finish_job(
            l_job,
            case when l_rej>0 then 'PARTIAL' else 'SUCCESS' end,
            l_read,l_ins,0,l_rej
        );
    exception
        when others then
            rollback;
            pkg_batch.log_error(
                p_batch_id,l_job,'LOAD_TRANSACTIONS',
                sqlcode,sqlerrm,dbms_utility.format_error_backtrace
            );
            pkg_batch.finish_job(l_job,'FAILED');
            raise;
    end;

    procedure load_balances(p_batch_id number) is
        l_job number;
        l_read number:=0;
        l_count number:=0;
    begin
        l_job := pkg_batch.start_job(p_batch_id,'LOAD_BALANCES');

        for r in (
            select a.current_balance,a.currency_code,d.account_sk
            from stg_account a
            join dim_account d on d.account_id=a.account_id
        )
        loop
            l_read := l_read+1;

            merge into fact_account_balance f
            using (
                select r.account_sk account_sk,
                       to_number(to_char(trunc(sysdate),'YYYYMMDD')) date_sk,
                       r.current_balance balance_amount,
                       r.currency_code currency_code
                from dual
            ) s
            on (f.account_sk=s.account_sk and f.date_sk=s.date_sk)
            when matched then update set
                f.balance_amount=s.balance_amount,
                f.currency_code=s.currency_code,
                f.loaded_at=systimestamp
            when not matched then insert(
                account_sk,date_sk,balance_amount,currency_code
            ) values(
                s.account_sk,s.date_sk,s.balance_amount,s.currency_code
            );

            l_count := l_count+1;
        end loop;

        commit;
        pkg_batch.finish_job(l_job,'SUCCESS',l_read,l_count,0,0);
    exception
        when others then
            rollback;
            pkg_batch.log_error(
                p_batch_id,l_job,'LOAD_BALANCES',
                sqlcode,sqlerrm,dbms_utility.format_error_backtrace
            );
            pkg_batch.finish_job(l_job,'FAILED');
            raise;
    end;

    procedure run_full_load is
        l_batch number;
        l_dummy number;
        l_dq_issues number;
        l_final varchar2(20):='SUCCESS';
    begin
        l_batch := pkg_batch.start_batch('MINI_BANKING_DWH_FULL_LOAD');

        load_dates(date '2026-01-01',add_months(trunc(sysdate,'YYYY'),12)-1);

        l_dummy := pkg_dq.run_entity(l_batch,'CUSTOMER');
        l_dummy := pkg_dq.run_entity(l_batch,'ACCOUNT');
        l_dummy := pkg_dq.run_entity(l_batch,'TRANSACTION');

        load_customers(l_batch);
        load_accounts(l_batch);
        load_transactions(l_batch);
        load_balances(l_batch);

        select count(*)
        into l_dq_issues
        from dq_execution
        where batch_id=l_batch
          and violations_found>0;

        if l_dq_issues>0 then
            l_final := 'PARTIAL';
        end if;

        pkg_batch.finish_batch(l_batch,l_final);
        pkg_recon.run_reconciliation(l_batch);
    exception
        when others then
            if l_batch is not null then
                pkg_batch.finish_batch(l_batch,'FAILED');
            end if;
            raise;
    end;

end pkg_dwh_load;
/
