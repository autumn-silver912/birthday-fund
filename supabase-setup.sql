-- One-owner birthday gift page: shared public data with one authenticated admin.
-- Run this once in Supabase Dashboard > SQL Editor after creating the project.

create table if not exists public.birthday_site (
  id text primary key check (id = 'main'),
  settings jsonb not null default '{"person":"소중한 너","birthday":"","wishes":[],"account":"","kakao":""}'::jsonb,
  donations jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

insert into public.birthday_site (id) values ('main') on conflict (id) do nothing;

alter table public.birthday_site enable row level security;
grant select on public.birthday_site to anon, authenticated;
grant update on public.birthday_site to authenticated;

drop policy if exists "Anyone can view birthday page data" on public.birthday_site;
create policy "Anyone can view birthday page data"
  on public.birthday_site for select to anon, authenticated using (true);

drop policy if exists "Birthday owner can update page data" on public.birthday_site;
create policy "Birthday owner can update page data"
  on public.birthday_site for update to authenticated
  using ((auth.jwt() ->> 'email') = 'dms1577@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'dms1577@gmail.com');

create table if not exists public.birthday_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 20),
  message text not null check (
    char_length(trim(message)) between 5 and 180
    and message !~* '(https?://|www\.)'
  ),
  created_at timestamptz not null default now()
);

alter table public.birthday_messages enable row level security;
grant select, insert on public.birthday_messages to anon, authenticated;
grant delete on public.birthday_messages to authenticated;

drop policy if exists "Anyone can read birthday messages" on public.birthday_messages;
create policy "Anyone can read birthday messages"
  on public.birthday_messages for select to anon, authenticated using (true);

drop policy if exists "Anyone can leave a birthday message" on public.birthday_messages;
create policy "Anyone can leave a birthday message"
  on public.birthday_messages for insert to anon, authenticated with check (true);

drop policy if exists "Birthday owner can delete birthday messages" on public.birthday_messages;
create policy "Birthday owner can delete birthday messages"
  on public.birthday_messages for delete to authenticated
  using ((auth.jwt() ->> 'email') = 'dms1577@gmail.com');

-- Private depositor registry for accurate repeat-supporter counts.
-- Depositor identities are stored separately from the public donation JSON.
create table if not exists public.birthday_supporters (
  id uuid primary key default gen_random_uuid(),
  name_key text not null unique,
  created_at timestamptz not null default now()
);

alter table public.birthday_supporters enable row level security;
grant select, insert on public.birthday_supporters to authenticated;

drop policy if exists "Birthday owner can view supporter identities" on public.birthday_supporters;
create policy "Birthday owner can view supporter identities"
  on public.birthday_supporters for select to authenticated
  using ((auth.jwt() ->> 'email') = 'dms1577@gmail.com');

drop policy if exists "Birthday owner can add supporter identities" on public.birthday_supporters;
create policy "Birthday owner can add supporter identities"
  on public.birthday_supporters for insert to authenticated
  with check ((auth.jwt() ->> 'email') = 'dms1577@gmail.com');
