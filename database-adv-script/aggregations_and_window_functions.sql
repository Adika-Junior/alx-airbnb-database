-- ============================================================================
-- Aggregations & Window Functions – Airbnb-like Schema
-- Queries demonstrate GROUP BY aggregations and window functions for ranking
-- Tables used: "user", booking, property
-- ============================================================================

-- 1) Total number of bookings made by each user
--    Includes users with zero bookings via LEFT JOIN; excludes soft-deleted rows
SELECT
    u.user_id,
    u.email,
    COALESCE(COUNT(b.booking_id), 0) AS total_bookings
FROM "user" AS u
LEFT JOIN booking AS b
  ON b.user_id = u.user_id
  AND b.deleted_at IS NULL
WHERE u.deleted_at IS NULL
GROUP BY u.user_id, u.email
ORDER BY total_bookings DESC, u.email ASC;

-- 2) Rank properties by total bookings using window functions
--    Produces both RANK() and ROW_NUMBER() for comparison
WITH property_booking_counts AS (
    SELECT
        p.property_id,
        p.name AS property_name,
        COALESCE(COUNT(b.booking_id), 0) AS total_bookings
    FROM property AS p
    LEFT JOIN booking AS b
      ON b.property_id = p.property_id
      AND b.deleted_at IS NULL
    WHERE p.deleted_at IS NULL
    GROUP BY p.property_id, p.name
)
SELECT
    property_id,
    property_name,
    total_bookings,
    RANK() OVER (ORDER BY total_bookings DESC, property_name ASC)          AS booking_rank,
    ROW_NUMBER() OVER (ORDER BY total_bookings DESC, property_name ASC)    AS booking_row_number
FROM property_booking_counts
ORDER BY total_bookings DESC, property_name ASC;

-- End of aggregations and window function queries


