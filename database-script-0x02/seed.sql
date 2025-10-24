-- AirBnB Clone Database - Sample Data Population
-- Prerequisites: Execute database-script-0x01/schema.sql first

BEGIN;

-- Enable required extensions (will error if not available)
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- For UUID generation
CREATE EXTENSION IF NOT EXISTS cube;      -- For geo-search support
CREATE EXTENSION IF NOT EXISTS earthdistance;  -- For location-based queries

-- Clean existing data (if any) in correct dependency order
TRUNCATE TABLE 
    message,            -- Start with child tables
    review,
    payment,
    booking,
    property_availability,
    property_amenity,
    amenity,
    property,
    location,
    "user"             -- End with parent tables
CASCADE;

-- Create sample users (both hosts and guests)
WITH inserted_users AS (
    INSERT INTO "user" (user_id, email, full_name, phone, bio, created_at) VALUES
    -- Hosts
    (gen_random_uuid(), 'host1@example.com', 'Sarah Johnson', '+1234567890', 'Experienced host with luxury properties', now()),
    (gen_random_uuid(), 'host2@example.com', 'Michael Chen', '+1234567891', 'Specializing in urban apartments', now()),
    (gen_random_uuid(), 'host3@example.com', 'Emma Davis', '+1234567892', 'Beachfront property expert', now()),
    (gen_random_uuid(), 'host4@example.com', 'James Wilson', '+1234567893', 'Mountain cabin host', now()),
    (gen_random_uuid(), 'host5@example.com', 'Maria Garcia', '+1234567894', 'Historic property specialist', now()),
    -- Guests
    (gen_random_uuid(), 'guest1@example.com', 'John Smith', '+1234567895', 'Love to travel!', now()),
    (gen_random_uuid(), 'guest2@example.com', 'Lisa Brown', '+1234567896', 'Business traveler', now()),
    (gen_random_uuid(), 'guest3@example.com', 'David Lee', '+1234567897', 'Adventure seeker', now()),
    (gen_random_uuid(), 'guest4@example.com', 'Sophie Martin', '+1234567898', 'Family vacation expert', now()),
    (gen_random_uuid(), 'guest5@example.com', 'Alex Taylor', '+1234567899', 'Digital nomad', now())
    RETURNING user_id, email
)
SELECT user_id, email FROM inserted_users;

-- Create sample locations
WITH inserted_locations AS (
    INSERT INTO location (location_id, street_address, city, state, postal_code, country, latitude, longitude) VALUES
    -- Urban locations
    (gen_random_uuid(), '123 Downtown Ave', 'New York', 'NY', '10001', 'USA', 40.7128, -74.0060),
    (gen_random_uuid(), '456 Marina Blvd', 'San Francisco', 'CA', '94123', 'USA', 37.7749, -122.4194),
    (gen_random_uuid(), '789 Lake Shore Dr', 'Chicago', 'IL', '60601', 'USA', 41.8781, -87.6298),
    -- Beach locations
    (gen_random_uuid(), '321 Ocean Drive', 'Miami Beach', 'FL', '33139', 'USA', 25.7617, -80.1918),
    (gen_random_uuid(), '654 Coastal Hwy', 'Malibu', 'CA', '90265', 'USA', 34.0259, -118.7798),
    -- Mountain locations
    (gen_random_uuid(), '987 Pine Ridge Rd', 'Aspen', 'CO', '81611', 'USA', 39.1911, -106.8175),
    (gen_random_uuid(), '741 Summit Way', 'Park City', 'UT', '84060', 'USA', 40.6461, -111.4980)
    RETURNING location_id, city
)
SELECT location_id, city FROM inserted_locations;

