# Index Performance – Measurement Guide

This guide explains how to measure query performance before and after applying indexes from `database-adv-script/database_index.sql` using PostgreSQL EXPLAIN and EXPLAIN (ANALYZE).

## Prerequisites
- Schema loaded: `database-script-0x01/schema.sql`
- Optional seed data: `database-script-0x02/seed.sql`
- Index script: `database-adv-script/database_index.sql`

## How to Measure
1. Open psql connected to your database.
2. Run each target query with `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` and save the output (BEFORE).
3. Apply indexes: `\i database-adv-script/database_index.sql`.
4. Run the same queries again and save the output (AFTER).
5. Compare: node types (Seq Scan vs Index Scan), total cost, actual time, rows, buffers.

## Target Queries

### 1) Recent bookings per user
```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT b.booking_id, b.created_at
FROM booking b
WHERE b.user_id = $1
  AND b.deleted_at IS NULL
ORDER BY b.created_at DESC
LIMIT 10;
```
Expected improvement: Use of `idx_booking_user_created_active` for an index scan with ordering satisfied by the index.

### 2) Property analytics (active statuses)
```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
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
Expected improvement: Fewer rows joined thanks to `idx_booking_property_active_status`.

### 3) Active properties sorted by name
```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT p.property_id, p.name
FROM property p
WHERE p.deleted_at IS NULL
  AND p.status = 'active'
ORDER BY p.name ASC
LIMIT 50;
```
Expected improvement: `idx_property_name_active` yields ordered index scan and can avoid explicit sort.

### 4) Latest review per property
```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT r.*
FROM review r
WHERE r.property_id = $1
  AND r.deleted_at IS NULL
ORDER BY r.created_at DESC
LIMIT 1;
```
Expected improvement: `idx_review_property_created_active` enables quick retrieval of newest review.

### 5) Payments by booking and status
```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT pmt.payment_id
FROM payment pmt
WHERE pmt.booking_id = $1
  AND pmt.deleted_at IS NULL
  AND pmt.payment_status = 'completed';
```
Expected improvement: `idx_payment_booking_status_active` provides selective index scan.

## Capturing Results
- `\o before_recent_bookings.txt` to capture BEFORE; `\o` to reset.
- `\o after_recent_bookings.txt` to capture AFTER.
- Compare: `Planning Time`, `Execution Time`, `Buffers: shared hit/read`, node types.

## Notes
- On very small tables, Seq Scan may be chosen; improvements are more visible with larger datasets.
- Update stats after bulk changes: `VACUUM (ANALYZE);`.
- Avoid over-indexing; indexes add write overhead and storage.

## References
- PostgreSQL EXPLAIN: https://www.postgresql.org/docs/current/sql-explain.html
- PostgreSQL Indexes: https://www.postgresql.org/docs/current/indexes.html
- Use The Index, Luke!: https://use-the-index-luke.com/
