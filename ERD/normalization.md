
Database Normalization Analysis - AirBnB Clone
Table of Contents

Current Entity Analysis
Normalization Theory
Per-Entity Normalization Analysis
Normalization Output
Final Normalized Entities


Current Entity Analysis
1. User Entity
Current Structure:
user_id, email, full_name, phone, created_at
```

**Attributes:**
- `user_id` - Primary identifier
- `email` - Contact and login credential
- `full_name` - User's complete name
- `phone` - Contact number
- `created_at` - Registration timestamp

**Issues Identified:**
- `full_name` is not atomic (violates 1NF) - contains first and last name
- No distinction between different user types (guest, host, admin)
- Missing audit trail for updates
- No support for soft deletion
- Limited user profile information

---

### 2. Property Entity
**Current Structure:**
```
property_id, host_id, name, description, location, 
price_per_night, created_at
```

**Attributes:**
- `property_id` - Primary identifier
- `host_id` - Foreign key to user
- `name` - Property title
- `description` - Property details
- `location` - Address information
- `price_per_night` - Daily rental price
- `created_at` - Listing creation timestamp

**Issues Identified:**
- `location` contains composite address data (violates 1NF)
- Location data creates transitive dependency (violates 3NF)
- No property type categorization
- Missing capacity and room information
- No status tracking for listing approval
- No update timestamp

---

### 3. Booking Entity
**Current Structure:**
```
booking_id, property_id, user_id, start_date, end_date, 
total_price, status
```

**Attributes:**
- `booking_id` - Primary identifier
- `property_id` - Foreign key to property
- `user_id` - Foreign key to guest
- `start_date` - Check-in date
- `end_date` - Check-out date
- `total_price` - Total booking cost
- `status` - Booking state

**Issues Identified:**
- Limited status values
- No tracking of guest count
- Missing check-in/check-out timestamps
- No cancellation metadata
- No audit trail
- No special requests field

---

### 4. Payment Entity
**Current Structure:**
```
payment_id, booking_id, amount, payment_date, payment_method
```

**Attributes:**
- `payment_id` - Primary identifier
- `booking_id` - Foreign key to booking (UNIQUE)
- `amount` - Payment amount
- `payment_date` - Transaction date
- `payment_method` - Payment type

**Issues Identified:**
- UNIQUE constraint on `booking_id` prevents partial payments
- No payment status tracking
- No external transaction reference
- No support for refunds
- Missing payment processor metadata

---

### 5. Review Entity
**Current Structure:**
```
review_id, property_id, user_id, rating, comment, created_at
```

**Attributes:**
- `review_id` - Primary identifier
- `property_id` - Foreign key to property
- `user_id` - Foreign key to reviewer
- `rating` - Overall rating score
- `comment` - Review text
- `created_at` - Review timestamp

**Issues Identified:**
- No verification that user actually stayed at property
- Single rating dimension (not detailed enough)
- No host response capability
- No helpful vote tracking
- Missing update timestamp

---

### 6. Message Entity
**Current Structure:**
```
message_id, sender_id, recipient_id, message_body, sent_at
```

**Attributes:**
- `message_id` - Primary identifier
- `sender_id` - Foreign key to sender
- `recipient_id` - Foreign key to recipient
- `message_body` - Message content
- `sent_at` - Send timestamp

**Issues Identified:**
- No booking context linkage
- No read status tracking
- No message type distinction
- Missing soft delete support

---

## Normalization Theory

### What is Database Normalization?

Database normalization is a systematic process of organizing data in a database to reduce redundancy and improve data integrity. It involves decomposing tables into smaller, well-structured tables and defining relationships between them according to specific rules called normal forms.

### Why Normalize?

1. **Eliminate Data Redundancy**: Reduce duplicate data storage
2. **Ensure Data Integrity**: Maintain consistency and accuracy
3. **Simplify Queries**: Make data retrieval more efficient
4. **Facilitate Maintenance**: Easier updates and modifications
5. **Optimize Storage**: Reduce database size

### Normal Forms Overview

#### First Normal Form (1NF)
**Definition**: A table is in 1NF if:
- All columns contain atomic (indivisible) values
- Each column contains values of a single type
- Each column has a unique name
- The order of rows and columns doesn't matter

**Example Violation**:
```
full_name: "John Doe" ❌ (contains first and last name)
location: "123 Main St, New York, NY 10001" ❌ (contains multiple address components)
```

**Corrected**:
```
first_name: "John" ✓
last_name: "Doe" ✓

street: "123 Main St" ✓
city: "New York" ✓
state: "NY" ✓
postal_code: "10001" ✓
```

---

#### Second Normal Form (2NF)
**Definition**: A table is in 2NF if:
- It is in 1NF
- All non-key attributes are fully functionally dependent on the entire primary key
- No partial dependencies exist (relevant for composite keys)

**Example Violation**:
```
Table: PropertyAmenity(property_id, amenity_name, amenity_category)
Primary Key: (property_id, amenity_name)

