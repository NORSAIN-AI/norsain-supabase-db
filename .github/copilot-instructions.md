# NORSAIN – Copilot-instrukser (repo)
- Stack: Supabase/Postgres. RLS fra dag 1. Forward-only migrasjoner.
- Navn: `YYYYMMDDHHMMSS_beskrivelse.sql` i `supabase/migrations/`.
- Seeds per miljø: `supabase/seeds/{dev|stage|prod}/seed.sql` inkluderer `00_ref_data.sql`, `01_dev_user.sql` osv.
- Zero-downtime: expand → backfill → switch → contract.
- Ikke transaksjon på `CREATE INDEX CONCURRENTLY` / enkelte `ALTER TYPE`.

Lokal:
```bash
supabase start
supabase db reset
supabase studio
