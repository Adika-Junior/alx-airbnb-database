-- ============================================================================
-- Indexes for Common Query Patterns (User, Booking, Property, Review, Payment)
-- Note: Some foundational indexes already exist in schema.sql. These additions
--       focus on composite/partial indexes aligned to frequent filters/sorts.
--       All use IF NOT EXISTS to avoid duplicates.
-- ============================================================================

-- =============================
-- USER
-- =============================
-- Typical filters: role, recency; avoid soft-deleted
CREATE INDEX IF NOT EXISTS idx_user_role_created_active
ON "user"(role, created_at DESC)
WHERE deleted_at IS NULL;

-- =============================
-- BOOKING
-- =============================
-- Recent bookings per user (e.g., ORDER BY created_at LIMIT ...)
CREATE INDEX IF NOT EXISTS idx_booking_user_created_active
ON booking(user_id, created_at DESC)
WHERE deleted_at IS NULL;

-- Property-centric analytics focused on active-ish statuses
CREATE INDEX IF NOT EXISTS idx_booking_property_active_status
ON booking(property_id)
WHERE deleted_at IS NULL
  AND status IN ('confirmed','checked_in','completed');

-- Speed up common status/date filtering combinations for reporting
CREATE INDEX IF NOT EXISTS idx_booking_status_dates
ON booking(status, start_date, end_date)
WHERE deleted_at IS NULL;

-- =============================
-- PROPERTY
-- =============================
-- Active property listing management by host
CREATE INDEX IF NOT EXISTS idx_property_host_status_active
ON property(host_id, status)
WHERE deleted_at IS NULL;

-- Sorting/browsing active properties by name
CREATE INDEX IF NOT EXISTS idx_property_name_active
ON property(name)
WHERE deleted_at IS NULL AND status = 'active';

-- Pricing filters on active properties
CREATE INDEX IF NOT EXISTS idx_property_price_active
ON property(price_per_night)
WHERE deleted_at IS NULL AND status = 'active';

-- =============================
-- REVIEW
-- =============================
-- Latest review per property and review feeds
CREATE INDEX IF NOT EXISTS idx_review_property_created_active
ON review(property_id, created_at DESC)
WHERE deleted_at IS NULL;

-- =============================
-- PAYMENT
-- =============================
-- Payment lookups per booking by status
CREATE INDEX IF NOT EXISTS idx_payment_booking_status_active
ON payment(booking_id, payment_status)
WHERE deleted_at IS NULL;

-- ============================================================================
-- End of index definitions
-- ============================================================================

-- ============================================================================
-- Measurement examples (run manually in psql) – BEFORE vs AFTER indexes
-- These are examples only and are commented out to avoid execution during index creation
-- Copy one, remove the dashes, and run it before and after applying indexes
-- ============================================================================

-- EXPLAIN ANALYZE SELECT b.booking_id, b.created_at
-- FROM booking b
-- WHERE b.user_id = '<some-uuid>' AND b.deleted_at IS NULL
-- ORDER BY b.created_at DESC
-- LIMIT 10;

-- EXPLAIN ANALYZE SELECT p.property_id, COUNT(b.booking_id) AS total
-- FROM property p
-- LEFT JOIN booking b
--   ON b.property_id = p.property_id
--   AND b.deleted_at IS NULL
--   AND b.status IN ('confirmed','checked_in','completed')
-- WHERE p.deleted_at IS NULL
-- GROUP BY p.property_id
-- ORDER BY total DESC
-- LIMIT 20;


