-- 0006_webhooks.sql: Støtte for webhook-logging og triggers.
-- Beste praksis 2025: Logg alle webhook-relaterte hendelser for audit, og bruk triggers for å forberede payloads hvis needed.

-- Tabell for å logge webhook-kall (inn/ut)
create table if not exists public.webhook_log (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.org(id) on delete cascade,
  event_type text not null,  -- f.eks. 'insert_interaction', 'crew_kickoff'
  payload jsonb,  -- Sendt/mottatt data
  status text check (status in ('sent', 'received', 'error')),  -- Status for kall
  error_message text,
  created_at timestamptz default now()
);

-- RLS for webhook_log
alter table public.webhook_log enable row level security;
create policy "webhook_log_rls" on public.webhook_log using (org_id in (select org_id from org_members where user_id = auth.uid()));

-- Trigger-eksempel: Logg automatisk på INSERT i interaction (kan utvides til andre tabeller)
create or replace function trg_log_webhook() returns trigger as $$
begin
  insert into public.webhook_log (org_id, event_type, payload, status)
  values (new.org_id, 'insert_interaction', row_to_json(new), 'sent');  -- 'sent' hvis webhook trigges
  return new;
end;
$$ language plpgsql;

create trigger log_webhook_interaction
after insert on public.interaction
for each row execute function trg_log_webhook();

-- Lignende for knowledge_item hvis relevant
create trigger log_webhook_knowledge
after insert on public.knowledge_item
for each row execute function trg_log_webhook();
