-- Idempotent referansedata (trygg i alle miljø)
insert into public.status_codes(code, description) values
 ('OPEN','Open case'),
 ('CLOSED','Closed case'),
 ('PENDING','Pending review')
on conflict (code) do nothing;
