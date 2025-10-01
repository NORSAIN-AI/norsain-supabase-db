-- Aktiver nødvendige extensions (fra 0000)
create extension if not exists "vector";
create extension if not exists "pgcrypto"; -- for gen_random_uuid() hvis ikke default
create extension if not exists "pg_trgm"; -- for trigram indekser senere

-- Organisasjon for multi-tenancy (fra 0000)
create table if not exists public.org (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz default now()
);

-- Vector collections for grouping knowledge (fra 0000)
create table if not exists public.vector_collection (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.org(id) on delete cascade,
  name text not null,
  description text,
  created_at timestamptz default now(),
  unique(org_id, name)
);

-- Agenter og modeller (forbedret med org_id og RLS)
create table if not exists public.agent (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.org(id) on delete cascade,
  code text not null unique, -- f.eks "qsafe", "retriever-01"
  name text not null,
  description text,
  owner text, -- team/org internt
  created_at timestamptz default now()
);

create table if not exists public.model (
  id uuid primary key default gen_random_uuid(),
  provider text not null, -- "openai", "anthropic", "vertex"
  name text not null, -- "gpt-4o-mini", "claude-3.5-sonnet"
  context_window int,
  pricing_input_usd numeric(12,6),
  pricing_output_usd numeric(12,6),
  unique(provider, name)
);

