-- 0004_triggers.sql: Triggers for auto-calc og logging.
-- Beste praksis 2025: Bruk triggers for idempotens, validering og audit i stor-skala systemer.

create or replace function trg_update_interaction() returns trigger as $$
begin
  if new.total_tokens is null then
    new.total_tokens = new.tokens_in + new.tokens_out;
  end if;
  new.latency_ms = extract(epoch from (now() - new.created_at)) * 1000;
  -- Cost calc: Tilpass med model-pricing hvis integrert
  if new.temperature < 0 or new.temperature > 1 then
    raise exception 'Invalid temperature';
  end if;
  new.input_hash = md5(coalesce(new.input, ''));
  new.output_hash = md5(coalesce(new.output, ''));
  return new;
end;
$$ language plpgsql;

create trigger update_interaction
before insert or update on public.interaction
for each row execute function trg_update_interaction();

create or replace function trg_audit() returns trigger as $$
begin
  insert into public.audit_log (table_name, operation, row_id, old_data, new_data)
  values (tg_relname, tg_op, coalesce(new.id, old.id), row_to_json(old), row_to_json(new));
  return null;
end;
$$ language plpgsql;

create trigger audit_interaction
after insert or update or delete on public.interaction
for each row execute function trg_audit();

-- Lignende for knowledge_item
create trigger audit_knowledge
after insert or update or delete on public.knowledge_item
for each row execute function trg_audit();
