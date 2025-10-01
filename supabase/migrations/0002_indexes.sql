-- 0002_indexes.sql: Opprett indekser for ytelse i stor MAS.
-- Beste praksis 2025: Bruk HNSW for vector-søk i prod, kompositt-indekser for vanlige queries, og GIN for arrays/tekst.

-- Relasjonelle indekser
create index if not exists idx_agent_org on public.agent(org_id);
create index if not exists idx_knowledge_org on public.knowledge_item(org_id);
create index if not exists idx_knowledge_checksum on public.knowledge_item(checksum);
create index if not exists idx_session_org on public.session(org_id);
create index if not exists idx_interaction_org on public.interaction(org_id);
create index if not exists idx_interaction_session on public.interaction(session_id);
create index if not exists idx_interaction_agent on public.interaction(agent_id, created_at desc);
create index if not exists idx_messages_interaction on public.conversation_messages(interaction_id);

-- Tekst- og array-indekser
create index if not exists idx_knowledge_tags on public.knowledge_item using gin(tags);
create index if not exists idx_knowledge_tsv on public.knowledge_item using gin(to_tsvector(language::regconfig, coalesce(title, '') || ' ' || content));
create index if not exists idx_knowledge_trgm on public.knowledge_item using gin(content gin_trgm_ops);
create index if not exists idx_interaction_meta on public.interaction using gin(meta);

-- Vector-indeks (HNSW for skalerbarhet i 2025)
create index if not exists idx_knowledge_embedding on public.knowledge_item using hnsw(embedding vector_cosine_ops) with (m = 16, ef_construction = 64);
-- Fallback: IVFFlat for små datasett - kommenter inn hvis needed: using ivfflat(embedding vector_cosine_ops) with (lists = 100);
