create or replace package body pkg_recon as

    procedure run_reconciliation(p_batch_id number) is
        l_run number;
        l_total number := 0;
        l_match number := 0;
        l_mismatch number := 0;
        l_status varchar2(30);
        l_details varchar2(2000);
    begin
        insert into recon_run(batch_id,status)
        values(p_batch_id,'RUNNING')
        returning recon_run_id into l_run;
        commit;

        for r in (
            with s as (
                select transaction_ref,
                       count(*) source_count,
                       min(amount) source_amount
                from stg_transaction
                where amount>0
                  and currency_code in ('EUR','USD','RON')
                  and transaction_date<=trunc(sysdate)
                group by transaction_ref
            ),
            d as (
                select transaction_ref,
                       count(*) dwh_count,
                       min(amount) dwh_amount
                from fact_transaction
                group by transaction_ref
            )
            select coalesce(s.transaction_ref,d.transaction_ref) transaction_ref,
                   nvl(s.source_count,0) source_count,
                   nvl(d.dwh_count,0) dwh_count,
                   s.source_amount,
                   d.dwh_amount
            from s
            full outer join d on d.transaction_ref=s.transaction_ref
        )
        loop
            l_total := l_total+1;

            if r.source_count>1 then
                l_status := 'DUPLICATE_SOURCE';
                l_details := 'Source count='||r.source_count;
            elsif r.dwh_count>1 then
                l_status := 'DUPLICATE_DWH';
                l_details := 'DWH count='||r.dwh_count;
            elsif r.dwh_count=0 then
                l_status := 'MISSING_DWH';
                l_details := 'Valid source transaction missing from fact';
            elsif abs(r.source_amount-r.dwh_amount)>0.01 then
                l_status := 'AMOUNT_MISMATCH';
                l_details := 'Difference='||to_char(r.source_amount-r.dwh_amount);
            else
                l_status := 'MATCHED';
                l_details := 'Source and DWH values agree';
            end if;

            insert into recon_result(
                recon_run_id,transaction_ref,result_status,
                source_count,dwh_count,source_amount,dwh_amount,
                amount_difference,details
            )
            values(
                l_run,r.transaction_ref,l_status,
                r.source_count,r.dwh_count,r.source_amount,r.dwh_amount,
                case when r.source_amount is not null and r.dwh_amount is not null
                     then r.source_amount-r.dwh_amount end,
                l_details
            );

            if l_status='MATCHED' then
                l_match := l_match+1;
            else
                l_mismatch := l_mismatch+1;
            end if;
        end loop;

        update recon_run
           set status='COMPLETED',
               finished_at=systimestamp,
               total_count=l_total,
               matched_count=l_match,
               mismatch_count=l_mismatch
         where recon_run_id=l_run;
        commit;
    exception
        when others then
            update recon_run
               set status='FAILED',
                   finished_at=systimestamp
             where recon_run_id=l_run;
            commit;
            raise;
    end;

end pkg_recon;
/
