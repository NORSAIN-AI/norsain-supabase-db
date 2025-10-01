# NORSAIN – Copilot-instrukser (repo-omfattende)

**Kontekst**
- Dette repoet inneholder Supabase/Postgres: migrasjoner (DDL), seeds (DML), RLS, webhooks/outbox.
- Dialekt: PostgreSQL. RLS fra dag 1. Forward-only migrasjoner.

**Navngiving**
- Migrasjoner: `YYYYMMDDHHMMSS_beskrivelse.sql` i `supabase/migrations/`.
- Seeds per miljø: `supabase/seeds/{dev|stage|prod}/seed.sql` som inkluderer andre filer.

**Regler**
- Én logisk endring per migrasjonsfil.
- Zero-downtime: expand → backfill → switch → contract.
- Unngå transaksjon rundt `CREATE INDEX CONCURRENTLY` og enkelte `ALTER TYPE`.
- Idempotente seeds (ON CONFLICT DO NOTHING).

**Bygg/test**
- Lokal: `supabase start`, `supabase db reset`, `supabase studio`.
- CI kjører lint/test og `supabase db push`.

**Når du genererer kode**
- Bruk Postgres-syntaks, eksplisitte kolonner (unngå `SELECT *` i prod).
- Legg korte kommentarer i toppen: hva/hvorfor.
