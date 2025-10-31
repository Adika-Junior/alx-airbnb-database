# Query Optimization Report – Bookings with User, Property, Payment

Files:
- Initial and refactored queries: `database-adv-script/perfomance.sql`
- Supporting indexes: `database-adv-script/database_index.sql`

## 1) Initial Query Summary
- Joins: `booking` ⋈ `user` ⋈ `property` ⟕ `payment`
- Characteristics:
  - No soft-delete filters, leading to low selectivity and potential seq scans.
  - LEFT JOIN to `payment` causes row multiplication for bookings with multiple payments.
  - Selects numerous columns; less cache-friendly and more I/O.
  - Global ORDER BY on `b.created_at` with no LIMIT in baseline example can be expensive.

### Expected EXPLAIN (high level)
- Hash Join or Merge Join between large relations.
- Seq Scan on `payment` or `booking` if stats suggest it, due to low selectivity.
- Sort step on `b.created_at` for global ordering.

## 2) Identified Inefficiencies
- Row explosion: Multiple `payment` rows per booking.
- Missing selective predicates: Not filtering `deleted_at` misses partial indexes.
- Wide select list: Unnecessary columns increase row size.
- Unbounded result set: Sorting all rows is costly.

## 3) Refactor Strategy and Query Changes
- Use LEFT JOIN LATERAL to select a single most relevant payment per booking (latest by `paid_at`).
- Add `deleted_at IS NULL` filters on `booking`, `user`, `property`, and inside the `payment` lateral subquery to leverage partial indexes.
- Limit columns to those needed.
- Add `ORDER BY b.created_at DESC` with `LIMIT` for pagination.

Key snippet (see full SQL in `perfomance.sql`):
```sql
LEFT JOIN LATERAL (
  SELECT pay.payment_id, pay.payment_status, pay.amount, pay.paid_at
  FROM payment AS pay
  WHERE pay.booking_id = b.booking_id
    AND pay.deleted_at IS NULL
  ORDER BY pay.paid_at DESC NULLS LAST
  LIMIT 1
) AS lp ON TRUE
```

## 4) Indexes Utilized
- `idx_booking_user_created_active` on `(user_id, created_at DESC)` WHERE `deleted_at IS NULL` – speeds recent bookings per user and ordering.
- `idx_booking_property_active_status` on `property_id` WHERE status in active-ish states – reduces joined rows in analytics.
- `idx_booking_status_dates` for status/date filters in reporting.
- `idx_property_name_active` for ordered scans over active properties.
- `idx_payment_booking_status_active` on `(booking_id, payment_status)` WHERE `deleted_at IS NULL` – speeds payment lookups.

## 5) Measuring Improvements
Commands to compare plans:
```sql
-- BEFORE
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT ... -- initial query from perfomance.sql

-- Apply indexes
\i database-adv-script/database_index.sql

-- AFTER (initial)
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT ... -- initial query again

-- AFTER (refactored)
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT ... -- refactored query from perfomance.sql
```
Compare:
- Node types: prefer Index Scan / Index Only Scan over Seq Scan.
- Removed Sorts due to index order.
- Lower `Execution Time`, fewer `shared read` buffers, lower row counts in joins.

## 6) Expected Outcomes
- Dramatically fewer rows joined from `payment` (1 row per booking via LATERAL).
- Better selectivity and index usage from `deleted_at IS NULL` predicates.
- Reduced sort cost when ordering aligns with composite indexes.
- Lower memory usage and I/O from a narrower select list and pagination.

## 7) Notes and Alternatives
- If business logic needs total paid rather than latest payment, pre-aggregate payments in a CTE and join that summary.
- On small datasets, planner may still choose Seq Scans; improvements are more visible with larger tables.
- Keep `VACUUM (ANALYZE)` current after bulk loads for accurate stats.

## References
- PostgreSQL EXPLAIN: https://www.postgresql.org/docs/current/sql-explain.html
- PostgreSQL Indexes: https://www.postgresql.org/docs/current/indexes.html
- Use The Index, Luke!: https://use-the-index-luke.com/