Issue: amenity_category depends only on amenity_name, not the full key
```

**Corrected**:
```
Table: Amenity(amenity_id, amenity_name, amenity_category)
Table: PropertyAmenity(property_id, amenity_id)
```

---

#### Third Normal Form (3NF)
**Definition**: A table is in 3NF if:
- It is in 2NF
- No transitive dependencies exist
- All non-key attributes depend directly on the primary key

**Example Violation**:
```
Table: Property(property_id, host_id, city, state, country)

Issue: country depends on state, state depends on city (transitive dependency)
```

**Corrected**:
```
Table: Property(property_id, host_id, location_id)
Table: Location(location_id, city, state, country)
```

---

### Normalization Process

1. **Identify Entities**: Determine distinct objects/concepts
2. **Define Attributes**: List all properties for each entity
3. **Apply 1NF**: Make all attributes atomic
4. **Apply 2NF**: Remove partial dependencies
5. **Apply 3NF**: Remove transitive dependencies
6. **Define Relationships**: Establish foreign keys and cardinalities

---

## Per-Entity Normalization Analysis

### 1. User Entity Normalization

#### Current State (Unnormalized)
```
user(user_id, email, full_name, phone, created_at)
```

#### 1NF Analysis
**Violation**: `full_name` contains multiple atomic values (first name + last name)

**Solution**: Split into atomic components
```
user(user_id, email, first_name, last_name, phone, created_at)
```

#### 2NF Analysis
**Status**: ✓ All non-key attributes fully depend on `user_id` (single-column PK)
- No composite key, so no partial dependencies possible

#### 3NF Analysis
**Status**: ✓ No transitive dependencies detected
- `email`, `first_name`, `last_name`, `phone` all directly depend on `user_id`

#### Additional Enhancements
While not strictly part of normalization, these improvements support data integrity:
- Add `role` to distinguish user types (guest/host/admin)
- Add `updated_at` for audit trail
- Add `deleted_at` for soft deletion
- Add `password_hash` for authentication
- Add profile fields (`profile_image_url`, `preferred_language`, `preferred_currency`)
- Add `is_verified` for account verification

#### Normalized Output
```
user(
	user_id [PK],
	first_name,
	last_name,
	email [UNIQUE],
	password_hash,
	phone_number,
	role,
	is_verified,
	profile_image_url,
	preferred_language,
	preferred_currency,
	created_at,
	updated_at,
	deleted_at
)
```

---

### 2. Property Entity Normalization

#### Current State (Unnormalized)
```
property(property_id, host_id, name, description, location, price_per_night, created_at)
```

#### 1NF Analysis
**Violation**: `location` contains composite data (street, city, state, country, postal code)

**Solution**: Extract location components
```
property(
	property_id, host_id, name, description, 
	street, city, state, country, postal_code,
	price_per_night, created_at
)
```

#### 2NF Analysis
**Status**: ✓ No composite key, all attributes depend on `property_id`

#### 3NF Analysis
**Violation**: Transitive dependency detected
- `country` depends on `state`
- `state` depends on `city`
- These location attributes depend on each other, not directly on `property_id`

**Solution**: Extract location to separate entity
```
location(location_id [PK], street, city, state, country, postal_code, latitude, longitude)
property(property_id [PK], host_id [FK], location_id [FK], name, description, price_per_night)
```

#### Additional Enhancements
- Add `property_type` for categorization
- Add capacity fields (`max_guests`, `num_bedrooms`, `num_bathrooms`)
- Add `status` for approval workflow
- Add audit fields (`updated_at`, `deleted_at`, `created_by`, `updated_by`)

#### Normalized Outputs
```
location(
	location_id [PK],
	country,
	state_province,
	city,
	postal_code,
	address_line1,
	address_line2,
	latitude,
	longitude,
	created_at,
	updated_at
)

property(
	property_id [PK],
	host_id [FK → user],
	location_id [FK → location],
	name,
	description,
	property_type,
	price_per_night,
	max_guests,
	num_bedrooms,
	num_bathrooms,
	status,
	created_at,
	updated_at,
	deleted_at,
	created_by [FK → user],
	updated_by [FK → user]
)
```

---

### 3. Property Amenities Normalization

#### Current State
**Missing Entity**: Amenities are not represented in the original schema

#### Analysis
Properties have multiple amenities (WiFi, Kitchen, Pool, etc.), and the same amenity applies to multiple properties. This is a many-to-many relationship requiring normalization.

#### 1NF Analysis
If amenities were stored as a comma-separated list:
```
property(property_id, amenities: "WiFi,Kitchen,Pool") ❌ Violates 1NF (not atomic)
```

#### 2NF & 3NF Analysis
**Solution**: Create normalized many-to-many relationship
- Amenity attributes (name, category) depend on `amenity_id`, not `property_id`
- Requires junction table to eliminate partial dependencies

#### Normalized Outputs
```
amenity(
	amenity_id [PK],
	name [UNIQUE],
	category,
	icon,
	created_at
)

