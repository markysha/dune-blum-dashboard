-- part of a query repo
-- query name: Blum special on-chain activity
-- query link: https://dune.com/queries/4704137


with
    addresses as (
        select            
            upper(ton_address_user_friendly_to_raw(address)) as address,
            address as uf_address
        from
            unnest (
                array[
                    -- 'EQCCR3ChGA_4qY9s9HjASX7OmBaAFHZi8_lkqlkDl6R8FPvW', -- token deployer
                    -- 'EQC93yQtbGtWWvwErnCVhiV6URME11qO5HO4WVlIKGoZfOpd', -- ton.fun token deployer
                    -- 'UQA9nNvUSLAebJxzhHv5sxMWK_RXrxk4MYXR39JMbqvrcxPx', -- blumhowwallet.ton 
                    'EQA9nNvUSLAebJxzhHv5sxMWK_RXrxk4MYXR39JMbqvrc040' -- was used in open leaque
                    -- 'EQBH8XOCAYnxMx_YeZENHcBrawu7S5fXgk1Vz48YjPw6OEEz', -- multisig reserves
                    -- 'EQDCcFymkr7vpSKJXMBSLDyojJXTIpjkJ1g-ZjGcIRCQ6gHc'
                ]
            ) as c (address)
    ),
    dest as (
        select
            destination as address, 
            opcode,
            source as src,
            a.uf_address,
            -- destination,
            -- count(*) as cnt,
            value,
            'dest' as type,
            block_date
        from
            ton.messages m
            join addresses a on m.destination = a.address
        where
            block_date > TIMESTAMP '2024-01-01'
            and opcode = 0
        -- group by
        --     1, 2
    )
    -- src as (
    --     select
    --         source as address, 
    --         opcode,
    --         min(a.uf_address) as uf_address,
    --         count(*) as cnt,
    --         sum(value) as sum_value,
    --         'src' as type
    --     from
    --         ton.messages m
    --         join addresses a on m.source = a.address
    --     where
    --         block_date > TIMESTAMP '2024-10-01'
    --     group by
    --         1, 2
    -- ),
    -- trx as (
    --     select
    --         account as address, 
    --         NULL as opcode,
    --         min(a.uf_address) as uf_address,
    --         count(*) as cnt,
    --         NULL as sum_value,
    --         'trx' as type
    --     from
    --         ton.transactions m
    --         join addresses a on m.account = a.address
    --     where
    --         block_date > TIMESTAMP '2024-10-01'
    --     group by
    --         1, 2
    -- )
select
    block_date,
    count(*) as cnt,
    count(distinct src) as cnt_distinct_src,
    sum(value / 1e9) as sum_value 
from
    dest
group by
    block_date
-- where
--     source in (select address from addresses)
--     OR
--     destination in (select address from addresses)
-- gr
