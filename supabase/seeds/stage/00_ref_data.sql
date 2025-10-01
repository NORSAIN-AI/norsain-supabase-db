-- Kun referansedata i stage
insert into public.status_codes(code, description) values
 ('OPEN','Open case'),
 ('CLOSED','Closed case'),
 ('PENDING','Pending review')
on conflict (code) do nothing;
