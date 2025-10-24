# Schema README — ERD/database-script-0x01

What this folder contains
-------------------------
- `schema.sql` — Full SQL DDL extracted from the normalization analysis. It includes table CREATE
  statements, indexes, triggers, views, example functions and idempotent sample data inserts.

Purpose
-------
This folder provides a standalone SQL schema for an AirBnB-style application. The schema is normalized
to 3NF and includes production-focused features such as soft deletes, audit fields, availability
calendar, normalized amenities, and support for partial payments.

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