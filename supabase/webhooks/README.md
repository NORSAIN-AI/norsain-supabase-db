# Webhooks (DB → MCP)

Vi bruker et **outbox-mønster**:
1) Triggere skriver hendelser til `public.event_outbox`.
2) MCP-server (eller en liten “webhook gateway”) henter pending events og leverer dem
   til riktig MCP endepunkt/webhook.
3) Etter vellykket levering markeres event som `delivered` (eller `failed` + `attempts+1`).

Fordeler:
- Null-låsing, null “HTTP i transaksjon”.
- Robust ved nedetid (retry på pending).
- Klar audit.

**Kontraktseksempel:** `examples/event_contract_example.json`
