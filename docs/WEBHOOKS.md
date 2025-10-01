# WEBHOOKS via OUTBOX
- Tabell: public.event_outbox (pending|delivered|failed)
- Trigger-eksempel på docs.insert → outbox
- MCP leser pending events (poll/RPC), leverer, oppdaterer status
- Fordel: robust, auditable, enkel å teste lokalt
