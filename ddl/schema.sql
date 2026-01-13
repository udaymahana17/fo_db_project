--create table exchange
CREATE TABLE exchange (
    EXCHANGE_ID SERIAL PRIMARY KEY,
    EXCHANGE_CODE VARCHAR(10) UNIQUE NOT NULL,
    EXCHANGE_NAME VARCHAR(50) NOT NULL
);

--Load data for exchange
INSERT INTO exchange (EXCHANGE_CODE, EXCHANGE_NAME)
VALUES ('NSE', 'National Stock Exchange')
ON CONFLICT DO NOTHING;


--create table instrument
CREATE TABLE instrument (
    INSTRUMENT_ID SERIAL PRIMARY KEY,
    SYMBOL VARCHAR(50) NOT NULL,
    INSTRUMENT_TYPE VARCHAR(10) CHECK (INSTRUMENT_TYPE IN ('FUT','OPT')),
    UNDERLYING VARCHAR(50),
    EXCHANGE_ID INT REFERENCES exchange(EXCHANGE_ID),
    UNIQUE (SYMBOL, INSTRUMENT_TYPE, EXCHANGE_ID)
);


--Load data for Instrument
INSERT INTO instrument (
    SYMBOL,
    INSTRUMENT_TYPE,
    UNDERLYING,
    EXCHANGE_ID
)
SELECT DISTINCT
    r."SYMBOL",
    CASE WHEN r."OPTION_TYP" = 'XX' THEN 'FUT' ELSE 'OPT' END,
    r."INSTRUMENT",
    e.EXCHANGE_ID
FROM stg_fo_raw r
JOIN exchange e
  ON e.EXCHANGE_CODE = r."EXCHANGE"
ON CONFLICT DO NOTHING;
                       

--create table expiry
CREATE TABLE expiry (
    EXPIRY_ID SERIAL PRIMARY KEY,
    EXPIRY_DT DATE NOT NULL,
    STRIKE_PR NUMERIC(10,2),
    OPTION_TYPE VARCHAR(2)
);


--Load data for Expiry
INSERT INTO expiry (EXPIRY_DT, STRIKE_PR, OPTION_TYPE)
SELECT DISTINCT
    COALESCE(
        "EXPIRY_DT"::date,                         
        '2026-01-31'::date
    ),
    "STRIKE_PR"::numeric(10,2),
    UPPER("OPTION_TYP")
FROM stg_fo_raw
WHERE "EXPIRY_DT" IS NOT NULL
  AND "STRIKE_PR" IS NOT NULL
  AND UPPER("OPTION_TYP") IN ('CE', 'PE');
    


--create table trade
CREATE TABLE trade (
    TRADE_ID BIGSERIAL PRIMARY KEY,
    INSTRUMENT_ID INT REFERENCES instrument(INSTRUMENT_ID),
    EXPIRY_ID INT REFERENCES expiry(EXPIRY_ID),
    TRADE_DATE DATE,
    OPEN_PR NUMERIC(10,2),
    HIGH_PR NUMERIC(10,2),
    LOW_PR NUMERIC(10,2),
    CLOSE_PR NUMERIC(10,2),
    SETTLE_PR NUMERIC(10,2),
    VOLUME BIGINT,
    OPEN_INT BIGINT,
    TIMESTAMP TIMESTAMP
);


--Load data in trade
INSERT INTO trade (
    INSTRUMENT_ID,
    EXPIRY_ID,
    TRADE_DATE,
    OPEN_PR,
    HIGH_PR,
    LOW_PR,
    CLOSE_PR,
    SETTLE_PR,
    VOLUME,
    OPEN_INT,
    TIMESTAMP
)
SELECT
    i.INSTRUMENT_ID,
    e.EXPIRY_ID,
    r."TIMESTAMP"::timestamp::date,              -- VARCHAR → TIMESTAMP → DATE
    r."OPEN",
    r."HIGH",
    r."LOW",
    r."CLOSE",
    r."SETTLE_PR",
    r."CONTRACTS",
    r."OPEN_INT",
    r."TIMESTAMP"::timestamp                     
FROM stg_fo_raw r
JOIN instrument i ON i.SYMBOL = r."SYMBOL"
JOIN expiry e ON e.EXPIRY_DT = r."EXPIRY_DT"::timestamp::date  
           AND e.STRIKE_PR = r."STRIKE_PR"
           AND COALESCE(e.OPTION_TYPE, 'XX') = COALESCE(NULLIF(r."OPTION_TYP", 'XX'), 'XX');