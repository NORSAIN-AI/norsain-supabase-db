alter table public.event_outbox enable row level security;

-- Ingen default-tilgang; MCP-service må bruke service_role / dedikert rolle i API-lag.
revoke all on public.event_outbox from anon, authenticated;

-- (Valgfritt) opprett en dedikert rolle som kun får select/update på outbox via RPC
-- create role mcp_puller;
-- grant select, update on public.event_outbox to mcp_puller;
