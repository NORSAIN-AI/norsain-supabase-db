-- Triggers for automatisk oppdatering og logging (til 0005_triggers.sql)
-- Disse triggers kjøres på insert/update for å beregne latency, cost, hashes, og audit-logg.
-- Forbedringer: Lagt til cost-calc basert på model.pricing, input/output-hash med MD5, 
-- audit-trigger for endringslogg (i egen tabell), og validering av params (f.eks. temperature mellom 0-1).
-- Kjør etter 0001 for å ha tabellene klare. Test med INSERT/UPDATE på interaction.

-- Funksjon for å beregne latency og cost på interaction-update
create or replace function trg_update_interaction() returns trigger as $$
declare
  v_pricing_input numeric(12,6);
  v_pricing_output numeric(12,6);
begin
  -- Beregn latency hvis finished_at settes
  if new.finished_at is not null and old.finished_at is null then
    new.latency_ms = extract(epoch from (new.finished_at - new.started_at)) * 1000;
  end if;

  -- Beregn cost basert på model (hent pricing)
  if new.input_tokens is not null and new.output_tokens is not null and new.model_id is not null then
    select pricing_input_usd, pricing_output_usd into v_pricing_input, v_pricing_output
    from public.model where id = new.model_id;
    new.cost_usd = (new.input_tokens * v_pricing_input) + (new.output_tokens * v_pricing_output);
  end if;

  -- Generer hashes for dedup/trace (MD5 på content)
  if new.input_hash is null then
    new.input_hash = md5(coalesce(new.system_prompt, '') || coalesce((select string_agg(content, '') from public.message where interaction_id = new.id and role = 'user'), ''));
  end if;
  if new.output_hash is null then
    new.output_hash = md5(coalesce((select string_agg(content, '') from public.message where interaction_id = new.id and role = 'assistant'), ''));
  end if;

  -- Valider params (kast feil hvis ugyldig)
  if new.temperature is not null and (new.temperature < 0 or new.temperature > 1) then
    raise exception 'Temperature must be between 0 and 1';
  end if;
  -- Legg til flere valideringer for top_p, etc. hvis needed

  return new;
end;
$$ language plpgsql;

-- Koble trigger til interaction (før update, når finished_at settes)
create trigger update_interaction_trigger
before update on public.interaction
for each row
execute function trg_update_interaction();

-- Audit-trigger for endringslogg (lag en audit-tabell først)
create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  operation text not null,  -- INSERT/UPDATE/DELETE
  row_id uuid not null,
  old_data jsonb,
  new_data jsonb,
  changed_by uuid default auth.uid(),
  changed_at timestamptz default now()
);

create or replace function trg_audit_log() returns trigger as $$
begin
  if (tg_op = 'DELETE') then
    insert into public.audit_log (table_name, operation, row_id, old_data)
    values (tg_relname, tg_op, old.id, row_to_json(old));
  elsif (tg_op = 'UPDATE') then
    insert into public.audit_log (table_name, operation, row_id, old_data, new_data)
    values (tg_relname, tg_op, new.id, row_to_json(old), row_to_json(new));
  elsif (tg_op = 'INSERT') then
    insert into public.audit_log (table_name, operation, row_id, new_data)
    values (tg_relname, tg_op, new.id, row_to_json(new));
  end if;
  return null;  -- For after-triggers
end;
$$ language plpgsql;

-- Koble audit til nøkkeltabeller (f.eks. interaction, knowledge_item)
create trigger audit_interaction
after insert or update or delete on public.interaction
for each row execute function trg_audit_log();

create trigger audit_knowledge
after insert or update or delete on public.knowledge_item
for each row execute function trg_audit_log();

-- Valgfri: Trigger for auto-update created_at/updated_at (hvis du legger til updated_at-felt)
alter table public.interaction add column if not exists updated_at timestamptz default now();
create or replace function trg_update_timestamp() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_timestamp_interaction
before update on public.interaction
for each row execute function trg_update_timestamp();
