# Advanced SQL – Joins, Aggregations, Indexing, Optimization & Partitioning

This module focuses on mastering SQL joins, analytical SQL (aggregations and window functions), indexing, query optimization, and partitioning across normalized Airbnb-like tables. Queries and scripts live under `database-adv-script/`, assuming the schema in `database-script-0x01/schema.sql` is applied and optionally populated via `database-script-0x02/seed.sql`.

## Objectives
- Understand and apply different join types: INNER, LEFT, FULL OUTER
- Retrieve cross-entity insights spanning `user`, `booking`, `property`, and `review`
- Practice production-aware filtering (e.g., excluding soft-deleted rows)
- Validate performance with `EXPLAIN` / `EXPLAIN ANALYZE`

## Prerequisites
- PostgreSQL with extensions used in the schema (pgcrypto, cube, earthdistance)
- Schema loaded: `psql -f database-script-0x01/schema.sql`
- Optional sample data: `psql -f database-script-0x02/seed.sql`
- Basic familiarity with SELECT, WHERE, GROUP BY, execution plans

## Files
- `database-adv-script/joins_queries.sql`: INNER, LEFT, FULL OUTER join queries
- `database-adv-script/aggregations_and_window_functions.sql`: Aggregations and ranking with window functions
- `database-adv-script/subqueries.sql`: Correlated and non-correlated subqueries (avg rating > 4.0; users with >3 bookings)
- `database-adv-script/database_index.sql`: Targeted CREATE INDEX statements
- `database-adv-script/index_performance.md`: How to measure before/after index performance
- `database-adv-script/perfomance.sql`: Initial vs refactored complex query (bookings + user + property + payment)
- `database-adv-script/optimization_report.md`: EXPLAIN analysis and refactor rationale
- `database-adv-script/partitioning.sql`: Range partitioning for bookings by start_date (dynamic quarterly)
- `database-adv-script/partition_performance.md`: Partition pruning performance tests
- `database-adv-script/performance_monitoring.md`: Ongoing monitoring workflow
- `database-script-0x01/schema.sql`: DDL for all tables and indexes
- `database-script-0x02/seed.sql`: Sample data

## Queries Included
1. INNER JOIN: Bookings with their users
   - Purpose: Show only bookings that have a valid user
   - Tables: `booking` ⋈ `user`
   - Output: booking details + user identity fields

2. LEFT JOIN: All properties and their reviews
   - Purpose: Include properties even when no reviews exist
   - Tables: `property` ⟕ `review`
   - Output: property info with nullable review fields

3. FULL OUTER JOIN: All users and all bookings
   - Purpose: Return unmatched rows from both sides (diagnostics/completeness)
   - Tables: `user` ⟗ `booking`
   - Output: user fields + booking fields; NULLs indicate no match

4. Aggregations & Window Functions
   - Aggregations: Total bookings per user using `COUNT(*)` + `GROUP BY`
   - Window ranking: Rank properties by total bookings using `RANK()` and `ROW_NUMBER()`
   - Tables: `user`, `booking`, `property`

See the exact SQL in the files listed above.

## How to Run
1) Load schema and (optionally) seed data as noted in Prerequisites.
2) Open a psql session connected to your database.
3) Execute from the repo root (`alx-airbnb-database`):
   - `\i database-adv-script/joins_queries.sql`
   - `\i database-adv-script/aggregations_and_window_functions.sql`
   - `\i database-adv-script/subqueries.sql`
   - `\i database-adv-script/database_index.sql`
   - `\i database-adv-script/perfomance.sql`
   - `\i database-adv-script/partitioning.sql`

Or copy/paste individual queries from the file. You can inspect plans via:
- `EXPLAIN` or `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` before each SELECT.

## Performance Notes
- Relevant indexes already exist in the schema (e.g., `booking(user_id)`, `review(property_id)`).
- WHERE clauses exclude soft-deleted rows to improve selectivity and plan quality.
- Use `EXPLAIN (ANALYZE)` to confirm hash/merge/nested loop choices and index usage.

## Learning Context
- Complex joins are part of broader skills: subqueries, aggregations, window functions, indexing, optimization, and partitioning for large tables.
- For a structured progression, tie these joins to analytics such as host performance, utilization, and guest behavior.

## References
- [PostgreSQL Joins (official docs)](https://www.postgresql.org/docs/current/queries-table-expressions.html)
- [EXPLAIN and query plans](https://www.postgresql.org/docs/current/sql-explain.html)
- [Indexes overview and usage](https://www.postgresql.org/docs/current/indexes.html)
- [Window functions](https://www.postgresql.org/docs/current/functions-window.html)
- [CTEs (WITH queries)](https://www.postgresql.org/docs/current/queries-with.html)
- [Use The Index, Luke! (practical indexing)](https://use-the-index-luke.com/)
- [Modern SQL (language features & best practices)](https://modern-sql.com/)
- [SQL Style Guide (readability)](https://www.sqlstyle.guide/)

### Top blogs & articles
- [pganalyze – Understanding EXPLAIN](https://pganalyze.com/docs/explain)
- [CYBERTEC – How to read EXPLAIN ANALYZE](https://www.cybertec-postgresql.com/en/how-to-read-explain-analyze-in-postgresql/)
- [Crunchy Data blog (PostgreSQL deep dives)](https://www.crunchydata.com/blog)
- [Citus Data – Fun with SQL: Window functions in Postgres](https://www.citusdata.com/blog/2018/06/01/fun-with-sql-window-functions-in-postgresql/)
- [Haki Benita – SQL window functions explained](https://hakibenita.com/sql-window-functions)
- [Percona blog – PostgreSQL performance](https://www.percona.com/blog/category/postgresql/)
- [Mode – SQL tutorial (joins & analytics)](https://mode.com/sql-tutorial/)


