-- part of a query repo
-- query name: Top 1000 Users Ordered by Volume
-- query link: https://dune.com/queries/4664461


WITH
    leaderboard AS (
        SELECT
            RANK() OVER (
                ORDER BY
                    SUM(volume_usd) DESC
            ) AS userRank,
            SUM(volume_usd) AS totalVolumeUSD,
            -- SUM(IF(version = 1, volume_usd, 0)) AS v1VolumeUSD,
            -- SUM(IF(version = 2, volume_usd, 0)) AS v2VolumeUSD,
            COUNT(DISTINCT (tx_hash)) AS numberOfTrades,
            COUNT(DISTINCT (pool_address)) AS numberOfPairs,
            COUNT(DISTINCT (block_date)) AS numberOfActiveDays,
            MIN(block_time) AS firstTradeDate,
            MAX(block_time) AS lastTradeDate,
            trader_address AS userAddress
        FROM
            ton.dex_trades AS trades
        WHERE
            referral_address = '0:C2705CA692BEEFA522895CC0522C3CA88C95D32298E427583E66319C211090EA' -- 'Blum'
            AND project_type = 'launchpad'
        GROUP BY
            trader_address
        ORDER BY
            totalVolumeUSD DESC
    )
SELECT
    userRank,
    userAddress AS user,
    get_href('https://tonviewer.com/' || userAddress, ton_address_raw_to_user_friendly(userAddress, false)) as user_url,
    totalVolumeUSD,
    -- v1VolumeUSD,
    -- v2VolumeUSD,
    numberOfTrades,
    numberOfPairs,
    numberOfActiveDays,
    firstTradeDate,
    lastTradeDate,
    userAddress
FROM
    leaderboard
ORDER BY
    userRank ASC
LIMIT
    1000