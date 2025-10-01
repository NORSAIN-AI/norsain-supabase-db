-- 0001_tables_rls.sql: Definer core-tabeller for MAS, inkl. multi-tenancy og RLS.
-- Beste praksis 2025: Bruk uuid for IDs, JSONB for fleksible params, og RLS for org-basert access. Inkluder org_id overalt for skalerbarhet i stor MAS.

-- Organisasjon for multi-tenancy
create table if not exists public.org (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz default now()
);

-- Agenter i MAS (mange agenter støttes via code/role)
create table if not exists public.agent (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.org(id) on delete cascade,
  code text not null unique, -- Unik identifikator, f.eks. 'knowledge-retriever-01'
  name text not null,
  role text not null, -- F.eks. 'retriever', 'logger', 'evaluator'
  description text,
  llm_model text, -- F.eks. 'grok-4'
  created_at timestamptz default now()
);

-- Kunnskapsobjekter med embeddings
create table if not exists public.knowledge_item (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.org(id) on delete cascade,
  source_type text not null check (source_type in ('url', 'file', 'note', 'api')),
  source_ref text,
  title text,
  content text,
  embedding vector(768), -- Optimal dimensjon for ytelse i 2025 (tilpass etter modell)
  checksum text, -- MD5 for idempotens
  tags text[],
  language text default 'english',
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

-- Sessions for agent-samarbeid i MAS
create table if not exists public.session (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.org(id) on delete cascade,
  name text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Interaksjoner for logging input/output
create table if not exists public.interaction (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.org(id) on delete cascade,
  session_id uuid references public.session(id) on delete set null,
  agent_id uuid references public.agent(id) on delete set null,
  input text,
  output text,
  tokens_in int,
  tokens_out int,
  total_tokens int,
  temperature numeric(4,3),
  top_p numeric(4,3),
  latency_ms int,
  cost_usd numeric(12,6),
  status text check (status in ('ok', 'error', 'timeout', 'blocked')),
  input_hash text,
  output_hash text,
  meta jsonb default '{}'::jsonb, -- Ekstra params som top_k, alpha, lambda
  created_at timestamptz default now()
);

-- Meldinger i samtaler
create table if not exists public.conversation_messages (
  id uuid primary key default gen_random_uuid(),
  interaction_id uuid not null references public.interaction(id) on delete cascade,
  role text not null check (role in ('system', 'user', 'assistant', 'tool')),
  content text,
  created_at timestamptz default now()
);

-- Audit-log for compliance
create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  operation text not null,
  row_id uuid not null,
  old_data jsonb,
  new_data jsonb,
  changed_by uuid default auth.uid(),
  changed_at timestamptz default now()
);

-- RLS policies (tilpass til din auth-setup, f.eks. via org_members-tabell)
alter table public.org enable row level security;
create policy "org_rls" on public.org using (true); -- Eksempel; tilpass til auth.uid()

alter table public.agent enable row level security;
create policy "agent_rls" on public.agent using (org_id in (select org_id from org_members where user_id = auth.uid()));

-- Lignende for andre tabeller...
alter table public.knowledge_item enable row level security;
create policy "knowledge_rls" on public.knowledge_item using (org_id in (select org_id from org_members where user_id = auth.uid()));

alter table public.session enable row level security;
create policy "session_rls" on public.session using (org_id in (select org_id from org_members where user_id = auth.uid()));

alter table public.interaction enable row level security;
create policy "interaction_rls" on public.interaction using (org_id in (select org_id from org_members where user_id = auth.uid()));

alter table public.conversation_messages enable row level security;
create policy "messages_rls" on public.conversation_messages using (true); -- Tilpass

alter table public.audit_log enable row level security;
create policy "audit_rls" on public.audit_log using (true); -- Begrens til admins
