-- part of a query repo
-- query name: Volume on DEX (after migration)
-- query link: https://dune.com/queries/4682267


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
            label in (
                -- 'Blum' 
                'BlumMigratedToStonfi'
            )
    ),
    stats_by_day as (
        SELECT
            DATE_TRUNC('day', block_time) as day,
            SUM(
                case
                    when (token_bought_address != '0:671963027F7F85659AB55B821671688601CDCF1EE674FC7FBBB1A776A18D34A3') then volume_usd
                end
            ) AS buy,
            SUM(
                case
                    when (token_bought_address = '0:671963027F7F85659AB55B821671688601CDCF1EE674FC7FBBB1A776A18D34A3') then -volume_usd
                end
            ) AS sell
        FROM
            trades
        GROUP BY
            1
    )
-- select * from trades
SELECT
    day,
    buy,
    sell,
    -sell as sell_abs,
    SUM(buy) OVER (
        ORDER BY
            day
    ) AS buy_total,
    SUM(sell) OVER (
        ORDER BY
            day
    ) AS sell_total
FROM
    stats_by_day
ORDER BY 
    1