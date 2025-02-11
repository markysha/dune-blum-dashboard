-- part of a query repo
-- query name: Volume
-- query link: https://dune.com/queries/4681646


WITH
    labeled_trades as (
        SELECT
            CASE
                WHEN (
                    project_type = 'launchpad'
                    AND referral_address = '0:C2705CA692BEEFA522895CC0522C3CA88C95D32298E427583E66319C211090EA'
                ) THEN 'Blum'
                WHEN (
                    referral_address = '0:37BD8AC8CF61D228F0FDBAE7877F1348701D76B85B2D671BE43E4872603A1BE7'
                ) THEN 'BlumMigratedToStonfi'
                ELSE 'other' -- uncomment to label morereferral_address
            END label,
            *
        FROM
            ton.dex_trades
        WHERE
            block_date >= (TIMESTAMP '2024-10-01')
    ),
    trades as (
        SELECT
            *
        FROM 
            labeled_trades
        WHERE
            label in ('Blum', 'BlumMigratedToStonfi')
            -- AND block_date >= now() - interval '7' day
    )
SELECT
    -- DATE_TRUNC('day', block_time) as day,
    case
        when (label = 'Blum') then 'on Blum'
        when (label = 'BlumMigratedToStonfi') then 'on DEX'
    end,
    SUM(volume_usd) AS volume
FROM
    trades
GROUP by 1