# Performance Monitoring & Refinement

This guide outlines a lightweight workflow to measure, identify, and refine database performance using PostgreSQL tools.

## Tools
- EXPLAIN / EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
- Optional: pg_stat_statements for ongoing monitoring

## Frequently Used Queries (examples)
1) Recent bookings per user (feeds, dashboards)
```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT b.booking_id, b.created_at
FROM booking b
WHERE b.user_id = $1 AND b.deleted_at IS NULL
ORDER BY b.created_at DESC
LIMIT 10;
```

2) Property activity (counts of bookings)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.property_id, COUNT(b.booking_id) AS total
FROM property p
LEFT JOIN booking b
  ON b.property_id = p.property_id
  AND b.deleted_at IS NULL
  AND b.status IN ('confirmed','checked_in','completed')
WHERE p.deleted_at IS NULL
GROUP BY p.property_id
ORDER BY total DESC
LIMIT 20;
```

3) Bookings with user, property, latest payment (see `perfomance.sql`)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ... -- refactored query using LEFT JOIN LATERAL for latest payment
```

## How to Capture Baselines
- In psql, redirect output:
```sql
\o before_recent_bookings.txt
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) ...
\o
```
- Capture the same after changes as `after_*.txt` and compare:
  - Node types (Seq Scan vs Index Scan/Index Only Scan)
  - Sort vs no Sort (order satisfied by index)
  - Buffers: shared read/hit
  - Execution Time / Planning Time

## Bottlenecks Identified (typical)
- Sequential scans on large tables due to low selectivity or missing predicates
- Row multiplication from broad LEFT JOINs (e.g., multiple payments per booking)
- Costly global sorts without supporting indexes
- Scanning entire large tables for date-range queries

## Changes Applied (in this repo)
- Targeted indexes: `database-adv-script/database_index.sql`
  - booking: `(user_id, created_at DESC)`; `property_id` with active statuses; `(status, start_date, end_date)`
  - user: `(role, created_at DESC)` partial
  - property: `name` (active), `host_id,status` (active)
  - review: `(property_id, created_at DESC)` partial
  - payment: `(booking_id, payment_status)` partial
- Query refactor: `database-adv-script/perfomance.sql`
  - Use LEFT JOIN LATERAL to select the latest payment, avoiding row explosion
  - Add `deleted_at IS NULL` to leverage partial indexes
  - Narrow column selection and add pagination-friendly ORDER BY + LIMIT
- Partitioning by date: `database-adv-script/partitioning.sql`
  - Range partitions on `start_date` with automatic quarterly creation and data load
  - Enables partition pruning for date-range filters

## Example After Results (what to expect)
- Recent bookings query: Index Scan on `idx_booking_user_created_active` and no explicit Sort
- Property activity: fewer rows joined thanks to `idx_booking_property_active_status`
- Bookings with latest payment: fewer rows processed due to LATERAL limiting to 1 row per booking
- Date-window queries: partition pruning scans only relevant partitions

## Continuous Monitoring (optional but recommended)
Enable pg_stat_statements to find the slowest/highest-load queries over time:
```sql
-- postgresql.conf
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all

-- After restart
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 20;
```
Use the insights to prioritize indexing/refactors and re-run the EXPLAIN comparisons.

## Summary of Improvements
- Reduced execution time and I/O via index usage and pruning
- Smaller memory footprint by avoiding wide selects and unnecessary joins
- Predictable performance for date-range queries via partitioning

## References
- PostgreSQL EXPLAIN: https://www.postgresql.org/docs/current/sql-explain.html
- pg_stat_statements: https://www.postgresql.org/docs/current/pgstatstatements.html
- Indexes: https://www.postgresql.org/docs/current/indexes.html
