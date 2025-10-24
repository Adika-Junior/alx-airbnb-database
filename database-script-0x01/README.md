Schema README — ERD/database-script-0x01
=====================================

What this folder contains
-------------------------
- `schema.sql` — Full SQL DDL extracted from the normalization analysis. It includes table CREATE statements, indexes, triggers, views, example functions and idempotent sample data inserts.

Purpose
-------
This folder provides a standalone SQL schema for an AirBnB-style application. The schema is normalized to 3NF and includes production-focused features such as soft deletes, audit fields, availability calendar, normalized amenities, and support for partial payments.

Prerequisites
-------------
- PostgreSQL 13+ (the SQL uses modern PG features and plpgsql functions).
- Extensions required (schema.sql will attempt to enable them):
  - `pgcrypto` (for `gen_random_uuid()`)
  - `cube` and `earthdistance` (for spatial GIST index using `ll_to_earth`)

How to run
----------
1. Create a database and connect with `psql` or your DB client.
2. From the repository root run:

```bash
# from repository root
psql -d your_db_name -f ERD/database-script-0x01/schema.sql
```

Notes & best practices
----------------------
- Run this file in a staging environment first. The file is meant to be idempotent for the objects it creates, but data migrations require careful ordering and testing.
- If you already have an existing production schema, follow a migration plan (backups, creating new objects, data backfills, adding indexes afterwards) rather than applying the whole `schema.sql` directly to production.
- Consider disabling some indexes during large bulk data backfills and re-creating them after import to improve load speed.

Schema highlights (quick reference)
----------------------------------
- Core tables: `user`, `location`, `property`, `property_availability`, `amenity`, `property_amenity`, `booking`, `payment`, `review`, `message`.
- Primary keys are UUIDs with `gen_random_uuid()` defaults.
- Soft deletes implemented as `deleted_at TIMESTAMPTZ` on major tables.
- Important constraints: date-range checks on `booking`, unique per-day availability on `property_availability`, composite PK on `property_amenity`.
- Indexing: partial indexes where `deleted_at IS NULL` for common read queries; spatial GIST on `location` coordinates.
- Business logic: functions such as `check_property_availability()` live in the SQL file. Use these as helpers in application logic or as part of transactional checks.

Testing recommendations
-----------------------
- Create a small seed file (see below) to insert:
  - A host user and a guest user
  - A property and a matching location row
  - A few `property_availability` rows and a confirmed booking
  - Payments and a review
- Validate constraints by attempting to insert overlapping confirmed bookings (should be prevented by the unique partial index/logic).

Next steps I can do for you
---------------------------
1. Produce an ordered migration runbook (ALTERs + data backfill SQL) to safely migrate an existing database to this schema.
2. Generate a small test harness `seed.sql` with example data plus assertion queries to validate constraints (double-booking prevention, availability checks, functions).

Open questions
--------------
- Do you want the migration runbook for an existing schema (i.e., starting from the `original-tables.md` layout), or a fresh deploy script?
- Should I produce the test harness now and place it in this folder as `seed.sql`?

Contact
-------
If you want me to generate the migration runbook or the test harness, reply with "migration" or "tests" (or "both") and I will add them to `ERD/database-script-0x01/`.