-- Kunnskapsobjekter (forbedret med collection_id, checksum for idempotens, og language for tsvector)
create table if not exists public.knowledge_item (
  id uuid primary key default gen_random_uuid(),
  collection_id uuid not null references public.vector_collection(id) on delete cascade,
  source_type text not null check (source_type in ('url', 'file', 'note', 'api')), -- enum-lignende
  source_ref text, -- URL eller filsti
  title text,
  content text, -- råtekst (valgfritt hvis i Storage)
  checksum text, -- MD5/SHA for dedup
  embedding vector(1536), -- tilpass dim, f.eks OpenAI
  tags text[],
  language text default 'english', -- f.eks 'norwegian' for bedre tsvector
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- Interaksjoner (forbedret med org_id, bedre param-logging i meta, og stop som text[])
create table if not exists public.interaction (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.org(id) on delete cascade,
  agent_id uuid references public.agent(id) on delete set null,
  model_id uuid references public.model(id) on delete set null,
  -- Parametre (logges også i meta for repro)
  temperature numeric(4,3),
  top_p numeric(4,3),
  top_k int,
  max_tokens int,
  stop text[], -- array for multiple stops
  system_prompt text,
  -- Telemetri
  started_at timestamptz default now(),
  finished_at timestamptz,
  latency_ms int,
  input_tokens int,
  output_tokens int,
  cost_usd numeric(12,6),
  status text check (status in ('ok', 'error', 'timeout', 'blocked')),
  -- Hashes
  input_hash text,
  output_hash text,
  -- Frikobling
  correlation_id text,
  meta jsonb default '{}'::jsonb -- logg ekstra params som alpha, lambda, topk, metric her
);

-- Meldinger (uendret, men med index senere)
create table if not exists public.message (
  id uuid primary key default gen_random_uuid(),
  interaction_id uuid not null references public.interaction(id) on delete cascade,
  role text not null check (role in ('system', 'user', 'assistant', 'tool')),
  content text,
  tool_name text,
  tokens int,
  created_at timestamptz default now()
);

-- Kobling kunnskap (uendret)
create table if not exists public.interaction_knowledge (
  interaction_id uuid references public.interaction(id) on delete cascade,
  knowledge_id uuid references public.knowledge_item(id) on delete cascade,
  rank int, -- rekkefølge/relevance
  score numeric(8,4), -- likhet/poeng
  primary key (interaction_id, knowledge_id)
);

-- Evalueringer (forbedret med org_id for RLS)
create table if not exists public.evaluation (
  id uuid primary key default gen_random_uuid(),
  interaction_id uuid not null references public.interaction(id) on delete cascade,
  criterion text not null, -- "helpfulness","groundedness","safety"
  score numeric(4,2) check (score between 0 and 10), -- standardiser skala
  notes text,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- RLS policies (fra 0001, for multi-tenancy basert på org via auth)
alter table public.org enable row level security;
create policy "org_rls" on public.org
  using (auth.uid() is not null); -- tilpass til din auth-logikk, f.eks via org_members tabell

alter table public.vector_collection enable row level security;
create policy "collection_rls" on public.vector_collection
  using (org_id in (select org_id from public.org_members where user_id = auth.uid())); -- antar org_members tabell

-- Lignende for agent, knowledge_item, interaction, evaluation (tilpass)
alter table public.agent enable row level security;
create policy "agent_rls" on public.agent using (org_id in (...)); -- etc.

-- Indekser (fra 0002)
create index if not exists idx_agent_org on public.agent(org_id);
create index if not exists idx_knowledge_collection on public.knowledge_item(collection_id);
create index if not exists idx_knowledge_checksum on public.knowledge_item(checksum);
create index if not exists idx_knowledge_tsv on public.knowledge_item using gin(to_tsvector('norwegian', content)) where language = 'norwegian'; -- trigram/fts
create index if not exists idx_knowledge_trgm on public.knowledge_item using gin(content gin_trgm_ops);
create index if not exists idx_knowledge_embedding on public.knowledge_item using hnsw(embedding vector_cosine_ops); -- HNSW aktiv, kommenter IVFFlat hvis fallback: using ivfflat(embedding vector_cosine_ops) with (lists = 100);

create index if not exists idx_interaction_org on public.interaction(org_id);
create index if not exists idx_interaction_started on public.interaction(started_at desc);
create index if not exists idx_message_interaction on public.message(interaction_id);

-- Views (fra 0003, eksempel)
create or replace view public.v_usage_daily as
select org_id, date_trunc('day', started_at) as day, sum(input_tokens + output_tokens) as total_tokens
from public.interaction group by org_id, day;

-- Triggers (fra 0004, eksempel for latency/cost)
create or replace function trg_update_latency() returns trigger as $$
begin
  new.latency_ms = extract(epoch from (new.finished_at - new.started_at)) * 1000;
  -- cost calc: new.cost_usd = (input * pricing_input + output * pricing_output) from model
  return new;
end;
$$ language plpgsql;

create trigger update_latency before update on public.interaction
for each row when (old.finished_at is null and new.finished_at is not null)
execute procedure trg_update_latency();

-- Funksjoner (fra 0005, eksempel fn_ingest_knowledge)
create or replace function public.fn_ingest_knowledge(
  p_collection_id uuid, p_source_type text, p_source_ref text, p_title text, p_content text,
  p_embedding vector(1536), p_tags text[], p_language text default 'english'
) returns uuid as $$
declare
  v_checksum text := md5(p_content);
  v_id uuid;
begin
  select id into v_id from public.knowledge_item where checksum = v_checksum and collection_id = p_collection_id;
  if v_id is not null then return v_id; end if; -- idempotens
  insert into public.knowledge_item (collection_id, source_type, source_ref, title, content, checksum, embedding, tags, language, created_by)
  values (p_collection_id, p_source_type, p_source_ref, p_title, p_content, v_checksum, p_embedding, p_tags, p_language, auth.uid())
  returning id into v_id;
  return v_id;
end;
$$ language plpgsql security definer;

-- Lignende for fn_hybrid_search, etc. (utvid som tidligere definert)

-- Seeds (dev_seed.sql eksempel)
insert into public.org (name) values ('NORSAIN') on conflict do nothing;
insert into public.vector_collection (org_id, name) values ((select id from public.org where name='NORSAIN'), 'qsafe_policies');
insert into public.vector_collection (org_id, name) values ((select id from public.org where name='NORSAIN'), 'retrieval_docs');
insert into public.agent (org_id, code, name) values ((select id from public.org where name='NORSAIN'), 'qsafe', 'QSafe Agent');
insert into public.model (provider, name) values ('openai', 'gpt-4o-mini');
-- Test knowledge
select public.fn_ingest_knowledge(
  (select id from public.vector_collection where name='qsafe_policies'),
  'note', null, 'Test Policy', 'Dette er en norsk testpolicy.', null, array['test'], 'norwegian'
);
