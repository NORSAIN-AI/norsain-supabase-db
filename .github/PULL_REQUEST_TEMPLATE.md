## Hva
Kort beskrivelse av endringen.

## Sjekkliste
- [ ] SQL følger timestamp-navn (YYYYMMDDHHMMSS_beskrivelse.sql)
- [ ] Forward-only (ingen historical edits)
- [ ] RLS vurdert/testet (dersom relevant)
- [ ] Seeds er idempotente og riktig miljø (prod = kun referansedata)
- [ ] Ingen secrets i diff

## Test
- [ ] Lokalt: `supabase db reset`
- [ ] (Valgfritt) `EXPLAIN` på hot queries

### Kontakt
hs@norsain.com
