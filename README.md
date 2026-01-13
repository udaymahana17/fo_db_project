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

Partitioned trades

BRIN indexes for time-series

Ready for intraday tick expansion
