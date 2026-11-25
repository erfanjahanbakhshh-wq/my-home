-- Hamkhaneh / Supabase PostgreSQL. Apply with Supabase SQL editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default '', created_at timestamptz not null default now());
create table if not exists public.homes (
 id uuid primary key default gen_random_uuid(), name text not null,
 owner_id uuid not null references public.profiles(id), created_at timestamptz not null default now());
create table if not exists public.home_members (
 home_id uuid not null references public.homes(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade,
 role text not null default 'member' check(role in ('owner','member')),
 joined_at timestamptz not null default now(), primary key(home_id,user_id));
create table if not exists public.invite_codes (
 id uuid primary key default gen_random_uuid(), home_id uuid not null references public.homes(id) on delete cascade,
 code_hash text not null unique, expires_at timestamptz not null, used_at timestamptz,
 used_by uuid references public.profiles(id), created_by uuid not null references public.profiles(id), created_at timestamptz not null default now());
create table if not exists public.tasks (
 id uuid primary key default gen_random_uuid(), home_id uuid not null references public.homes(id) on delete cascade,
 title text not null, notes text not null default '', assignee_id uuid references public.profiles(id), due_at timestamptz,
 category text not null default 'خانه', priority text not null default 'معمولی', status text not null default 'open' check(status in ('open','done','cancelled')),
 created_by uuid not null references public.profiles(id), created_at timestamptz not null default now());
create table if not exists public.shopping_lists (
 id uuid primary key default gen_random_uuid(), home_id uuid not null references public.homes(id) on delete cascade,
 title text not null default 'خرید ماهانه', month_start date not null, created_by uuid not null references public.profiles(id), created_at timestamptz not null default now());
create table if not exists public.shopping_items (
 id uuid primary key default gen_random_uuid(), home_id uuid not null references public.homes(id) on delete cascade,
 list_id uuid references public.shopping_lists(id) on delete cascade, name text not null, quantity text not null default '',
 estimated_price numeric(12,2) not null default 0 check(estimated_price>=0), actual_price numeric(12,2) check(actual_price>=0), purchased boolean not null default false,
 created_by uuid not null references public.profiles(id), created_at timestamptz not null default now());
create table if not exists public.receipts (
 id uuid primary key default gen_random_uuid(), home_id uuid not null references public.homes(id) on delete cascade,
 storage_path text not null, amount numeric(12,2), purchased_at date not null default current_date,
 uploaded_by uuid not null references public.profiles(id), created_at timestamptz not null default now());
create table if not exists public.dashboard_widgets (
 id uuid primary key default gen_random_uuid(), home_id uuid not null references public.homes(id) on delete cascade,
 widget_key text not null, enabled boolean not null default true, position integer not null default 0,
 settings jsonb not null default '{}'::jsonb, unique(home_id,widget_key));
create index if not exists home_members_user_idx on public.home_members(user_id);
create index if not exists tasks_home_due_idx on public.tasks(home_id,due_at);
create index if not exists shopping_items_home_idx on public.shopping_items(home_id);
create index if not exists shopping_lists_home_month_idx on public.shopping_lists(home_id,month_start);
create index if not exists receipts_home_date_idx on public.receipts(home_id,purchased_at);
create index if not exists invites_home_expiry_idx on public.invite_codes(home_id,expires_at) where used_at is null;
create or replace function public.is_home_member(hid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.home_members m where m.home_id=hid and m.user_id=auth.uid()) $$;
create or replace function public.is_home_owner(hid uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.home_members m where m.home_id=hid and m.user_id=auth.uid() and m.role='owner') $$;
revoke all on function public.is_home_member(uuid) from public;
revoke all on function public.is_home_owner(uuid) from public;
grant execute on function public.is_home_member(uuid) to authenticated;
grant execute on function public.is_home_owner(uuid) to authenticated;
-- Profiles: self-managed; household membership is private to its members.
alter table public.profiles enable row level security;
create policy profiles_read_self_or_peer on public.profiles for select to authenticated using (id=auth.uid() or exists(select 1 from public.home_members mine join public.home_members peer on peer.home_id=mine.home_id where mine.user_id=auth.uid() and peer.user_id=profiles.id));
create policy profiles_update_self on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy profiles_insert_self on public.profiles for insert to authenticated with check(id=auth.uid());
alter table public.homes enable row level security;
create policy homes_member_read on public.homes for select to authenticated using(public.is_home_member(id));
create policy homes_owner_update on public.homes for update to authenticated using(public.is_home_owner(id)) with check(public.is_home_owner(id));
create policy homes_authenticated_create on public.homes for insert to authenticated with check(owner_id=auth.uid());
alter table public.home_members enable row level security;
create policy members_read_home on public.home_members for select to authenticated using(public.is_home_member(home_id));
create policy members_owner_manage on public.home_members for all to authenticated using(public.is_home_owner(home_id)) with check(public.is_home_owner(home_id));
-- Scoped household rows: members read/write; owner-only destructive/admin control must be enforced for membership/invites.
alter table public.tasks enable row level security;
create policy tasks_member_all on public.tasks for all to authenticated using(public.is_home_member(home_id)) with check(public.is_home_member(home_id));
alter table public.shopping_lists enable row level security;
create policy shopping_lists_member_all on public.shopping_lists for all to authenticated using(public.is_home_member(home_id)) with check(public.is_home_member(home_id));
alter table public.shopping_items enable row level security;
create policy shopping_items_member_all on public.shopping_items for all to authenticated using(public.is_home_member(home_id)) with check(public.is_home_member(home_id));
alter table public.receipts enable row level security;
create policy receipts_member_all on public.receipts for all to authenticated using(public.is_home_member(home_id)) with check(public.is_home_member(home_id));
alter table public.dashboard_widgets enable row level security;
create policy dashboard_widgets_member_all on public.dashboard_widgets for all to authenticated using(public.is_home_member(home_id)) with check(public.is_home_member(home_id));
alter table public.invite_codes enable row level security;
create policy invite_owner_select on public.invite_codes for select to authenticated using(public.is_home_owner(home_id));
create policy invite_owner_create on public.invite_codes for insert to authenticated with check(public.is_home_owner(home_id) and created_by=auth.uid());
create policy invite_owner_revoke on public.invite_codes for delete to authenticated using(public.is_home_owner(home_id));
-- Secure invite redemption: implement a SECURITY DEFINER RPC that atomically locks one
-- unexpired unused code, verifies crypt(code,salt) server-side, adds auth.uid() as member,
-- and stamps used_at/used_by in one transaction. Never expose raw codes or permit client
-- updates to used_at; do not let ordinary members read invite rows. Hash codes with a
-- server-held secret, rate-limit redemption, and expire short-lived single-use codes.
-- For receipt images use a private Storage bucket; object paths must be homes/<home_uuid>/...
-- and Storage RLS must verify the uuid segment against home_members. Never make receipts public.
