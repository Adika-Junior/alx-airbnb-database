-- ============================================================================
-- Advanced JOIN Queries for AirBnB-like Schema
-- This file demonstrates INNER JOIN, LEFT JOIN, and FULL OUTER JOIN queries
-- using the normalized schema defined in database-script-0x01/schema.sql.
-- Tables used: "user", booking, property, review
-- ============================================================================

-- 1) INNER JOIN: Retrieve all bookings and the respective users who made them
--    Only bookings with a valid linked user will be returned.
SELECT
    b.booking_id,
    b.property_id,
    b.user_id,
    b.start_date,
    b.end_date,
    b.total_price,
    u.first_name,
    u.last_name,
    u.email
FROM booking AS b
INNER JOIN "user" AS u
  ON b.user_id = u.user_id
WHERE b.deleted_at IS NULL
  AND u.deleted_at IS NULL;

-- 2) LEFT JOIN: Retrieve all properties and their reviews, including properties
--    that have no reviews. When no review exists, review columns will be NULL.
SELECT
    p.property_id,
    p.name AS property_name,
    p.host_id,
    r.review_id,
    r.rating,
    r.comment,
    r.created_at AS review_created_at
FROM property AS p
LEFT JOIN review AS r
  ON r.property_id = p.property_id
  AND r.deleted_at IS NULL
WHERE p.deleted_at IS NULL
ORDER BY p.name ASC, r.created_at DESC NULLS LAST;

-- 3) FULL OUTER JOIN: Retrieve all users and all bookings, even if a user has
--    no booking or a booking is not linked to a user (defensive completeness).
--    This can surface data integrity issues where booking.user_id has no match.
SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    u.email,
    b.booking_id,
    b.property_id,
    b.start_date,
    b.end_date,
    b.total_price
FROM "user" AS u
FULL OUTER JOIN booking AS b
  ON b.user_id = u.user_id
WHERE (u.deleted_at IS NULL OR u.user_id IS NULL)
  AND (b.deleted_at IS NULL OR b.booking_id IS NULL);

-- End of JOIN queries


