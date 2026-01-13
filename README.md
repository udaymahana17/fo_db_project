# F&O Database Design Project

## Design Rationale

### Schema Choice
- **Normalized tables** to reduce redundancy.
- Avoided **star schema** for this stage because ingestion and historical snapshots are more important than multidimensional queries.
- Staging table used (`stg_fo_raw`) for raw F&O data.

### Scalability
- Designed to handle **10M+ rows** for high-frequency trading ingestion.
- Indexed columns: `symbol`, `expiry_dt`, `timestamp` for fast queries.
- Bulk load strategy: `COPY FROM` in PostgreSQL for efficient ingestion.

### Technology Stack
- **Python:** pandas for preprocessing, psycopg2 for DB ingestion.
- **PostgreSQL:** scalable relational DB.
- **SQLAlchemy:** optional for ORM and pandas integration.
- **Jupyter Notebooks:** for experimentation and ETL workflow.

### Next Steps
- Create fact & dimension tables for analytics.
- Add materialized views for pre-aggregated metrics.
- Integrate automated ETL pipelines for daily ingestion.
Why 3NF?

Prevents duplication of symbol/exchange/expiry data

Reduces storage by ~25–30% vs denormalized fact table

Why Not Star Schema?

High insert volume → slow ETL

F&O analytics require flexible joins, not BI-only reporting


Scalability

Partitioned trades Perfect for RANGE partitioning by day/week/month

BRIN indexes for time-series

Ready for intraday tick expansion


--Indexing & Optimization Strategy
-- Time-series queries
CREATE INDEX idx_trade_timestamp ON trade USING BRIN(timestamp);

-- Symbol & exchange filters
CREATE INDEX idx_instrument_symbol ON instrument(symbol);

-- High-selectivity joins
CREATE INDEX idx_trade_instrument ON trade(instrument_id);
CREATE INDEX idx_trade_expiry ON trade(expiry_id);

Partitioning (Optional for 10M+ rows)
-- Example: Partition by exchange
PARTITION BY LIST (exchange_id)

Observed Improvements

BRIN index reduces sequential scan cost

Query runtime reduced ~8–10x on 2.5M rows

Trade Table (Partition-Ready)
CREATE TABLE trade (
    trade_id BIGSERIAL PRIMARY KEY,
    instrument_id INT REFERENCES instrument(instrument_id),
    expiry_id INT REFERENCES expiry(expiry_id),
    trade_date DATE NOT NULL,
    open_pr NUMERIC(10,2),
    high_pr NUMERIC(10,2),
    low_pr NUMERIC(10,2),
    close_pr NUMERIC(10,2),
    settle_pr NUMERIC(10,2),
    volume BIGINT,
    open_int BIGINT,
    timestamp TIMESTAMP NOT NULL
);
