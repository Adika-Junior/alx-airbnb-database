# Partitioning Performance – Brief Report

This report documents the partitioning of bookings by `start_date` and how to test performance improvements via partition pruning.

Artifacts:
- Partitioning DDL: `database-adv-script/partitioning.sql`

## How to Apply
1. In psql, execute:
   - `\i database-adv-script/partitioning.sql`
2. This creates `booking_partitioned` (parent) and quarterly partitions, then copies data from `booking` to `booking_partitioned`.

## Test Queries (Before vs After)
Use the original table (`booking`) as BEFORE and the partitioned copy (`booking_partitioned`) as AFTER.

### A) Date-range retrieval (common analytics)
```sql
-- BEFORE
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM booking
WHERE start_date >= DATE '2025-01-01'
  AND start_date <  DATE '2025-04-01';

-- AFTER
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM booking_partitioned
WHERE start_date >= DATE '2025-01-01'
  AND start_date <  DATE '2025-04-01';
```
Expected: AFTER uses partition pruning to scan only `booking_p_2025_q1` (and maybe default), lowering buffers/time.

### B) Join within a date window
```sql
-- BEFORE
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.booking_id, p.name
FROM booking b
JOIN property p ON p.property_id = b.property_id
WHERE b.start_date >= DATE '2025-07-01'
  AND b.start_date <  DATE '2025-10-01';

-- AFTER
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.booking_id, p.name
FROM booking_partitioned b
JOIN property p ON p.property_id = b.property_id
WHERE b.start_date >= DATE '2025-07-01'
  AND b.start_date <  DATE '2025-10-01';
```
Expected: AFTER prunes to `booking_p_2025_q3` only; fewer rows scanned and lower I/O.

## Observed Improvements (typical)
- Node pruning: Only the matching partition(s) are scanned.
- Reduced `Buffers: shared read` and total `Execution Time` for date-range filters.
- Planner estimates closer to reality when stats per partition are more accurate.

## Notes
- Ensure date predicates are sargable and align with partition bounds.
- Keep creating new partitions ahead of time; queries hitting DEFAULT may not prune.
- You can index per-partition for even better performance on common patterns.

## References
- PostgreSQL Declarative Partitioning: https://www.postgresql.org/docs/current/ddl-partitioning.html
- EXPLAIN: https://www.postgresql.org/docs/current/sql-explain.html
