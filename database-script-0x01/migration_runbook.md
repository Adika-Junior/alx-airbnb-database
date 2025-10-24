# Migration Runbook — AirBnB Schema (ordered)

This runbook is intended as a safe, ordered guide to migrate an existing schema to the normalized schema
contained in `schema.sql`.

Pre-reqs
- Perform migration in a staging environment mirroring production.
- Ensure backups (logical + physical) are taken and tested.
- Run during a maintenance window if writes cannot be paused; otherwise prefer a phased deployment with
  idempotent steps.

Overview of phases
1. Add non-destructive columns and new tables.
2. Backfill deduplicated reference data (locations, amenities).
3. Populate FK columns on child tables (update properties to reference location_id, create
   property_amenity rows).
4. Validate data and application behavior in read-only mode (smoke tests + booking conflict simulation).
5. Create constraints (FKs, unique indexes) and then drop old/deprecated columns.

Ordered steps (example SQL snippets and notes)

Step 0 — prepare
- Capture counts and basic metrics for rollback plans.

Step 1 — create new tables and helper objects
- Create `location`, `amenity`, `property_amenity`, `property_availability` and any helper PL/pgSQL
  functions used by the new schema. These should be created without removing or modifying production
  columns.
- Example: run the `CREATE TABLE` statements from `schema.sql` for new objects only.

Step 2 — add nullable FK columns to existing tables
- Add `location_id UUID NULL` to `property`.
- Add any new nullable columns required for payments/booking metadata.

Example:

```sql
ALTER TABLE property ADD COLUMN location_id UUID;
ALTER TABLE property ADD COLUMN property_type VARCHAR(50);
```

Step 3 — backfill `location` and update `property.location_id`
 - Deduplicate addresses from the existing property address fields and create a `location` row per
   unique physical address.
 - Run in batches (example using LIMIT/OFFSET or cursor-based processing).

Backfill pattern (example):
```sql
-- 1) create deduped locations
INSERT INTO location (location_id, street_address, city, state, postal_code, country, latitude, longitude)
SELECT gen_random_uuid(), street_address, city, state, postal_code, country, latitude, longitude
FROM (
  SELECT DISTINCT street_address, city, state, postal_code, country, latitude, longitude
  FROM property
) t;

-- 2) update properties to reference location rows
UPDATE property p
SET location_id = l.location_id
FROM location l
WHERE p.street_address = l.street_address
  AND p.city = l.city
  AND p.state = l.state
  AND p.postal_code = l.postal_code
  AND p.country = l.country
  AND p.latitude = l.latitude
  AND p.longitude = l.longitude;
```

Notes:
- If addresses cannot be matched exactly, use fuzzy-match logic with a human-in-the-loop for murky cases.
- Run updates in small batches to limit transactional locking.

Step 4 — migrate amenities
- Insert distinct amenities into `amenity`.
- Insert into `property_amenity` by joining property amenity text to the new `amenity` rows.

Step 5 — create and test indexes
- Once bulk backfills are done, create indexes (partial indexes where appropriate) to avoid bloat during load.

Step 6 — switch application reads/writes
- Point a subset of traffic or a staging application to use the new columns (e.g.,
  `property.location_id`).
- Run integration tests (availability, booking conflict simulation, payments).

Step 7 — create constraints and tighten nullability
- After verification, add NOT NULL constraints and FKs where appropriate in small transactional steps.

Example:
```sql
ALTER TABLE property ALTER COLUMN location_id SET NOT NULL;
ALTER TABLE property ADD CONSTRAINT fk_property_location
  FOREIGN KEY (location_id) REFERENCES location(location_id);
```

Step 8 — drop deprecated columns
- After a hold period and confidence in the new model, drop old address columns or set them to
  DEPRECATED and eventually remove them.

Rollback guidance
- Rollbacks should be based on previously captured backups and the pre-migration snapshots.
- Keep old columns until you are comfortable removing them so you can rollback without loss of derived
  data.

Testing checklist (before production cutover)
 - Booking conflict simulation: try concurrent bookings for the same property/time window; ensure
   unique/overlap protection holds.
 - Availability queries: ensure `property_availability` reflects expected prices/blocks.
- Payments: run test payments and verify `payment` rows and processor JSONB are stored.
- Performance: run read-heavy queries with partial indexes and measure latency.

Contact and escalation
- Keep DB and app engineers on call during the cutover window. If any step fails, pause and consult the runbook owner.

End of runbook
