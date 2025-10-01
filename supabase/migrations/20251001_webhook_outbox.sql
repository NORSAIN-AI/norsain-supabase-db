-- Outbox-tabell for hendelser som MCP-serveren henter/leverer
create table if not exists public.event_outbox (
  id uuid primary key default gen_random_uuid(),
  topic text not null,                    -- f.eks. 'user.created'
  payload jsonb not null,                 -- hendelsesinnhold
  created_at timestamptz not null default now(),
  status text not null default 'pending', -- pending|delivered|failed
  attempts int not null default 0
);

-- Eksempel på “kildetabell” som utløser hendelse (erstatt med deres)
create table if not exists public.docs (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  created_by uuid,
  created_at timestamptz not null default now()
);

-- Trigger: ved ny doc → legg en rad i outbox
create or replace function public.docs_after_insert_outbox()
returns trigger language plpgsql as $$
begin
  insert into public.event_outbox(topic, payload)
  values ('doc.created', jsonb_build_object('id', new.id, 'created_by', new.created_by));
  return new;
end;
$$;

drop trigger if exists trg_docs_after_insert_outbox on public.docs;
create trigger trg_docs_after_insert_outbox
after insert on public.docs
for each row execute function public.docs_after_insert_outbox();
