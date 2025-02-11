-- part of a query repo
-- query name: Total Metrics
-- query link: https://dune.com/queries/4659780


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
            -- COUNT(DISTINCT token_bought_address) as memepad_coins,
            SUM(volume_usd) as volume_usd
        FROM
            memepad_trades
            -- (
            --     SELECT
            --         token_bought_address,
            --         MIN(block_time) as first_trade_time
            --     FROM
            --         memepad_trades
            --     GROUP BY
            --         1
            -- ) first_appearances
        WHERE
            token_bought_address != '0:0000000000000000000000000000000000000000000000000000000000000000' -- TON
        GROUP BY
            1
    )
SELECT
    SUM(volume_usd) as total_volume,
    COUNT(distinct token_bought_address) as total_tokens,
    COUNT(distinct trader_address) as total_traders,
    COUNT(*) as total_trades
FROM
    memepad_trades