-- 0003_views.sql: Analytiske views for logging og innsikt.
-- Beste praksis 2025: Bruk views for real-time analytics uten materialisering, join for lesbarhet, og begrens data for ytelse.

create or replace view public.v_usage_daily as
select
  o.name as org_name,
  date_trunc('day', i.created_at) as day,
  i.agent_id,
  a.name as agent_name,
  count(*) as calls,
  sum(i.total_tokens) as total_tokens,
  sum(i.cost_usd) as total_cost,
  avg(i.latency_ms) as avg_latency,
  sum(case when i.status = 'error' then 1 else 0 end)::float / count(*) as error_rate
from public.interaction i
join public.org o on i.org_id = o.id
left join public.agent a on i.agent_id = a.id
where i.created_at >= now() - interval '30 days'
group by o.name, day, i.agent_id, a.name
order by day desc;

create or replace view public.v_param_effects as
select
  o.name as org_name,
  i.agent_id,
  a.name as agent_name,
  width_bucket(coalesce(i.temperature, 0.0), 0.0, 1.0, 5) as temp_bucket,
  width_bucket(coalesce(i.top_p, 0.0), 0.0, 1.0, 5) as top_p_bucket,
  avg(i.total_tokens) as avg_tokens,
  avg(i.latency_ms) as avg_latency,
  count(*) as count
from public.interaction i
join public.org o on i.org_id = o.id
left join public.agent a on i.agent_id = a.id
where i.created_at >= now() - interval '90 days'
group by o.name, i.agent_id, a.name, temp_bucket, top_p_bucket
order by i.agent_id, temp_bucket;

create or replace view public.v_knowledge_usage as
select
  k.org_id,
  count(*) as item_count,
  sum(case when k.embedding is not null then 1 else 0 end) as embedded_count,
  avg(array_length(k.tags, 1)) as avg_tags
from public.knowledge_item k
group by k.org_id;
