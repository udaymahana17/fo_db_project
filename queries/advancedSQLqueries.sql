--1 Top 10 Symbols by Open Interest Change
WITH oi_change AS (
    SELECT
        i.symbol,
        e.exchange_code,
        MAX(t.open_int) - MIN(t.open_int) AS oi_diff
    FROM trade t
    JOIN instrument i ON t.instrument_id = i.instrument_id
    JOIN exchange e ON i.exchange_id = e.exchange_id
    GROUP BY i.symbol, e.exchange_code
)
SELECT *
FROM oi_change
ORDER BY oi_diff DESC
LIMIT 10;

-- 2  7-Day Rolling Volatility (NIFTY Options)
SELECT
    t.trade_date,
    i.symbol,
    STDDEV(t.close_pr) OVER (
        PARTITION BY i.symbol
        ORDER BY t.trade_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_volatility
FROM trade t
JOIN instrument i ON t.instrument_id = i.instrument_id
WHERE i.symbol = 'NIFTY'
  AND i.instrument_type = 'OPT';
  
-- 3  Cross-Exchange Comparison
--    Gold Futures (MCX) vs Index Futures (NSE)

SELECT
    e.exchange_code,
    AVG(t.settle_pr) AS avg_settle_price
FROM trade t
JOIN instrument i ON t.instrument_id = i.instrument_id
JOIN exchange e ON i.exchange_id = e.exchange_id
WHERE
    (e.exchange_code = 'MCX' AND i.symbol = 'GOLD')
    OR
    (e.exchange_code = 'NSE' AND i.instrument_type = 'FUT')
GROUP BY e.exchange_code;

-- 4 Option Chain Summary (Expiry + Strike)

SELECT
    ex.expiry_dt,
    ex.strike_pr,
    ex.option_type,
    SUM(t.volume) AS implied_volume
FROM trade t
JOIN expiry ex ON t.expiry_id = ex.expiry_id
GROUP BY ex.expiry_dt, ex.strike_pr, ex.option_type
ORDER BY ex.expiry_dt, ex.strike_pr;

-- 5 Max Volume in Last 30 Days (Optimized)
SELECT
    i.symbol,
    MAX(t.volume) AS max_volume
FROM trade t
JOIN instrument i ON t.instrument_id = i.instrument_id
WHERE t.trade_date >= CURRENT_DATE - INTERVAL '5000 days'
GROUP BY i.symbol;



-- Performance Proof (EXPLAIN ANALYZE)
EXPLAIN ANALYZE
SELECT
    MAX(volume)
FROM trade
WHERE trade_date >= CURRENT_DATE - INTERVAL '30 days';