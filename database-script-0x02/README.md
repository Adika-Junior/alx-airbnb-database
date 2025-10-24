# AirBnB Clone - Sample Data Population Scripts

This folder contains SQL scripts to populate the AirBnB database with realistic test data.

## Usage

1. Prerequisites:
   - PostgreSQL 12 or higher
   - Base schema applied from `database-script-0x01/schema.sql`
   - Extensions: pgcrypto, cube, earthdistance

2. Run the seed script:
```bash
psql -d your_database -f seed.sql
```

## Sample Data Overview

The seed script populates:

1. Users
   - 5 hosts (various property specialties)
   - 5 guests (different travel preferences)

2. Locations
   - Urban (NY, SF, Chicago)
   - Beach (Miami, Malibu)
   - Mountain (Aspen, Park City)

3. Properties
   - 15 properties across locations
   - Varied types (apartments, houses, villas)
   - Realistic pricing and amenities

4. Bookings & Reviews
   - Various booking statuses
   - Partial/full payments
   - Reviews for completed stays

## Data Verification

Check data integrity:
```sql
-- Count active properties by city
SELECT l.city, COUNT(*)
FROM property p
JOIN location l ON p.location_id = l.location_id
WHERE p.deleted_at IS NULL
GROUP BY l.city;

-- Verify booking constraints
SELECT b.booking_id, p.name, b.start_date
FROM booking b
JOIN property p ON b.property_id = p.property_id
WHERE b.status = 'confirmed'
ORDER BY b.start_date;

-- Check review validity
SELECT r.rating, p.name, b.status
FROM review r
JOIN booking b ON r.booking_id = b.booking_id
JOIN property p ON r.property_id = p.property_id;
```

## Running the Scripts

1. Ensure you have the schema applied first:
```bash
psql -d your_db -f ../database-script-0x01/schema.sql
```

2. Run the seed script:
```bash
psql -d your_db -f seed.sql
```

## Data Relationships

The sample data demonstrates:

1. User relationships:
   - Hosts with multiple properties
   - Guests with multiple bookings
   - Reviews from real stays

2. Property features:
   - Different property types
   - Various amenity combinations
   - Dynamic pricing (via availability calendar)
   - Location diversity

3. Booking scenarios:
   - Confirmed bookings
   - Cancelled bookings
   - Partial/full payments
   - Reviews from completed stays

4. Business rules demonstrated:
   - No double-bookings
   - Pricing calculations
   - Review validation
   - Message threading

## Test Queries

Example queries to verify the loaded data:

```sql
-- Find all properties for a host
SELECT p.name, p.property_type, l.city
FROM property p
JOIN location l ON p.location_id = l.location_id
WHERE p.host_id = '[host_uuid]'
  AND p.deleted_at IS NULL;

-- Check booking history for a guest
SELECT b.booking_id, p.name, b.start_date, b.end_date, b.status
FROM booking b
JOIN property p ON b.property_id = p.property_id
WHERE b.user_id = '[guest_uuid]'
ORDER BY b.start_date DESC;

-- View payment status for a booking
SELECT p.payment_id, p.amount, p.payment_type, p.payment_status
FROM payment p
WHERE p.booking_id = '[booking_uuid]'
ORDER BY p.created_at;
```

## Cleanup

To reset the sample data:

```sql
-- WARNING: This will delete all sample data
DELETE FROM message;
DELETE FROM review;
DELETE FROM payment;
DELETE FROM booking;
DELETE FROM property_availability;
DELETE FROM property_amenity;
DELETE FROM property;
DELETE FROM location;
DELETE FROM "user";
```

## Next Steps

After loading the sample data, you can:

1. Run the provided test queries to verify relationships
2. Try creating new bookings to test overlap prevention
3. Add reviews to verify booking-review linkage
4. Test the availability calendar features

