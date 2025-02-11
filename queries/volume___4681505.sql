-- part of a query repo
-- query name: Volume
-- query link: https://dune.com/queries/4681505


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
    ),
    labeled_jettons as (
        SELECT
            jetton_master,
            label,
            block_time,
            rank() OVER (
                PARTITION BY
                    jetton_master, label
                ORDER BY
                    block_time
            ) AS rnk
        FROM
            (
                SELECT
                    block_time,
                    token_sold_address as jetton_master,
                    label
                FROM
                    labeled_trades
                WHERE
                    token_sold_address != '0:0000000000000000000000000000000000000000000000000000000000000000'
                UNION ALL
                SELECT
                    block_time,
                    token_bought_address as jetton_master,
                    label
                FROM
                    labeled_trades
                WHERE
                    token_bought_address != '0:0000000000000000000000000000000000000000000000000000000000000000'
            )
            -- GROUP BY
            --     1
    ),
    labeled_filtered_jettons AS (
        SELECT
            jetton_master,
            label,
            min(block_time) as first_trade_time
        FROM
            (
                SELECT
                    *
                FROM
                    labeled_jettons
                WHERE
                    rnk = 1
            )
        WHERE
            label in ('Blum', 'BlumMigratedToStonfi')
        GROUP BY
            1, 2
    ),
    labeled_filtered_trades AS (
        SELECT
            *
        FROM
            ton.dex_trades
        WHERE
            (
                (
                    token_sold_address in (
                        SELECT
                            jetton_master
                        FROM
                            labeled_filtered_jettons
                    )
                )
                OR (
                    token_bought_address in (
                        SELECT
                            jetton_master
                        FROM
                            labeled_filtered_jettons
                    )
                )
            )
            AND block_date >= (TIMESTAMP '2024-10-01')
    ),
    -- ,first_by_pair AS ( -- first time of trade for each pair
    --     SELECT
    --         token_sold_address,
    --         token_bought_address,
    --         CASE
    --             WHEN project_type = 'launchpad'
    --             AND referral_address = '0:C2705CA692BEEFA522895CC0522C3CA88C95D32298E427583E66319C211090EA' THEN 'Blum' -- this is trade from blum
    --             ELSE 'other'
    --         END AS label,
    --         MIN(block_time) as first_trade_time
    --     FROM
    --         labeled_filtered_trades_in_time_range trades
    --         -- LEFT JOIN
    --         --     labeled_filtered_jettons btoken on trades.token_bought_address = btoken.jetton_master
    --         -- LEFT JOIN
    --         --     labeled_filtered_jettons stoken on trades.token_sold_address = stoken.jetton_master
    --     GROUP BY
    --         1,
    --         2,
    --         3
    -- ),
    -- first_by_token AS (
    --     SELECT
    --         jetton_master,
    --         label,
    --         MIN(first_trade_time) as first_trade_time
    --     FROM
    --         (
    --             SELECT
    --                 first_trade_time,
    --                 token_sold_address as jetton_master,
    --                 label
    --             FROM
    --                 first_by_pair
    --             UNION ALL
    --             SELECT
    --                 first_trade_time,
    --                 token_bought_address as jetton_master,
    --                 label
    --             FROM
    --                 first_by_pair
    --         )
    --     WHERE
    --         jetton_master not in (
    --             '0:0000000000000000000000000000000000000000000000000000000000000000'
    --         )
    --     GROUP BY
    --         1,
    --         2
    -- ),
    stats_by_day as (
        SELECT
            DATE_TRUNC('day', block_time) as day,
            SUM(
                case
                    when (label = 'Blum') then volume_usd
                end
            ) AS blum,
            SUM(
                case
                    when (label = 'BlumMigratedToStonfi') then volume_usd
                end
            ) AS migrated
        FROM
            trades
        GROUP BY
            1
    )
SELECT
    day,
    blum,
    migrated,
    SUM(blum) OVER (
        ORDER BY
            day
    ) AS blum_total,
    SUM(migrated) OVER (
        ORDER BY
            day
    ) AS migrated_total
FROM
    stats_by_day
ORDER BY 
    1