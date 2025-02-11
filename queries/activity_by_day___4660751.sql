-- part of a query repo
-- query name: Activity By Day
-- query link: https://dune.com/queries/4660751


WITH
    tradesWithFees AS (
        SELECT
            block_time,
            block_date,
            volume_usd AS amount_usd,
            trades.version,
            trader_address AS tx_from,
            pool_address AS project_contract_address,
            tx_hash
        FROM
            ton.dex_trades AS trades
        WHERE
            referral_address = '0:C2705CA692BEEFA522895CC0522C3CA88C95D32298E427583E66319C211090EA' -- 'Blum'
            AND project_type = 'launchpad'
    ),
    firstUserOccurrences AS (
        SELECT
            tx_from AS user,
            MIN(block_date) AS firstTradeDate
        FROM
            tradesWithFees
        GROUP BY
            tx_from
    )
SELECT
    block_date,
    SUM(amount_usd) AS volumeUSD,
    -- SUM(IF(version = 1, amount_usd, NULL)) AS v1VolumeUSD,
    -- SUM(IF(version = 2, amount_usd, NULL)) AS v2VolumeUSD,
    --SUM(fee_usd) As feesUSD,
    --SUM(IF(version = 1, fee_usd, NULL)) AS v1FeesUSD,
    --SUM(IF(version = 2, fee_usd, NULL)) AS v2FeesUSD,
    COUNT(DISTINCT (tx_from)) AS numberOfUsers,
    COALESCE(COUNT(DISTINCT (firstUserOccurrences.user)), 0) AS numberOfNewUsers,
    COUNT(DISTINCT (tx_hash)) AS numberOfTrades,
    COUNT(DISTINCT (project_contract_address)) AS numberOfPairs,
    COUNT(DISTINCT (trades.tx_from)) - COALESCE(COUNT(DISTINCT (firstUserOccurrences.user)), 0) AS numberOfReturningUsers,
    SUM(
        COALESCE(COUNT(DISTINCT (firstUserOccurrences.user)), 0)
    ) OVER (
        ORDER BY
            block_date
    ) AS cumulative_numberOfNewUsers,
    SUM(SUM(amount_usd)) OVER (
        ORDER BY
            block_date
    ) AS cumulative_volumeUSD,
    SUM(COUNT(DISTINCT (tx_hash))) OVER (
        ORDER BY
            block_date
    ) AS cumulative_numberOfTrades
FROM
    tradesWithFees AS trades
    LEFT OUTER JOIN firstUserOccurrences ON (
        trades.tx_from = firstUserOccurrences.user
        AND trades.block_date = firstUserOccurrences.firstTradeDate
    )
GROUP BY
    block_date
ORDER BY
    block_date DESC