-- Create amenities
WITH inserted_amenities AS (
    INSERT INTO amenity (amenity_id, name, category) VALUES
    -- Basic amenities
    (gen_random_uuid(), 'WiFi', 'basic'),
    (gen_random_uuid(), 'Air conditioning', 'basic'),
    (gen_random_uuid(), 'Heating', 'basic'),
    (gen_random_uuid(), 'Washer', 'basic'),
    (gen_random_uuid(), 'Dryer', 'basic'),
    -- Kitchen amenities
    (gen_random_uuid(), 'Full kitchen', 'kitchen'),
    (gen_random_uuid(), 'Refrigerator', 'kitchen'),
    (gen_random_uuid(), 'Dishwasher', 'kitchen'),
    (gen_random_uuid(), 'Coffee maker', 'kitchen'),
    -- Entertainment
    (gen_random_uuid(), 'TV', 'entertainment'),
    (gen_random_uuid(), 'Pool table', 'entertainment'),
    (gen_random_uuid(), 'Sound system', 'entertainment'),
    -- Outdoor
    (gen_random_uuid(), 'Pool', 'outdoor'),
    (gen_random_uuid(), 'Hot tub', 'outdoor'),
    (gen_random_uuid(), 'BBQ grill', 'outdoor'),
    (gen_random_uuid(), 'Fire pit', 'outdoor'),
    -- Safety
    (gen_random_uuid(), 'Smoke alarm', 'safety'),
    (gen_random_uuid(), 'First aid kit', 'safety'),
    (gen_random_uuid(), 'Fire extinguisher', 'safety'),
    -- Accessibility
    (gen_random_uuid(), 'Elevator', 'accessibility'),
    (gen_random_uuid(), 'Step-free access', 'accessibility'),
    (gen_random_uuid(), 'Wide doorways', 'accessibility')
    RETURNING amenity_id, name
)
SELECT amenity_id, name FROM inserted_amenities;

-- Create properties (using the IDs from users[hosts] and locations)
-- Note: Replace UUIDs with actual values from above inserts in practice
WITH host_ids AS (
    SELECT user_id FROM "user" WHERE email LIKE 'host%@example.com'
),
location_ids AS (
    SELECT location_id FROM location
),
inserted_properties AS (
    INSERT INTO property (
        property_id, host_id, location_id, name, description, property_type,
        price_per_night, max_guests, num_bedrooms, num_bathrooms, status
    )
    SELECT
        gen_random_uuid(),
        host_id,
        location_id,
        'Property ' || row_number() over() || ' - ' || l.city,
        'Beautiful property in ' || l.city,
        (ARRAY['apartment', 'house', 'villa', 'cabin', 'hotel_room'])[floor(random() * 5 + 1)],
        (random() * 300 + 100)::numeric(10,2),
        floor(random() * 8 + 2),
        floor(random() * 4 + 1),
        floor(random() * 3 + 1)::numeric(3,1),
        'active'
    FROM host_ids h
    CROSS JOIN location_ids l
    LIMIT 15
    RETURNING property_id, name
)
SELECT property_id, name FROM inserted_properties;

