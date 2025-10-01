---
applies-to: "supabase/**"
---

# Copilot – DB-spesifikke føringer

**Migrasjoner**
- Bruk `CREATE EXTENSION IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS` når mulig.
- Del store endringer i flere filer (indekser egen fil om CONCURRENTLY).
- RLS/policies i egen migrasjonsfil eller inkludert med `\i` for lesbarhet.

**Seeds**
- Prod: kun referansedata. Dev/Stage: demo-data ok.
- Master `seed.sql` inkluderer nummererte filer: `00_ref_data.sql`, `01_dev_user.sql`, …

**Tester**
- Legg små SQL-asserter i `supabase/tests/` (RLS/EXPLAIN).
