-- ============================================================================
-- ENHANCED AIRBNB DATABASE SCHEMA
-- Version: 2.0
-- Normalized to 3NF with modern best practices (2024-2025)
-- ============================================================================

-- NOTE: This file was extracted from ERD/normalization.md. It contains the
-- full SQL DDL, indexes, triggers, functions and sample data used by the
-- enhanced AirBnB schema design.

-- Enable UUID generation and required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "cube";
CREATE EXTENSION IF NOT EXISTS "earthdistance";

-- ============================================================================
-- 1. USER TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS "user" (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    phone_number TEXT,
    role TEXT CHECK (role IN ('guest','host','admin')) NOT NULL DEFAULT 'guest',
    is_verified BOOLEAN DEFAULT false,
    profile_image_url TEXT,
    preferred_language VARCHAR(10) DEFAULT 'en',
    preferred_currency VARCHAR(3) DEFAULT 'USD',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- ============================================================================
-- 2. LOCATION TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS location (
    location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- ============================================================================
-- 3. PROPERTY TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS property (
    property_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
    location_id UUID NOT NULL REFERENCES location(location_id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    property_type VARCHAR(50) NOT NULL CHECK (property_type IN (
        'apartment', 'house', 'villa', 'cabin', 'hotel_room', 'other'
    )),
    price_per_night NUMERIC(10,2) NOT NULL CHECK (price_per_night > 0),
    max_guests INTEGER NOT NULL CHECK (max_guests > 0),
    num_bedrooms INTEGER NOT NULL CHECK (num_bedrooms >= 0),
    num_bathrooms DECIMAL(3,1) NOT NULL CHECK (num_bathrooms > 0),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN (
        'draft', 'pending_approval', 'active', 'inactive', 'suspended'
    )),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_by UUID REFERENCES "user"(user_id),
    updated_by UUID REFERENCES "user"(user_id)
);

-- ============================================================================
-- 4. PROPERTY AVAILABILITY TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS property_availability (
    availability_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES property(property_id) ON DELETE CASCADE,
    available_date DATE NOT NULL,
    is_available BOOLEAN DEFAULT true,
    price_override NUMERIC(10,2) CHECK (price_override IS NULL OR price_override > 0),
    min_nights INTEGER CHECK (min_nights IS NULL OR min_nights > 0),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(property_id, available_date)
);

-- ============================================================================
-- 5. AMENITY TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS amenity (
    amenity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN (
        'basic', 'safety', 'entertainment', 'kitchen', 'outdoor', 'accessibility'
    )),
    icon VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS property_amenity (
    property_id UUID REFERENCES property(property_id) ON DELETE CASCADE,
    amenity_id UUID REFERENCES amenity(amenity_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    PRIMARY KEY (property_id, amenity_id)
);

-- ============================================================================
-- 6. BOOKING TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS booking (
    booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES property(property_id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    num_guests INTEGER NOT NULL CHECK (num_guests > 0),
    total_price NUMERIC(10,2) NOT NULL CHECK (total_price > 0),
    status TEXT CHECK (status IN (
        'pending', 'confirmed', 'checked_in', 'checked_out', 
        'completed', 'canceled', 'refunded'
    )) NOT NULL DEFAULT 'pending',
    special_requests TEXT,
    checked_in_at TIMESTAMPTZ,
    checked_out_at TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT valid_date_range CHECK (end_date > start_date),
    CONSTRAINT valid_checkin CHECK (
        checked_in_at IS NULL OR checked_in_at >= start_date::timestamptz
    ),
    CONSTRAINT valid_checkout CHECK (
        checked_out_at IS NULL OR checked_out_at <= (end_date::timestamptz + interval '1 day')
    )
);

-- ============================================================================
-- 7. PAYMENT TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS payment (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES booking(booking_id) ON DELETE RESTRICT,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN (
        'deposit', 'full_payment', 'partial_payment', 'refund'
    )),
    payment_method TEXT CHECK (payment_method IN (
        'credit_card', 'debit_card', 'paypal', 'stripe', 'bank_transfer'
    )) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN (
        'pending', 'processing', 'completed', 'failed', 'refunded'
    )),
    transaction_id TEXT,
    payment_processor_response JSONB,
    paid_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- 8. REVIEW TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS review (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES property(property_id) ON DELETE CASCADE,
    booking_id UUID UNIQUE NOT NULL REFERENCES booking(booking_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
    rating SMALLINT CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    rating_cleanliness SMALLINT CHECK (rating_cleanliness >= 1 AND rating_cleanliness <= 5),
    rating_accuracy SMALLINT CHECK (rating_accuracy >= 1 AND rating_accuracy <= 5),
    rating_checkin SMALLINT CHECK (rating_checkin >= 1 AND rating_checkin <= 5),
    rating_communication SMALLINT CHECK (rating_communication >= 1 AND rating_communication <= 5),
    rating_location SMALLINT CHECK (rating_location >= 1 AND rating_location <= 5),
    rating_value SMALLINT CHECK (rating_value >= 1 AND rating_value <= 5),
    comment TEXT,
    host_response TEXT,
    host_responded_at TIMESTAMPTZ,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- 9. MESSAGE TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS message (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES booking(booking_id) ON DELETE SET NULL,
    sender_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
    message_type VARCHAR(20) CHECK (message_type IN (
        'inquiry', 'booking_related', 'support', 'general'
    )) DEFAULT 'general',
    message_body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT different_users CHECK (sender_id != recipient_id)
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_email ON "user"(email) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_user_role ON "user"(role) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_location_city ON location(city, country);
CREATE INDEX IF NOT EXISTS idx_location_coords ON location USING GIST(
    ll_to_earth(latitude, longitude)
) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_property_host ON property(host_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_property_location ON property(location_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_property_status ON property(status) WHERE deleted_at IS NULL AND status = 'active';
CREATE INDEX IF NOT EXISTS idx_property_price ON property(price_per_night) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_availability_property_date ON property_availability(property_id, available_date);
CREATE INDEX IF NOT EXISTS idx_availability_date_range ON property_availability(available_date)
    WHERE is_available = true;

CREATE INDEX IF NOT EXISTS idx_property_amenity_property ON property_amenity(property_id);
CREATE INDEX IF NOT EXISTS idx_property_amenity_amenity ON property_amenity(amenity_id);

CREATE INDEX IF NOT EXISTS idx_booking_property ON booking(property_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_booking_user ON booking(user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_booking_dates ON booking(start_date, end_date) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_booking_status ON booking(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_booking_created ON booking(created_at DESC) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_no_double_booking ON booking(property_id, start_date, end_date)
    WHERE status IN ('confirmed', 'checked_in') AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_payment_booking ON payment(booking_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_payment_status ON payment(payment_status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_payment_transaction ON payment(transaction_id) WHERE transaction_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_review_property ON review(property_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_review_user ON review(user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_review_rating ON review(rating) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_review_created ON review(created_at DESC) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_message_sender ON message(sender_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_message_recipient ON message(recipient_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_message_booking ON message(booking_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_message_unread ON message(recipient_id, is_read)
    WHERE deleted_at IS NULL AND is_read = false;
CREATE INDEX IF NOT EXISTS idx_message_conversation ON message(sender_id, recipient_id, sent_at DESC)
    WHERE deleted_at IS NULL;

-- ============================================================================
-- TRIGGERS FOR AUTOMATIC TIMESTAMP UPDATES
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'user') THEN
        EXECUTE 'CREATE TRIGGER IF NOT EXISTS update_user_timestamp BEFORE UPDATE ON "user" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'location') THEN
        EXECUTE 'CREATE TRIGGER IF NOT EXISTS update_location_timestamp BEFORE UPDATE ON location FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'property') THEN
        EXECUTE 'CREATE TRIGGER IF NOT EXISTS update_property_timestamp BEFORE UPDATE ON property FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'property_availability') THEN
        EXECUTE 'CREATE TRIGGER IF NOT EXISTS update_property_availability_timestamp BEFORE UPDATE ON property_availability FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'booking') THEN
        EXECUTE 'CREATE TRIGGER IF NOT EXISTS update_booking_timestamp BEFORE UPDATE ON booking FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'payment') THEN
        EXECUTE 'CREATE TRIGGER IF NOT EXISTS update_payment_timestamp BEFORE UPDATE ON payment FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'review') THEN
        EXECUTE 'CREATE TRIGGER IF NOT EXISTS update_review_timestamp BEFORE UPDATE ON review FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();';
    END IF;
END$$;

-- ============================================================================
-- VIEWS, FUNCTIONS AND SAMPLE DATA
-- (These are included for convenience; adapt names/permissions to your app)
-- ============================================================================

CREATE OR REPLACE VIEW v_active_properties AS
SELECT 
    p.property_id,
    p.name,
    p.description,
    p.property_type,
    p.price_per_night,
    p.max_guests,
    p.num_bedrooms,
    p.num_bathrooms,
    u.user_id as host_id,
    u.first_name || ' ' || u.last_name as host_name,
    u.is_verified as host_verified,
    l.city,
    l.state_province,
    l.country,
    l.latitude,
    l.longitude,
    COALESCE(AVG(r.rating), 0) as avg_rating,
    COUNT(DISTINCT r.review_id) as review_count,
    p.created_at
FROM property p
JOIN "user" u ON p.host_id = u.user_id
JOIN location l ON p.location_id = l.location_id
LEFT JOIN review r ON p.property_id = r.property_id AND r.deleted_at IS NULL
WHERE p.deleted_at IS NULL 
    AND p.status = 'active'
    AND u.deleted_at IS NULL
GROUP BY p.property_id, u.user_id, u.first_name, u.last_name, u.is_verified,
                 l.city, l.state_province, l.country, l.latitude, l.longitude;

CREATE OR REPLACE FUNCTION check_property_availability(
    p_property_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_conflict BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM booking
        WHERE property_id = p_property_id
            AND deleted_at IS NULL
            AND status IN ('confirmed', 'checked_in')
            AND (
                (start_date <= p_start_date AND end_date > p_start_date)
                OR (start_date < p_end_date AND end_date >= p_end_date)
                OR (start_date >= p_start_date AND end_date <= p_end_date)
            )
    ) INTO v_has_conflict;
  
    RETURN NOT v_has_conflict;
END;
$$ LANGUAGE plpgsql;

INSERT INTO amenity (name, category, icon) VALUES
    ('WiFi', 'basic', 'wifi'),
    ('Air Conditioning', 'basic', 'ac_unit'),
    ('Heating', 'basic', 'heat'),
    ('Kitchen', 'kitchen', 'kitchen'),
    ('Washer', 'basic', 'local_laundry_service'),
    ('Dryer', 'basic', 'local_laundry_service'),
    ('TV', 'entertainment', 'tv'),
    ('Pool', 'outdoor', 'pool'),
    ('Hot Tub', 'outdoor', 'hot_tub'),
    ('Parking', 'basic', 'local_parking'),
    ('Smoke Alarm', 'safety', 'smoke_detector'),
    ('Carbon Monoxide Alarm', 'safety', 'co2'),
    ('Fire Extinguisher', 'safety', 'fire_extinguisher'),
    ('First Aid Kit', 'safety', 'medical_services'),
    ('Wheelchair Accessible', 'accessibility', 'accessible'),
    ('Elevator', 'accessibility', 'elevator'),
    ('Gym', 'entertainment', 'fitness_center'),
    ('Workspace', 'basic', 'desk'),
    ('Pet Friendly', 'basic', 'pets'),
    ('BBQ Grill', 'outdoor', 'outdoor_grill')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- END OF SCHEMA DEFINITION
-- ============================================================================
