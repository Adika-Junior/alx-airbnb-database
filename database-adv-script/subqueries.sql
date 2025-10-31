-- ============================================================================
-- Subqueries – Non-Correlated and Correlated Examples
-- Tables used: property, review, booking, "user"
-- ==========================================================================

-- 1) Non-correlated subquery: Properties with avg rating > 4.0
--    Computes average from review table; filters properties by that average.
SELECT
    p.property_id,
    p.name AS property_name,
    avg_r.avg_rating,
    avg_r.review_count
FROM property AS p
JOIN (
    SELECT
        r.property_id,
        AVG(r.rating)::numeric(3,2) AS avg_rating,
        COUNT(*) AS review_count
    FROM review AS r
    WHERE r.deleted_at IS NULL
    GROUP BY r.property_id
) AS avg_r
  ON avg_r.property_id = p.property_id
WHERE p.deleted_at IS NULL
  AND avg_r.avg_rating > 4.0
ORDER BY avg_r.avg_rating DESC, avg_r.review_count DESC, p.name ASC;

-- 2) Correlated subquery: Users who have made more than 3 bookings
--    Counts bookings per user in a subquery referencing outer user row.
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    (
        SELECT COUNT(*)
        FROM booking AS b
        WHERE b.user_id = u.user_id
          AND b.deleted_at IS NULL
    ) AS total_bookings
FROM "user" AS u
WHERE u.deleted_at IS NULL
  AND (
        SELECT COUNT(*)
        FROM booking AS b
        WHERE b.user_id = u.user_id
          AND b.deleted_at IS NULL
      ) > 3
ORDER BY total_bookings DESC, u.email ASC;

-- End of subqueries


