-- ============================================================================
-- Range Partitioning for Booking by start_date (Non-disruptive rollout)
-- Strategy: Create a partitioned table copy `booking_partitioned` and partitions
--           by quarter. Migrate data for evaluation without breaking FKs.
--           Keep original `booking` for application continuity.
-- Requirements: PostgreSQL 11+
-- ============================================================================

BEGIN;

-- 1) Create partitioned parent table mirroring `booking`
CREATE TABLE IF NOT EXISTS booking_partitioned (
    LIKE booking INCLUDING DEFAULTS INCLUDING CONSTRAINTS INCLUDING INDEXES
)
PARTITION BY RANGE (start_date);

-- 2) Create quarterly partitions dynamically for the year range in data
DO $$
DECLARE
    min_d date;
    max_d date;
    start_year int;
    end_year int;
    y int;
    q int;
    q_start date;
    q_end date;
    part_name text;
BEGIN
    SELECT COALESCE(min(start_date), date_trunc('year', current_date)::date),
           COALESCE(max(start_date), date_trunc('year', current_date)::date)
    INTO min_d, max_d
    FROM booking;

    start_year := EXTRACT(YEAR FROM min_d)::int;
    -- add a buffer year ahead of max for future inserts
    end_year := GREATEST(EXTRACT(YEAR FROM max_d)::int, EXTRACT(YEAR FROM current_date)::int) + 1;

    FOR y IN start_year..end_year LOOP
        FOR q IN 1..4 LOOP
            CASE q
                WHEN 1 THEN q_start := make_date(y, 1, 1);   q_end := make_date(y, 4, 1);
                WHEN 2 THEN q_start := make_date(y, 4, 1);   q_end := make_date(y, 7, 1);
                WHEN 3 THEN q_start := make_date(y, 7, 1);   q_end := make_date(y, 10, 1);
                WHEN 4 THEN q_start := make_date(y, 10, 1);  q_end := make_date(y + 1, 1, 1);
            END CASE;

            part_name := format('booking_p_%s_q%s', y, q);
            EXECUTE format(
                'CREATE TABLE IF NOT EXISTS %I PARTITION OF booking_partitioned FOR VALUES FROM (%L) TO (%L);',
                part_name, q_start, q_end
            );
        END LOOP;
    END LOOP;

    -- Default partition to catch any out-of-range rows
    EXECUTE 'CREATE TABLE IF NOT EXISTS booking_p_default PARTITION OF booking_partitioned DEFAULT';
END$$;

-- 3) Notes on indexes: indexes on parent are created on partitions automatically
--    because parent was created WITH INCLUDING INDEXES; create extra ones if needed.

-- 4) Load existing data for evaluation (can be batched)
INSERT INTO booking_partitioned
SELECT * FROM booking
ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================================================
-- Usage notes
-- - For evaluation, point reporting/analytics queries at booking_partitioned
-- - To fully switch over, plan a maintenance window to:
--     a) stop writes; b) ensure parity; c) rename tables; d) update FKs/views
-- - Create future partitions ahead of time (e.g., via a scheduled job)
-- ============================================================================


