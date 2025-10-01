-- 0005_functions.sql: Funksjoner for ingest, søk og logging.
-- Beste praksis 2025: Security definer, idempotens og hybrid-søk for MAS-effektivitet.

create or replace function public.fn_ingest_knowledge(
  p_org_id uuid, p_source_type text, p_content text, p_embedding vector(768), p_tags text[], p_language text
) returns uuid as $$
declare
  v_checksum text := md5(p_content);
  v_id uuid;
begin
  select id into v_id from public.knowledge_item where checksum = v_checksum and org_id = p_org_id;
  if v_id is not null then return v_id; end if;
  insert into public.knowledge_item (org_id, source_type, content, embedding, checksum, tags, language, created_by)
  values (p_org_id, p_source_type, p_content, p_embedding, v_checksum, p_tags, p_language, auth.uid())
  returning id into v_id;
  return v_id;
end;
$$ language plpgsql security definer;

create or replace function public.fn_hybrid_search(
  p_org_id uuid, p_query_text text, p_query_vector vector(768), p_top_k int, p_alpha numeric
) returns table (id uuid, score numeric) as $$
begin
  return query
  with text_scores as (
    select id, ts_rank(to_tsvector(language::regconfig, content), websearch_to_tsquery(p_language::regconfig, p_query_text)) as text_score
    from public.knowledge_item where org_id = p_org_id
  ),
  vector_scores as (
    select id, 1 - (embedding <=> p_query_vector) as vec_score
    from public.knowledge_item where org_id = p_org_id
  )
  select t.id, (p_alpha * v.vec_score) + ((1 - p_alpha) * t.text_score) as score
  from text_scores t join vector_scores v on t.id = v.id
  order by score desc limit p_top_k;
end;
$$ language plpgsql security definer;

create or replace function public.fn_log_interaction(
  p_org_id uuid, p_session_id uuid, p_agent_id uuid, p_input text, p_output text,
  p_tokens_in int, p_tokens_out int, p_temperature numeric, p_top_p numeric, p_meta jsonb
) returns uuid as $$
declare
  v_id uuid;
begin
  insert into public.interaction (org_id, session_id, agent_id, input, output, tokens_in, tokens_out,
    temperature, top_p, meta)
  values (p_org_id, p_session_id, p_agent_id, p_input, p_output, p_tokens_in, p_tokens_out,
    p_temperature, p_top_p, p_meta)
  returning id into v_id;
  return v_id;
end;
$$ language plpgsql security definer;