property_amenity(
	property_id [PK, FK → property],
	amenity_id [PK, FK → amenity],
	created_at
)
```

---

### 4. Property Availability Normalization

#### Current State
**Missing Entity**: Availability and dynamic pricing not represented

#### Analysis
Properties need per-date availability tracking and price overrides for weekends/holidays. This requires a separate entity to avoid data redundancy and support fine-grained control.

#### Normalization Rationale
- Each property has availability status for each date
- Price can vary by date (overriding base price)
- Minimum night requirements can vary by date
- Composite natural key: (property_id, available_date)

#### Normalized Output
```
property_availability(
	availability_id [PK],
	property_id [FK → property],
	available_date [DATE],
	is_available,
	price_override,
	min_nights,
	created_at,
	updated_at,
	UNIQUE(property_id, available_date)
)
```

---

### 5. Booking Entity Normalization

#### Current State (Unnormalized)
```
booking(booking_id, property_id, user_id, start_date, end_date, total_price, status)
```

#### 1NF Analysis
**Status**: ✓ All attributes are atomic

#### 2NF Analysis
**Status**: ✓ No composite key; all attributes depend on `booking_id`

#### 3NF Analysis
**Status**: ✓ No transitive dependencies
- All attributes directly relate to the specific booking instance

#### Additional Enhancements
- Expand `status` enum for complete workflow
- Add `num_guests` for capacity validation
- Add check-in/check-out timestamps
- Add cancellation metadata
- Add audit fields

#### Normalized Output
```
booking(
	booking_id [PK],
	property_id [FK → property],
	user_id [FK → user],
	start_date,
	end_date,
	num_guests,
	total_price,
	status,
	special_requests,
	checked_in_at,
	checked_out_at,
	canceled_at,
	cancellation_reason,
	created_at,
	updated_at,
	deleted_at,
	CHECK(end_date > start_date)
)
```

---

### 6. Payment Entity Normalization

#### Current State (Unnormalized)
```
payment(payment_id, booking_id [UNIQUE], amount, payment_date, payment_method)
```

#### 1NF Analysis
**Status**: ✓ All attributes are atomic

#### 2NF Analysis
**Status**: ✓ All attributes depend on `payment_id`

#### 3NF Analysis
**Status**: ✓ No transitive dependencies

#### Critical Issue
**UNIQUE constraint on `booking_id`** creates a 1:1 relationship, preventing:
- Partial payments (deposit + final payment)
- Multiple payment methods
- Refund transactions

**Solution**: Remove UNIQUE constraint to enable 1:many relationship

#### Additional Enhancements
- Add `payment_type` (deposit, full_payment, partial_payment, refund)
- Add `payment_status` (pending, processing, completed, failed, refunded)
- Add `transaction_id` for external processor reference
- Add `payment_processor_response` JSONB for reconciliation
- Add timestamp fields

#### Normalized Output
```
payment(
	payment_id [PK],
	booking_id [FK → booking],  -- No longer UNIQUE
	amount,
	payment_type,
	payment_method,
	payment_status,
	transaction_id,
	payment_processor_response [JSONB],
	paid_at,
	refunded_at,
	created_at,
	updated_at,
	deleted_at
)
```

---

### 7. Review Entity Normalization

#### Current State (Unnormalized)
```
review(review_id, property_id, user_id, rating, comment, created_at)
```

#### 1NF Analysis
**Status**: ✓ All attributes are atomic

#### 2NF Analysis
**Status**: ✓ All attributes depend on `review_id`

#### 3NF Analysis
**Potential Issue**: No verification that user actually stayed at property
- Review should depend on completed booking, not just property + user

**Solution**: Add `booking_id` foreign key to verify stay occurred

#### Additional Enhancements
- Add detailed rating dimensions (cleanliness, accuracy, communication, location, value)
- Add `host_response` for host replies
- Add `helpful_count` for community feedback
- Add `updated_at` and `deleted_at`

#### Normalized Output
```
review(
	review_id [PK],
	property_id [FK → property],
	booking_id [FK → booking, UNIQUE],
	user_id [FK → user],
	rating,
	rating_cleanliness,
	rating_accuracy,
	rating_checkin,
	rating_communication,
	rating_location,
	rating_value,
	comment,
	host_response,
	host_responded_at,
	helpful_count,
	created_at,
	updated_at,
	deleted_at
)
```

---

### 8. Message Entity Normalization

#### Current State (Unnormalized)
```
message(message_id, sender_id, recipient_id, message_body, sent_at)
```

#### 1NF Analysis
**Status**: ✓ All attributes are atomic

#### 2NF Analysis
**Status**: ✓ All attributes depend on `message_id`

#### 3NF Analysis
**Status**: ✓ No transitive dependencies

#### Additional Enhancements
- Add optional `booking_id` for contextual messages
- Add `message_type` for categorization
- Add `is_read` and `read_at` for tracking
- Add `deleted_at` for soft deletion

#### Normalized Output
```
message(
	message_id [PK],
	booking_id [FK → booking, OPTIONAL],
	sender_id [FK → user],
	recipient_id [FK → user],
	message_type,
	message_body,
	is_read,
	read_at,
	sent_at,
	deleted_at,
	CHECK(sender_id != recipient_id)
)
```

---

## Normalization Output

### Summary of Changes

#### Entities Created
1. **Location** - Extracted from Property (3NF compliance)
2. **Amenity** - New entity for property features
3. **Property_Amenity** - Junction table for many-to-many relationship
4. **Property_Availability** - New entity for per-date pricing and availability

#### Entities Modified
1. **User** - Split `full_name`, added role and audit fields
2. **Property** - Extracted location, added metadata and status
3. **Booking** - Added guest tracking, check-in/out, cancellation
4. **Payment** - Removed UNIQUE constraint, added status and type
5. **Review** - Linked to booking, added detailed ratings
6. **Message** - Added booking context and read tracking

---

### Normalization Benefits

#### Data Integrity
- **No Redundancy**: Location data stored once and referenced
- **Consistent Naming**: Amenities have single source of truth
- **Verified Reviews**: Reviews linked to actual bookings
- **Accurate Payments**: Multiple payments per booking supported

#### Query Efficiency
- **Optimized Searches**: Indexed location data for geographic queries
- **Fast Availability**: Dedicated table with composite unique constraint
- **Clean Relationships**: Proper foreign keys enable efficient joins
- **Partial Indexes**: WHERE deleted_at IS NULL for active records only

#### Business Rules Enforcement
- **No Double Bookings**: Unique index on (property_id, start_date, end_date) for confirmed bookings
- **Valid Date Ranges**: CHECK constraints ensure end_date > start_date
- **Guest Capacity**: CHECK constraints prevent overbooking
- **Payment Flexibility**: Support for deposits, partial payments, and refunds
- **Review Validity**: Reviews only allowed after completed stays

#### Maintainability
- **Independent Updates**: Change address without touching property
- **Flexible Amenities**: Add/remove amenities without schema changes
- **Extensible Status**: Easy to add new booking/payment statuses
- **Audit Trail**: Track who created/updated records and when
- **Safe Deletion**: Soft deletes preserve history

---

## Final Normalized Entities

Below are the complete normalized entities in Third Normal Form (3NF):

### Core Entities

#### 1. User
```
user(
	user_id              UUID [PK],
	first_name           TEXT,
	last_name            TEXT,
	email                TEXT [UNIQUE],
	password_hash        TEXT,
	phone_number         TEXT,
	role                 VARCHAR(20),  -- 'guest', 'host', 'admin'
	is_verified          BOOLEAN,
	profile_image_url    TEXT,
	preferred_language   VARCHAR(10),
	preferred_currency   VARCHAR(3),
	created_at           TIMESTAMPTZ,
	updated_at           TIMESTAMPTZ,
	deleted_at           TIMESTAMPTZ
)

