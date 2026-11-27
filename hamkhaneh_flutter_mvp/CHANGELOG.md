# Changelog

## PocketBase migration

- Migrated household data access from the previous Supabase-oriented setup to PocketBase authentication and collections.
- Added support for the `houses` collection (owner, members, and invite code), `tasks` (house-linked task status and due dates), and `shopping_items` (house-linked items, purchase status, and month key).
- Replaced the unsupported monthly-spend dashboard value with a count of purchased items; the current schema contains no spending amount.
- Added GitHub Actions Flutter dependency and static-analysis checks without requiring repository secrets.
