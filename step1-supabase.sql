-- 1) The table
create table if not exists public.flashcard_links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  url text not null,
  title text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted boolean not null default false
);

-- 2) Indexes for fast lookups (by user, and by link for duplicate checks)
create index if not exists flashcard_links_user_updated_idx
  on public.flashcard_links (user_id, updated_at desc);
create index if not exists flashcard_links_user_url_idx
  on public.flashcard_links (user_id, url);

-- 3) Row security: each person only sees and changes their own rows
alter table public.flashcard_links enable row level security;

drop policy if exists "Flashcard links viewable by owner" on public.flashcard_links;
create policy "Flashcard links viewable by owner"
  on public.flashcard_links for select
  using (auth.uid() = user_id);

drop policy if exists "Flashcard links insertable by owner" on public.flashcard_links;
create policy "Flashcard links insertable by owner"
  on public.flashcard_links for insert
  with check (auth.uid() = user_id);

drop policy if exists "Flashcard links updatable by owner" on public.flashcard_links;
create policy "Flashcard links updatable by owner"
  on public.flashcard_links for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- No delete policy on purpose: rows are never really deleted, only marked deleted = true.

-- 4) Permissions for logged-in users (read, add, change; no delete)
revoke all on public.flashcard_links from anon;
revoke all on public.flashcard_links from authenticated;
grant select, insert, update on public.flashcard_links to authenticated;

-- 5) Lock the "Added" date: on any update, created_at is put back to its original value
create or replace function public.flashcard_links_keep_created_at()
returns trigger
language plpgsql
as $$
begin
  new.created_at := old.created_at;
  return new;
end;
$$;

drop trigger if exists flashcard_links_keep_created_at on public.flashcard_links;
create trigger flashcard_links_keep_created_at
  before update on public.flashcard_links
  for each row
  execute function public.flashcard_links_keep_created_at();