Constraints:
- CHECK(role IN ('guest', 'host', 'admin'))
- CHECK(email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
```

**Normalization Status**: ✓ 3NF
- Atomic attributes (1NF)
- No partial dependencies (2NF)
- No transitive dependencies (3NF)

---

#### 2. Location
```
location(
	location_id      UUID [PK],
	country          VARCHAR(100),
	state_province   VARCHAR(100),
	city             VARCHAR(100),
	postal_code      VARCHAR(20),
	address_line1    TEXT,
	address_line2    TEXT,
	latitude         DECIMAL(10, 8),
	longitude        DECIMAL(11, 8),
	created_at       TIMESTAMPTZ,
	updated_at       TIMESTAMPTZ
)
```

**Normalization Status**: ✓ 3NF
- Extracted from property to eliminate transitive dependency
- All address components atomic (1NF)
- Direct dependency on location_id (2NF, 3NF)

---

#### 3. Property
```
property(
	property_id       UUID [PK],
	host_id           UUID [FK → user.user_id],
	location_id       UUID [FK → location.location_id],
	name              TEXT,
	description       TEXT,
	property_type     VARCHAR(50),  -- 'apartment', 'house', 'villa', 'cabin', 'hotel_room', 'other'
	price_per_night   NUMERIC(10,2),
	max_guests        INTEGER,
	num_bedrooms      INTEGER,
	num_bathrooms     DECIMAL(3,1),
	status            VARCHAR(20),   -- 'draft', 'pending_approval', 'active', 'inactive', 'suspended'
	created_at        TIMESTAMPTZ,
	updated_at        TIMESTAMPTZ,
	deleted_at        TIMESTAMPTZ,
	created_by        UUID [FK → user.user_id],
	updated_by        UUID [FK → user.user_id]
)

Constraints:
- CHECK(property_type IN ('apartment', 'house', 'villa', 'cabin', 'hotel_room', 'other'))
- CHECK(price_per_night > 0)
- CHECK(max_guests > 0)
- CHECK(num_bedrooms >= 0)
- CHECK(num_bathrooms > 0)
- CHECK(status IN ('draft', 'pending_approval', 'active', 'inactive', 'suspended'))
```

**Normalization Status**: ✓ 3NF
- Location extracted to separate table (3NF)
- All attributes atomic (1NF)
- Direct dependency on property_id (2NF, 3NF)

---

### Property-Related Entities

#### 4. Property Availability
```
property_availability(
	availability_id   UUID [PK],
	property_id       UUID [FK → property.property_id],
	available_date    DATE,
	is_available      BOOLEAN,
	price_override    NUMERIC(10,2),
	min_nights        INTEGER,
	created_at        TIMESTAMPTZ,
	updated_at        TIMESTAMPTZ,
	UNIQUE(property_id, available_date)
)

Constraints:
- CHECK(price_override IS NULL OR price_override > 0)
- CHECK(min_nights IS NULL OR min_nights > 0)
```

**Normalization Status**: ✓ 3NF
- Separate entity to avoid repeating date-specific data (2NF)
- Natural composite key (property_id, available_date)
- All attributes depend on this composite (3NF)

---

#### 5. Amenity
```
amenity(
	amenity_id   UUID [PK],
	name         VARCHAR(100) [UNIQUE],
	category     VARCHAR(50),  -- 'basic', 'safety', 'entertainment', 'kitchen', 'outdoor', 'accessibility'
	icon         VARCHAR(50),
	created_at   TIMESTAMPTZ
)

Constraints:
- CHECK(category IN ('basic', 'safety', 'entertainment', 'kitchen', 'outdoor', 'accessibility'))
```

**Normalization Status**: ✓ 3NF
- Independent entity for reusable amenities
- Eliminates redundant amenity descriptions

---

#### 6. Property Amenity (Junction Table)
```
property_amenity(
	property_id   UUID [PK, FK → property.property_id],
	amenity_id    UUID [PK, FK → amenity.amenity_id],
	created_at    TIMESTAMPTZ
)
```

**Normalization Status**: ✓ 3NF
- Resolves many-to-many relationship
- Composite primary key eliminates partial dependencies (2NF)

---

### Booking Flow Entities

#### 7. Booking
```
booking(
	booking_id           UUID [PK],
	property_id          UUID [FK → property.property_id],
	user_id              UUID [FK → user.user_id],
	start_date           DATE,
	end_date             DATE,
	num_guests           INTEGER,
	total_price          NUMERIC(10,2),
	status               VARCHAR(20),  -- 'pending', 'confirmed', 'checked_in', 'checked_out', 'completed', 'canceled', 'refunded'
	special_requests     TEXT,
	checked_in_at        TIMESTAMPTZ,
	checked_out_at       TIMESTAMPTZ,
	canceled_at          TIMESTAMPTZ,
	cancellation_reason  TEXT,
	created_at           TIMESTAMPTZ,
	updated_at           TIMESTAMPTZ,
	deleted_at           TIMESTAMPTZ
)

Constraints:
- CHECK(status IN ('pending', 'confirmed', 'checked_in', 'checked_out', 'completed', 'canceled', 'refunded'))
- CHECK(num_guests > 0)
- CHECK(total_price > 0)
- CHECK(end_date > start_date)
- CHECK(checked_in_at IS NULL OR checked_in_at >= start_date::timestamptz)
- CHECK(checked_out_at IS NULL OR checked_out_at <= (end_date::timestamptz + interval '1 day'))
- UNIQUE INDEX(property_id, start_date, end_date) WHERE status IN ('confirmed', 'checked_in') AND deleted_at IS NULL
```

**Normalization Status**: ✓ 3NF
- All attributes atomic (1NF)
- Direct dependency on booking_id (2NF, 3NF)
- Unique constraint prevents double bookings

---

#### 8. Payment
```
payment(
	payment_id                    UUID [PK],
	booking_id                    UUID [FK → booking.booking_id],  -- NOT UNIQUE (allows multiple payments)
	amount                        NUMERIC(10,2),
	payment_type                  VARCHAR(20),  -- 'deposit', 'full_payment', 'partial_payment', 'refund'
	payment_method                VARCHAR(20),  -- 'credit_card', 'debit_card', 'paypal', 'stripe', 'bank_transfer'
	payment_status                VARCHAR(20),  -- 'pending', 'processing', 'completed', 'failed', 'refunded'
	transaction_id                TEXT,
	payment_processor_response    JSONB,
	paid_at                       TIMESTAMPTZ,
	refunded_at                   TIMESTAMPTZ,
	created_at                    TIMESTAMPTZ,
	updated_at                    TIMESTAMPTZ,
	deleted_at                    TIMESTAMPTZ
)

Constraints:
- CHECK(amount > 0)
- CHECK(payment_type IN ('deposit', 'full_payment', 'partial_payment', 'refund'))
- CHECK(payment_method IN ('credit_card', 'debit_card', 'paypal', 'stripe', 'bank_transfer'))
- CHECK(payment_status IN ('pending', 'processing', 'completed', 'failed', 'refunded'))
```

**Normalization Status**: ✓ 3NF
- Removed UNIQUE constraint enables 1:many relationship with booking
- Supports partial payments and refunds
- All attributes depend on payment_id (3NF)

---

#### 9. Review
```
review(
	review_id               UUID [PK],
	property_id             UUID [FK → property.property_id],
	booking_id              UUID [FK → booking.booking_id, UNIQUE],
	user_id                 UUID [FK → user.user_id],
	rating                  SMALLINT,  -- 1-5
	rating_cleanliness      SMALLINT,  -- 1-5
	rating_accuracy         SMALLINT,  -- 1-5
	rating_checkin          SMALLINT,  -- 1-5
	rating_communication    SMALLINT,  -- 1-5
	rating_location         SMALLINT,  -- 1-5
	rating_value            SMALLINT,  -- 1-5
	comment                 TEXT,
	host_response           TEXT,
	host_responded_at       TIMESTAMPTZ,
	helpful_count           INTEGER,
	created_at              TIMESTAMPTZ,
	updated_at              TIMESTAMPTZ,
	deleted_at              TIMESTAMPTZ
)

Constraints:
- CHECK(rating >= 1 AND rating <= 5)
- CHECK(rating_cleanliness IS NULL OR (rating_cleanliness >= 1 AND rating_cleanliness <= 5))
- CHECK(rating_accuracy IS NULL OR (rating_accuracy >= 1 AND rating_accuracy <= 5))
- CHECK(rating_checkin IS NULL OR (rating_checkin >= 1 AND rating_checkin <= 5))
- CHECK(rating_communication IS NULL OR (rating_communication >= 1 AND rating_communication <= 5))
- CHECK(rating_location IS NULL OR (rating_location >= 1 AND rating_location <= 5))
- CHECK(rating_value IS NULL OR (rating_value >= 1 AND rating_value <= 5))
```

**Normalization Status**: ✓ 3NF
- Linked to booking_id ensures review verification
- Detailed rating dimensions remain atomic (1NF)
- All attributes depend on review_id (3NF)

---

### Communication Entity

#### 10. Message
```
message(
	message_id       UUID [PK],
	booking_id       UUID [FK → booking.booking_id, OPTIONAL],
	sender_id        UUID [FK → user.user_id],
	recipient_id     UUID [FK → user.user_id],
	message_type     VARCHAR(20),  -- 'inquiry', 'booking_related', 'support', 'general'
	message_body     TEXT,
	is_read          BOOLEAN,
	read_at          TIMESTAMPTZ,
	sent_at          TIMESTAMPTZ,
	deleted_at       TIMESTAMPTZ
)

Constraints:
- CHECK(message_type IN ('inquiry', 'booking_related', 'support', 'general'))
- CHECK(sender_id != recipient_id)
Normalization Status: ✓ 3NF

All attributes atomic (1NF)
Direct dependency on message_id (2NF, 3NF)
Optional booking_id provides context without creating dependency


Entity Relationship Summary
User (1) ──────< (many) Property [as host]
User (1) ──────< (many) Booking [as guest]
User (1) ──────< (many) Review [as reviewer]
User (1) ──────< (many) Message [as sender]
User (1) ──────< (many) Message [as recipient]
Location (1) ──────< (many) Property
Property (1) ──────< (many) Property_Availability
Property (1) ──────< (many) Booking
Property (1) ──────< (many) Review
Property (many) ────< (many) Amenity [via Property_Amenity]
Amenity (many) ────< (many) Property [via Property_Amenity]
Booking (1) ──────< (many) Payment
Booking (1) ──────< (1) Review [one review per booking]
Booking (1) ──────< (many) Message [optional booking context]

---

## Normalization Verification Checklist

### First Normal Form (1NF) ✓
- [x] User: `full_name` split into `first_name` and `last_name`
- [x] Property: `location` extracted into atomic address fields
- [x] All entities have atomic columns
- [x] No repeating groups
- [x] Each column contains single value type

### Second Normal Form (2NF) ✓
- [x] All tables use surrogate primary keys (UUID)
- [x] No partial dependencies on composite keys
- [x] Property_Amenity: Composite key (property_id, amenity_id) with no non-key attributes to create partial dependencies
- [x] Property_Availability: Composite unique key (property_id, available_date) properly structured

### Third Normal Form (3NF) ✓
- [x] Location extracted from Property (eliminates transitive dependency: country → state → city)
- [x] Amenity extracted to separate entity (eliminates repeating amenity descriptions)
- [x] All non-key attributes directly depend on primary key only
- [x] No transitive dependencies remain in any entity

---

## Key Normalization Decisions

### 1. Location Extraction (3NF Compliance)
**Before:**
```
property(property_id, ..., street, city, state, country, postal_code, ...)
```
**Issue**: Transitive dependency - state depends on city, country depends on state

**After:**
```
location(location_id, country, state_province, city, postal_code, address_line1, address_line2, latitude, longitude)
property(property_id, ..., location_id [FK], ...)
```
**Benefit**: Location data deduplicated, single source of truth for addresses

---

### 2. Amenity Many-to-Many Normalization
**Before (if implemented):**
```
property(property_id, ..., amenities: "WiFi,Kitchen,Pool", ...)  -- Violates 1NF
```

**After:**
```
amenity(amenity_id, name, category, icon)
property_amenity(property_id, amenity_id)
```
**Benefit**: Amenities reusable, consistent naming, supports categorization

---

### 3. Payment Relationship Change (1:1 → 1:Many)
**Before:**
```
payment(payment_id, booking_id [UNIQUE], ...)
```
**Issue**: UNIQUE constraint forces 1:1, prevents partial payments

**After:**
```
payment(payment_id, booking_id [FK], ...)  -- No UNIQUE
```
**Benefit**: Supports deposits, partial payments, refunds, multiple payment methods

---

### 4. Review Verification (Booking Linkage)
**Before:**
```
review(review_id, property_id, user_id, ...)
```
**Issue**: No verification that user stayed at property

**After:**
```
review(review_id, property_id, booking_id [UNIQUE], user_id, ...)
```
**Benefit**: Reviews verified through completed bookings, one review per stay

---

### 5. Availability Separation (New Entity)
**Before:**
Property table only had base price_per_night

**After:**
```
property_availability(availability_id, property_id, available_date, is_available, price_override, min_nights)
```
**Benefit**: Per-date pricing control, maintenance blocking, minimum stay requirements

---

## Normalization Benefits Summary

### Data Integrity
| Aspect | Improvement |
|--------|-------------|
| Redundancy | Location stored once, referenced by multiple properties |
| Consistency | Amenities have single definition across all properties |
| Accuracy | Reviews verified against actual completed bookings |
| Validity | CHECK constraints enforce business rules at database level |

### Performance
| Aspect | Improvement |
|--------|-------------|
| Geographic Search | Dedicated location table with spatial indexes (GIST) |
| Availability Queries | Dedicated table with composite unique constraint prevents scans |
| Active Records | Partial indexes (WHERE deleted_at IS NULL) reduce index size |
| Relationship Queries | Proper foreign keys enable efficient JOIN operations |

### Maintainability
| Aspect | Improvement |
|--------|-------------|
| Address Updates | Change location once, affects all referencing properties |
| Amenity Management | Add/modify amenities without altering property records |
| Status Extensions | Add new booking/payment statuses without data migration |
| Audit Trail | Track creation/modification metadata for compliance |

### Business Logic
| Aspect | Improvement |
|--------|-------------|
| Double Booking Prevention | Unique index on (property_id, date_range, status) |
| Payment Flexibility | Multiple payments per booking (deposits, installments, refunds) |
| Review Authenticity | Reviews linked to verified stays only |
| Capacity Control | Guest count validated against property max_guests |

---

## Migration Considerations

### Phase 1: Schema Creation
1. Create new tables: `location`, `amenity`, `property_amenity`, `property_availability`
2. Add new columns to existing tables: `deleted_at`, audit fields
3. Do NOT drop old columns yet (maintain backward compatibility)

### Phase 2: Data Migration
1. **Location Extraction**:
	 - Extract unique address combinations from `property` table
	 - INSERT into `location` table
	 - UPDATE `property` set `location_id` based on address match

2. **Amenity Migration**:
	 - Define standard amenity list
	 - INSERT into `amenity` table
	 - Create `property_amenity` mappings based on existing property data

3. **User Name Split**:
	 - Parse `full_name` into `first_name` and `last_name`
	 - UPDATE user records

4. **Payment Constraint Removal**:
	 - DROP UNIQUE constraint on `payment.booking_id`

### Phase 3: Validation
1. Verify all foreign key relationships
2. Check data integrity (no orphaned records)
3. Validate CHECK constraints
4. Test business logic functions

### Phase 4: Application Update
1. Update queries to use new table structure
2. Implement soft delete logic (WHERE deleted_at IS NULL)
3. Update booking conflict prevention logic
4. Modify payment processing to handle multiple payments

### Phase 5: Cleanup
1. Drop old columns from original tables
2. Remove deprecated indexes
3. Add production indexes
4. Update documentation

---

## Index Strategy for Normalized Schema

### Primary Indexes (Foreign Keys)
```sql
-- User relationships
CREATE INDEX idx_property_host ON property(host_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_booking_user ON booking(user_id) WHERE deleted_at IS NULL;

-- Location relationships
CREATE INDEX idx_property_location ON property(location_id) WHERE deleted_at IS NULL;

-- Booking relationships
CREATE INDEX idx_booking_property ON booking(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_payment_booking ON payment(booking_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_review_booking ON review(booking_id) WHERE deleted_at IS NULL;

-- Message relationships
CREATE INDEX idx_message_sender ON message(sender_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_message_recipient ON message(recipient_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_message_booking ON message(booking_id) WHERE deleted_at IS NULL;
```

### Business Logic Indexes
```sql
-- Prevent double bookings
CREATE UNIQUE INDEX idx_no_double_booking ON booking(property_id, start_date, end_date)
	WHERE status IN ('confirmed', 'checked_in') AND deleted_at IS NULL;

-- Availability queries
CREATE INDEX idx_availability_property_date ON property_availability(property_id, available_date);
CREATE INDEX idx_availability_date_range ON property_availability(available_date) 
	WHERE is_available = true;

-- Property search
CREATE INDEX idx_property_status ON property(status) WHERE deleted_at IS NULL AND status = 'active';
CREATE INDEX idx_property_price ON property(price_per_night) WHERE deleted_at IS NULL;

-- Geographic search (requires PostGIS or earthdistance)
CREATE INDEX idx_location_coords ON location USING GIST(
	ll_to_earth(latitude, longitude)
) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Review queries
CREATE INDEX idx_review_property ON review(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_review_rating ON review(rating) WHERE deleted_at IS NULL;

-- Unread messages
CREATE INDEX idx_message_unread ON message(recipient_id, is_read) 
	WHERE deleted_at IS NULL AND is_read = false;
```

---

## Constraint Summary

### Referential Integrity (Foreign Keys)
```sql
-- User references
property.host_id → user.user_id
property.created_by → user.user_id
property.updated_by → user.user_id
booking.user_id → user.user_id
review.user_id → user.user_id
message.sender_id → user.user_id
message.recipient_id → user.user_id

-- Property references
property.location_id → location.location_id
booking.property_id → property.property_id
review.property_id → property.property_id
property_amenity.property_id → property.property_id
property_availability.property_id → property.property_id

-- Booking references
payment.booking_id → booking.booking_id
review.booking_id → booking.booking_id (UNIQUE)
message.booking_id → booking.booking_id (OPTIONAL)

-- Amenity references
property_amenity.amenity_id → amenity.amenity_id
```

### Domain Constraints (CHECK)
```sql
-- User
CHECK(role IN ('guest', 'host', 'admin'))
CHECK(email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')

-- Property
CHECK(property_type IN ('apartment', 'house', 'villa', 'cabin', 'hotel_room', 'other'))
CHECK(price_per_night > 0)
CHECK(max_guests > 0)
CHECK(num_bedrooms >= 0)
CHECK(num_bathrooms > 0)
CHECK(status IN ('draft', 'pending_approval', 'active', 'inactive', 'suspended'))

-- Property Availability
CHECK(price_override IS NULL OR price_override > 0)
CHECK(min_nights IS NULL OR min_nights > 0)

-- Amenity
CHECK(category IN ('basic', 'safety', 'entertainment', 'kitchen', 'outdoor', 'accessibility'))

-- Booking
CHECK(status IN ('pending', 'confirmed', 'checked_in', 'checked_out', 'completed', 'canceled', 'refunded'))
CHECK(num_guests > 0)
CHECK(total_price > 0)
CHECK(end_date > start_date)
CHECK(checked_in_at IS NULL OR checked_in_at >= start_date::timestamptz)
CHECK(checked_out_at IS NULL OR checked_out_at <= (end_date::timestamptz + interval '1 day'))

-- Payment
CHECK(amount > 0)
CHECK(payment_type IN ('deposit', 'full_payment', 'partial_payment', 'refund'))
CHECK(payment_method IN ('credit_card', 'debit_card', 'paypal', 'stripe', 'bank_transfer'))
CHECK(payment_status IN ('pending', 'processing', 'completed', 'failed', 'refunded'))

-- Review
CHECK(rating >= 1 AND rating <= 5)
CHECK(rating_cleanliness IS NULL OR (rating_cleanliness >= 1 AND rating_cleanliness <= 5))
-- ... similar for other rating dimensions

-- Message
CHECK(message_type IN ('inquiry', 'booking_related', 'support', 'general'))
CHECK(sender_id != recipient_id)
```

### Uniqueness Constraints
```sql
-- Single column unique
user.email UNIQUE
amenity.name UNIQUE
review.booking_id UNIQUE  -- One review per booking

-- Composite unique
property_availability(property_id, available_date) UNIQUE
property_amenity(property_id, amenity_id) PRIMARY KEY
```

---

## Conclusion

This normalization analysis has successfully transformed the AirBnB clone database from its original unnormalized state to a fully normalized Third Normal Form (3NF) structure. The key achievements include:

1. **1NF Compliance**: All attributes are atomic, with composite fields like `full_name` and `location` properly decomposed.

2. **2NF Compliance**: Partial dependencies eliminated through the use of surrogate primary keys and proper junction tables for many-to-many relationships.

3. **3NF Compliance**: Transitive dependencies removed by extracting `location` as an independent entity and normalizing amenity management.

4. **Enhanced Data Integrity**: Addition of comprehensive CHECK constraints, foreign key relationships, and business rule enforcement at the database level.

5. **Improved Maintainability**: Soft delete pattern, audit trails, and independent entity management enable safer operations and historical tracking.

6. **Better Performance**: Strategic indexing, including partial indexes for active records and spatial indexes for geographic queries.

7. **Business Logic Support**: Database-level enforcement of critical rules like double booking prevention, payment flexibility, and review verification.

The normalized schema provides a solid foundation for a scalable, maintainable, and reliable booking platform that enforces data integrity while remaining flexible for future enhancements.

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-24  
**Normalization Level**: Third Normal Form (3NF)  
**Total Entities**: 10 (User, Location, Property, Property_Availability, Amenity, Property_Amenity, Booking, Payment, Review, Message)
