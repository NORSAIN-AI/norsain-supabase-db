# norsain-supabase-db
Supabase migrasjoner, seeds og RLS-policyer for NORSAIN MAS

## Forutsetninger

- [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started) installert
- Docker installert og kjører (for lokal utvikling)

## Kom i gang

### Start Supabase lokalt

For å starte Supabase lokalt med Docker:

```bash
supabase start
```

Dette kommandoen vil:
- Starte PostgreSQL database
- Kjøre alle migrasjoner
- Starte Supabase Studio (admin-grensesnitt)
- Starte Auth, Storage og Realtime tjenester

Etter oppstart vil du få URL-er og nøkler for lokal utvikling.

### Tilgang til Supabase Studio

Supabase Studio er et web-basert admin-grensesnitt for din database.

Etter å ha kjørt `supabase start`, åpne:
- **URL**: http://localhost:54323
- Her kan du se tabeller, kjøre SQL-spørringer, administrere brukere, og mer

### Nullstille databasen

For å nullstille databasen til en ren tilstand (sletter alle data og kjører migrasjoner på nytt):

```bash
supabase db reset
```

Dette vil:
1. Droppe alle tabeller og data
2. Kjøre alle migrasjoner på nytt fra `supabase/migrations/`
3. Kjøre seed-data fra `supabase/seeds/dev/seed.sql` (for lokal utvikling)

**Merk**: Dette er destruktivt og bør bare brukes i utviklingsmiljø.

## Prosjektstruktur

```
.
├── supabase/
│   ├── config.toml              # Supabase konfigurasjon
│   ├── migrations/              # Database migrasjoner (timestamp-basert)
│   │   └── 20251001055804_create_users_table.sql
│   ├── seeds/                   # Seed data for ulike miljøer
│   │   ├── 00_ref_data.sql     # Referansedata (lookup tables, etc.)
│   │   ├── 01_dummy_user.sql   # Test-brukere
│   │   ├── dev/
│   │   │   └── seed.sql        # Dev seed (inkluderer ref data + dummy users)
│   │   ├── stage/
│   │   │   └── seed.sql        # Staging seed
│   │   └── prod/
│   │       └── seed.sql        # Prod seed (kun ref data, ingen dummy users)
│   └── tests/                   # Database tester
│       └── rls_users_select.sql # RLS test for users tabell
└── README.md
```

## Migrasjoner

Migrasjoner er SQL-filer som endrer databaseskjemaet. De kjøres i rekkefølge basert på timestamp i filnavnet.

### Opprette ny migrasjon

```bash
supabase migration new <migration_name>
```

Dette oppretter en ny migrasjonsfil i `supabase/migrations/` med timestamp.

### Kjøre migrasjoner

Migrasjoner kjøres automatisk ved `supabase start` og `supabase db reset`.

## Seeds

Seed-data brukes til å fylle databasen med initial data for testing og utvikling.

- **Dev**: Inkluderer referansedata og dummy-brukere
- **Stage**: Inkluderer referansedata og test-brukere
- **Prod**: Kun referansedata, ingen test-brukere

Seeds kjøres automatisk ved `supabase db reset`.

## Tester

RLS (Row Level Security) tester sikrer at brukere bare kan se sine egne data.

### Kjøre tester

```bash
psql postgresql://postgres:postgres@localhost:54322/postgres -f supabase/tests/rls_users_select.sql
```

## Nyttige kommandoer

```bash
# Start Supabase
supabase start

# Stopp Supabase
supabase stop

# Se status
supabase status

# Nullstill database
supabase db reset

# Opprett ny migrasjon
supabase migration new <name>

# Åpne Studio i nettleser
supabase studio

# Se logs
supabase logs
```

## Row Level Security (RLS)

Prosjektet bruker RLS for å sikre at brukere bare kan se og endre sine egne data.

### Users-tabell

- **Policy**: "Users can select their own data"
- **Regel**: Brukere kan bare SELECT rader hvor `auth.uid() = id`

Se `supabase/migrations/20251001055804_create_users_table.sql` for detaljer.

