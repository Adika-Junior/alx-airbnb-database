-- ============================================================================
-- Performance Exercise: Complex Query and Refactor
-- Schema tables used: booking, "user", property, payment
-- ============================================================================

-- --------------------------------------------------------------------------
-- Initial Query (baseline)
-- Retrieves all bookings with user, property, and payment details
-- Note: This will duplicate booking rows when multiple payments exist
-- --------------------------------------------------------------------------
SELECT
    b.booking_id,
    b.property_id,
    b.user_id,
    b.start_date,
    b.end_date,
    b.status AS booking_status,
    b.total_price,
    u.first_name,
    u.last_name,
    u.email,
    p.name AS property_name,
    p.price_per_night,
    pay.payment_id,
    pay.payment_status,
    pay.amount,
    pay.paid_at
FROM booking AS b
JOIN "user" AS u ON u.user_id = b.user_id
JOIN property AS p ON p.property_id = b.property_id
LEFT JOIN payment AS pay ON pay.booking_id = b.booking_id
-- Intentionally no soft-delete filters and broad join to show baseline
ORDER BY b.created_at DESC;

-- Suggested plan inspection:
-- EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
-- [paste the query above]

-- --------------------------------------------------------------------------
-- Refactored Query (optimized)
-- Goals:
-- 1) Avoid row explosion from multiple payments by selecting the latest
--    completed (or most recent) payment via LATERAL subquery
-- 2) Apply soft-delete filters to leverage partial indexes
-- 3) Select only necessary columns (no SELECT *)
-- 4) Provide pagination-friendly ORDER BY and LIMIT
-- --------------------------------------------------------------------------
SELECT
    b.booking_id,
    b.property_id,
    b.user_id,
    b.start_date,
    b.end_date,
    b.status AS booking_status,
    b.total_price,
    u.first_name,
    u.last_name,
    u.email,
    p.name AS property_name,
    p.price_per_night,
    lp.payment_id AS latest_payment_id,
    lp.payment_status AS latest_payment_status,
    lp.amount AS latest_payment_amount,
    lp.paid_at AS latest_payment_at
FROM booking AS b
JOIN "user" AS u
  ON u.user_id = b.user_id
JOIN property AS p
  ON p.property_id = b.property_id
LEFT JOIN LATERAL (
    SELECT pay.payment_id, pay.payment_status, pay.amount, pay.paid_at
    FROM payment AS pay
    WHERE pay.booking_id = b.booking_id
      AND pay.deleted_at IS NULL
    ORDER BY pay.paid_at DESC NULLS LAST
    LIMIT 1
) AS lp ON TRUE
WHERE b.deleted_at IS NULL
  AND u.deleted_at IS NULL
  AND p.deleted_at IS NULL
ORDER BY b.created_at DESC
LIMIT 200; -- tune as appropriate for pagination

-- Suggested plan inspection:
-- EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
-- [paste the refactored query above]

-- Indexes expected to help (see database_index.sql and schema.sql):
-- - booking(user_id, created_at DESC) WHERE deleted_at IS NULL
-- - booking(property_id) WHERE deleted_at IS NULL AND status IN (...)
-- - user(role, created_at DESC) WHERE deleted_at IS NULL
-- - property(name) WHERE deleted_at IS NULL AND status = 'active'
-- - payment(booking_id, payment_status) WHERE deleted_at IS NULL
-- - review(property_id, created_at DESC) WHERE deleted_at IS NULL (for review-related variants)

-- Alternate pattern: Pre-aggregate payments if total paid is desired
-- WITH payments_summary AS (
--   SELECT booking_id,
--          SUM(amount) FILTER (WHERE payment_status = 'completed') AS total_completed_paid,
--          MAX(paid_at) AS latest_paid_at
--   FROM payment
--   WHERE deleted_at IS NULL
--   GROUP BY booking_id
-- )
-- SELECT ...
-- LEFT JOIN payments_summary ps ON ps.booking_id = b.booking_id

-- ============================================================================
-- End of file
-- ============================================================================


