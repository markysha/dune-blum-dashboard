-- part of a query repo
-- query name: Activity By Weekday on Blum
-- query link: https://dune.com/queries/4682627


WITH
    tradesByDayOfWeek AS (
        SELECT
            date_trunc('day', block_time) AS block_date,
            day_of_week(block_time) as dayOfWeek,
            COUNT(DISTINCT (tx_hash)) AS numberOfTrades,
            SUM(volume_usd) as volumeUSD,
            COUNT(DISTINCT (trader_address)) as numberOfUsers
        FROM
            ton.dex_trades AS trades
        WHERE
            (
                referral_address = '0:C2705CA692BEEFA522895CC0522C3CA88C95D32298E427583E66319C211090EA' -- 'Blum'
                AND project_type = 'launchpad'
            )
        GROUP BY
            date_trunc('day', block_time),
            day_of_week(block_time)
        ORDER BY
            block_date ASC,
            dayOfWeek ASC,
            numberOfTrades ASC
    )
SELECT
    dayOfWeek,
    CASE
        WHEN dayOfWeek = 1 THEN '1 Mon'
        WHEN dayOfWeek = 2 THEN '2 Tue'
        WHEN dayOfWeek = 3 THEN '3 Wed'
        WHEN dayOfWeek = 4 THEN '4 Thu'
        WHEN dayOfWeek = 5 THEN '5 Fri'
        WHEN dayOfWeek = 6 THEN '6 Sat'
        WHEN dayOfWeek = 7 THEN '7 Sun'
    END as weekday,
    FLOOR(AVG(numberOfTrades)) as averageNumberOfTrades,
    APPROX_PERCENTILE(numberOfTrades, 0.5) as medianNumberOfTrades,
    FLOOR(AVG(volumeUSD)) as averageVolumeUSD,
    APPROX_PERCENTILE(volumeUSD, 0.5) as medianVolumeUSD,
    FLOOR(AVG(numberOfUsers)) as averageNumberOfUsers,
    APPROX_PERCENTILE(numberOfUsers, 0.5) as medianNumberOfUsers
FROM
    tradesByDayOfWeek
GROUP BY
    dayOfWeek
ORDER BY
    dayOfWeek ASC