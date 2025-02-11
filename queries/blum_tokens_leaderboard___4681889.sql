-- part of a query repo
-- query name: Blum Tokens Leaderboard
-- query link: https://dune.com/queries/4681889


WITH
    trades AS (
        SELECT
            block_time,
            block_date,
            volume_usd AS amount_usd,
            trades.version,
            trader_address AS tx_from,
            pool_address AS project_contract_address,
            token_bought_address,
            token_sold_address,
            amount_sold_raw,
            amount_bought_raw,
            tx_hash,
            case
                when ( -- on Blum
                    project_type = 'launchpad'
                    AND referral_address = '0:C2705CA692BEEFA522895CC0522C3CA88C95D32298E427583E66319C211090EA'
                ) then 'Blum'
                when ( -- Migrated
                    referral_address = '0:37BD8AC8CF61D228F0FDBAE7877F1348701D76B85B2D671BE43E4872603A1BE7'
                ) then 'BlumMigratedToStonfi'
                else 'other'
            end as label
        FROM
            ton.dex_trades AS trades
        WHERE
            ( -- on Blum
                project_type = 'launchpad'
                AND referral_address = '0:C2705CA692BEEFA522895CC0522C3CA88C95D32298E427583E66319C211090EA'
            )
            -- OR 
            -- ( -- Migrated
            --     referral_address = '0:37BD8AC8CF61D228F0FDBAE7877F1348701D76B85B2D671BE43E4872603A1BE7'
            -- )
    ),
    liquidity AS (
        SELECT
            *
        FROM
            query_4681803 -- Ston Pool Liquidity
    ),
    pairLeaderboard AS (
        SELECT
            RANK() OVER (
                ORDER BY
                    SUM(amount_usd) DESC
            ) AS pairRank,
            SUM(amount_usd) AS totalVolumeUSD,
            COUNT(DISTINCT (tx_hash)) AS numberOfTrades,
            COUNT(DISTINCT (tx_from)) AS numberOfUsers,
            -- MIN(trades.block_time) AS firstSwapTimestamp,
            -- MAX(trades.block_time) AS latestSwapTimestamp,
            -- version,
            MAX(
                1e0 * amount_usd / (
                    case
                        when token_sold_address = '0:0000000000000000000000000000000000000000000000000000000000000000' then amount_bought_raw
                        else amount_sold_raw
                    end
                ) * 1e18
            ) as max_cap,
            max_by(
                1e0 * amount_usd / (
                    case
                        when token_sold_address = '0:0000000000000000000000000000000000000000000000000000000000000000' then amount_bought_raw
                        else amount_sold_raw
                    end
                ) * 1e18,
                block_time
            ) as cur_cap,
            MIN(token_bought_address) as jetton_left_address,
            MAX(token_sold_address) as jetton_right_address,
            label,
            project_contract_address
        FROM
            trades
        GROUP BY
            -- version,
            label,
            project_contract_address
    ),
    jetton_metadata AS (
        SELECT
            address,
            symbol,
            decimals
        FROM
            query_4428187 -- Jetton Metadata
    )
SELECT
    pairRank,
    -- COALESCE(
    --     token_pair,
    --     SUBSTRING(CAST(project_contract_address AS VARCHAR), 1, 6)
    -- ) AS token_pair,
    get_href (
        'https://tonviewer.com/' || case
            when jetton_left_address = '0:0000000000000000000000000000000000000000000000000000000000000000' then jetton_right.address
            Else jetton_left.address
        end,
        case
            when jetton_left_address = '0:0000000000000000000000000000000000000000000000000000000000000000' then jetton_right.symbol
            Else jetton_left.symbol
        end
    ) as token,
    totalVolumeUSD,
    cur_cap,
    max_cap,
    numberOfTrades,
    numberOfUsers,
    label,
    project_contract_address
    -- CONCAT(
    --     '<a href="https://tonviewer.com/',
    --     CAST(project_contract_address AS VARCHAR),
    --     '" target=_blank">',
    --     CAST(project_contract_address AS VARCHAR),
    --     '</a>'
    -- ) AS project_contract_address_url
FROM
    pairLeaderboard
    -- LEFT JOIN liquidity ON project_contract_address = pool_address
    LEFT JOIN jetton_metadata AS jetton_left ON jetton_left_address = jetton_left.address
    LEFT JOIN jetton_metadata AS jetton_right ON jetton_right_address = jetton_right.address
ORDER BY
    totalVolumeUSD DESC
LIMIT
    1000