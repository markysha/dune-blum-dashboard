-- part of a query repo
-- query name: Trading Volume
-- query link: https://dune.com/queries/4659721


WITH 
    memepad_trades AS (
        SELECT 
            *
        FROM 
            ton.dex_trades 
        WHERE 
            referral_address = '0:C2705CA692BEEFA522895CC0522C3CA88C95D32298E427583E66319C211090EA' -- 'Blum'
            AND project_type = 'launchpad'
    ),
    memepad_stats AS (
        -- Count from memepads
        SELECT
            DATE_TRUNC('day', block_time) as day,
            COUNT(DISTINCT token_bought_address) as different_coins,
            COUNT(DISTINCT trader_address) as different_traders,
            COUNT(*) as number_of_trades,
            SUM(volume_usd) as volume_usd
        FROM
            memepad_trades
        WHERE
            token_bought_address != '0:0000000000000000000000000000000000000000000000000000000000000000' -- TON
        GROUP BY
            1
    ),
    new_launches as (
        SELECT
            DATE_TRUNC('day', first_trade_time) as day,
            COUNT(*) as new_launches
        FROM (
            SELECT
                token_bought_address,
                MIN(block_time) as first_trade_time
            FROM
                memepad_trades
            GROUP BY
                1
            ) first_appearances
        GROUP BY
            1
    )
SELECT
    *,
    SUM(new_launches) OVER(ORDER BY ms.day) AS new_launches_total,
    SUM(volume_usd) OVER(ORDER BY ms.day) AS volume_usd_total
FROM
    memepad_stats ms
LEFT JOIN new_launches nl ON ms.day = nl.day