-- Relasjonelle indekser (for joins og filtrering)
create index if not exists idx_agent_org on public.agent (org_id); -- For multi-tenancy filtrering på org
create index if not exists idx_vector_collection_org on public.vector_collection (org_id); -- Samme for collections
create index if not exists idx_knowledge_collection on public.knowledge_item (collection_id); -- Hyppig join på collection
create index if not exists idx_knowledge_created_by on public.knowledge_item (created_by); -- Filtrering på bruker
create index if not exists idx_interaction_org on public.interaction (org_id); -- Kritisk for multi-tenancy
create index if not exists idx_interaction_agent on public.interaction (agent_id, started_at desc); -- Queries etter agent + tidssortering
create index if not exists idx_interaction_model on public.interaction (model_id, started_at desc); -- Lignende for model
create index if not exists idx_interaction_started_at on public.interaction (started_at desc); -- Tidsbaserte queries (f.eks. siste interaksjoner)
create index if not exists idx_interaction_status on public.interaction (status); -- Filtrering på status (ok/error etc.)
create index if not exists idx_message_interaction on public.message (interaction_id); -- Join på interaction
create index if not exists idx_message_interaction_role on public.message (interaction_id, role); -- Filtrering på role innen interaction (f.eks. bare 'assistant')
create index if not exists idx_interaction_knowledge_interaction on public.interaction_knowledge (interaction_id); -- For å hente knowledge per interaction
create index if not exists idx_evaluation_interaction on public.evaluation (interaction_id); -- Join på evaluation

-- GIN/Trigram/FTS indekser (for tekst- og array-søk)
create index if not exists idx_knowledge_tags on public.knowledge_item using gin (tags); -- Raskt søk i tags-array
create index if not exists idx_knowledge_checksum on public.knowledge_item (checksum); -- For idempotens i ingest (rask lookup)
create index if not exists idx_knowledge_tsv on public.knowledge_item using gin (to_tsvector(language::regconfig, coalesce(title, '') || ' ' || content)); -- FTS med dynamisk language (f.eks. 'norwegian' for bedre ranking)
create index if not exists idx_knowledge_trgm on public.knowledge_item using gin (content gin_trgm_ops); -- Fuzzy tekst-søk (trigram)
create index if not exists idx_interaction_meta on public.interaction using gin (meta); -- Hvis du logger params som JSONB (f.eks. søk på meta->>'alpha')

-- Enum-lignende indekser (for filtrering på begrensede verdier)
create index if not exists idx_knowledge_visibility on public.knowledge_item (visibility); -- Hvis visibility-felt eksisterer (f.eks. public/private)
create index if not exists idx_knowledge_source_type on public.knowledge_item (source_type); -- Filtrering på type (url/file etc.)

-- Vector indekser (for semantisk søk)
create index if not exists idx_knowledge_embedding on public.knowledge_item using ivfflat (embedding vector_cosine_ops) with (lists = 100); -- IVFFlat for små datasett; kommenter inn HNSW for bedre ytelse i prod: using hnsw (embedding vector_cosine_ops) with (m = 16, ef_construction = 64);
-- Merk: Bytt til cosine/l2/ip basert på din metric i fn_hybrid_search; kjør ANALYZE etter insert for probing.

-- Valgfri: Partiell indeks for å optimalisere (f.eks. bare indekser knowledge med embedding)
create index if not exists idx_knowledge_embedding_partial on public.knowledge_item using ivfflat (embedding vector_cosine_ops) where embedding is not null;
