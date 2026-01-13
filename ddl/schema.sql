--create table exchange
CREATE TABLE exchange (
    exchange_id SERIAL PRIMARY KEY,
    exchange_code VARCHAR(10) UNIQUE NOT NULL,
    exchange_name VARCHAR(50) NOT NULL
);
--Load data for Exchange
INSERT INTO exchange (exchange_code, exchange_name)
VALUES ('NSE', 'National Stock Exchange')
ON CONFLICT DO NOTHING;

--create table instrument
CREATE TABLE instrument (
    instrument_id SERIAL PRIMARY KEY,
    symbol VARCHAR(50) NOT NULL,
    instrument_type VARCHAR(10) CHECK (instrument_type IN ('FUT','OPT')),
    underlying VARCHAR(50),
    exchange_id INT REFERENCES exchange(exchange_id),
    UNIQUE(symbol, instrument_type, exchange_id)
);

--Load data for Instrument
INSERT INTO instrument (symbol, instrument_type, underlying, exchange_id)
SELECT DISTINCT
    symbol,
    CASE WHEN option_typ = 'XX' THEN 'FUT' ELSE 'OPT' END,
    instrument,
    e.exchange_id
FROM stg_fo_raw r
JOIN exchange e ON e.exchange_code = r.exchange
ON CONFLICT DO NOTHING;

--create table expiry
CREATE TABLE expiry (
    expiry_id SERIAL PRIMARY KEY,
    expiry_dt DATE NOT NULL,
    strike_pr NUMERIC(10,2),
    option_type VARCHAR(2)
);

--Load data for Expiry
INSERT INTO expiry (expiry_dt, strike_pr, option_type)
SELECT DISTINCT
    r.expiry_dt,
    r.strike_pr,
    NULLIF(r.option_typ, 'XX')
FROM stg_fo_raw r
WHERE r.expiry_dt IS NOT NULL
ON CONFLICT DO NOTHING;

--create table trade
CREATE TABLE trade (
    trade_id BIGSERIAL PRIMARY KEY,
    instrument_id INT REFERENCES instrument(instrument_id),
    expiry_id INT REFERENCES expiry(expiry_id),
    trade_date DATE,
    open_pr NUMERIC(10,2),
    high_pr NUMERIC(10,2),
    low_pr NUMERIC(10,2),
    close_pr NUMERIC(10,2),
    settle_pr NUMERIC(10,2),
    volume BIGINT,
    open_int BIGINT,
    timestamp TIMESTAMP
);

--Load data in trade
INSERT INTO trade (
    instrument_id,
    expiry_id,
    trade_date,
    open_pr,
    high_pr,
    low_pr,
    close_pr,
    settle_pr,
    volume,
    open_int,
    timestamp
)
SELECT
    i.instrument_id,
    e.expiry_id,
    r.timestamp,
    r.open,
    r.high,
    r.low,
    r.close,
    r.settle_pr,
    r.contracts,
    r.open_int,
    r.timestamp::timestamp
FROM stg_fo_raw r
JOIN instrument i ON i.symbol = r.symbol
JOIN expiry e
 ON e.expiry_dt = r.expiry_dt
AND e.strike_pr = r.strike_pr
AND COALESCE(e.option_type,'XX') = COALESCE(NULLIF(r.option_typ,'XX'),'XX');