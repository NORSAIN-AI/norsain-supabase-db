-- Dev-dummybruker
insert into public.users (id, email)
values ('00000000-0000-0000-0000-000000000001','dev@norsain.com')
on conflict (email) do nothing;