-- Create property amenities (link properties with random amenities)
INSERT INTO property_amenity (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM property p
CROSS JOIN amenity a
WHERE random() < 0.7;  -- 70% chance of each amenity being added

-- Create availability calendar (90 days from today)
INSERT INTO property_availability (
    availability_id, property_id, available_date, 
    is_available, price_override, min_nights
)
SELECT
    gen_random_uuid(),
    p.property_id,
    current_date + i,
    true,
    CASE 
        WHEN EXTRACT(DOW FROM current_date + i) IN (5,6) THEN p.price_per_night * 1.2  -- Weekend premium
        ELSE p.price_per_night
    END,
    CASE WHEN random() < 0.2 THEN floor(random() * 3 + 2) ELSE NULL END  -- 20% chance of min nights requirement
FROM property p
CROSS JOIN generate_series(0, 89) i;

-- Create realistic bookings with proper date ranges and pricing
WITH guest_ids AS (
    SELECT user_id FROM "user" WHERE email LIKE 'guest%@example.com'
),
booking_dates AS (
    -- Generate realistic date ranges that respect availability and min_nights
    SELECT 
        p.property_id,
        p.price_per_night,
        p.max_guests,
        pa.available_date as start_date,
        LEAST(
            pa.available_date + COALESCE(pa.min_nights, 2) + floor(random() * 5)::integer,
            current_date + 89
        ) as end_date
    FROM property p
    JOIN property_availability pa ON p.property_id = pa.property_id
    WHERE 
        pa.is_available = true
        AND pa.available_date >= current_date
        AND pa.available_date <= current_date + 60  -- Book within next 60 days
),
inserted_bookings AS (
    INSERT INTO booking (
        booking_id, property_id, user_id, start_date, end_date,
        num_guests, total_price, status, special_requests
    )
    SELECT
        gen_random_uuid(),
        bd.property_id,
        g.user_id,
        bd.start_date,
        bd.end_date,
        -- Realistic guest counts (usually not at max capacity)
        GREATEST(1, floor(random() * (bd.max_guests - 1) + 1)),
        -- Calculate total price using actual available dates
        (
            SELECT SUM(COALESCE(pa.price_override, bd.price_per_night))
            FROM generate_series(bd.start_date, bd.end_date - 1) d
            LEFT JOIN property_availability pa ON 
                pa.property_id = bd.property_id AND pa.available_date = d
        ),
        (ARRAY['confirmed', 'completed', 'canceled'])[
            CASE 
                WHEN bd.start_date < current_date THEN 2  -- Past bookings are completed
                WHEN random() < 0.1 THEN 3  -- 10% canceled
                ELSE 1  -- Rest are confirmed
            END
        ],
        CASE 
            WHEN random() < 0.3 THEN 
                CASE floor(random() * 3)::integer
                    WHEN 0 THEN 'Early check-in requested'
                    WHEN 1 THEN 'Late check-out if possible'
                    ELSE 'Special dietary requirements'
                END
            ELSE NULL 
        END
    FROM booking_dates bd
    CROSS JOIN guest_ids g
    WHERE random() < 0.3  -- Create bookings for ~30% of available dates
    RETURNING booking_id, property_id, user_id, total_price
)
SELECT booking_id, total_price FROM inserted_bookings;

    -- Create payments for confirmed/completed bookings with proper transaction tracking
INSERT INTO payment (
    payment_id, booking_id, amount, payment_type,
    payment_method, payment_status, transaction_id,
    payment_processor_response
)
WITH booking_payments AS (
    -- First, calculate how many payments each booking needs
    SELECT 
        b.booking_id,
        b.total_price,
        CASE 
            WHEN random() < 0.7 THEN 1  -- 70% single full payment
            ELSE 2  -- 30% split into deposit + final payment
        END as num_payments
    FROM booking b
    WHERE b.status IN ('confirmed', 'completed')
)
SELECT
    gen_random_uuid(),
    bp.booking_id,
    CASE 
        WHEN bp.num_payments = 1 THEN bp.total_price
        WHEN payment_num = 1 THEN (bp.total_price * 0.3)::numeric(10,2)  -- 30% deposit
        ELSE (bp.total_price * 0.7)::numeric(10,2)  -- 70% final payment
    END as amount,
    CASE 
        WHEN bp.num_payments = 1 THEN 'full_payment'
        WHEN payment_num = 1 THEN 'deposit'
        ELSE 'final_payment'
    END as payment_type,
    -- Use consistent payment method per booking
    (ARRAY['credit_card', 'paypal', 'bank_transfer'])[1 + mod(abs(('x' || substr(bp.booking_id::text, 1, 8))::bit(32)::int), 3)] as payment_method,
    'completed' as payment_status,
    -- Generate deterministic but unique transaction IDs
    'TXN-' || substr(bp.booking_id::text, 1, 8) || '-' || payment_num as transaction_id,
    jsonb_build_object(
        'processor_id', 'PROC-' || substr(bp.booking_id::text, 1, 8) || '-' || payment_num,
        'timestamp', now(),
        'status', 'success',
        'payment_num', payment_num,
        'total_payments', bp.num_payments
    ) as payment_processor_response
FROM booking_payments bp
CROSS JOIN generate_series(1, 2) payment_num
WHERE 
    -- Include all single payments and both payments for split payments
    (bp.num_payments = 1 AND payment_num = 1) OR
    (bp.num_payments = 2 AND payment_num <= 2);-- Create reviews for completed bookings
INSERT INTO review (
    review_id, property_id, booking_id, user_id,
    rating, rating_cleanliness, rating_accuracy, rating_communication,
    rating_location, rating_value, comment
)
SELECT
    gen_random_uuid(),
    b.property_id,
    b.booking_id,
    b.user_id,
    floor(random() * 3 + 3),  -- Ratings between 3-5
    floor(random() * 3 + 3),
    floor(random() * 3 + 3),
    floor(random() * 3 + 3),
    floor(random() * 3 + 3),
    floor(random() * 3 + 3),
    'Review for stay - ' || now()::text
FROM booking b
WHERE b.status = 'completed'
AND random() < 0.8;  -- 80% of completed bookings get reviews

-- Create sample messages
INSERT INTO message (
    message_id, sender_id, recipient_id, booking_id,
    message_body, is_read
)
SELECT
    gen_random_uuid(),
    CASE WHEN random() < 0.5 THEN b.user_id ELSE p.host_id END,
    CASE WHEN random() < 0.5 THEN p.host_id ELSE b.user_id END,
    b.booking_id,
    'Sample message ' || row_number() over() || ' regarding booking',
    random() < 0.7  -- 70% read messages
FROM booking b
JOIN property p ON b.property_id = p.property_id
WHERE random() < 0.5;  -- Create messages for 50% of bookings

-- End of seed data script