# Step 1: Supabase database setup (Flashcard Links)

This sets up the database before any app code is built. It goes in the **same Supabase project** as the notes app and the Artifact Library, so the same login works. It uses a **new table, `flashcard_links`**, so this list never mixes with the Artifact Library's `links` table.

It creates:
- the `flashcard_links` table (link, name, Added date, last-changed time, deleted flag)
- row security: you can only see and change your own rows
- no hard deletes: the database doesn't allow rows to be removed at all. Deleting a link just sets `deleted = true`.
- the lock on the Added date (`created_at`), so it can never change after a link is added

No screenshots, so there's no `preview_path` column, no storage bucket and no Edge Function.

It's safe to run more than once.

## The SQL

```sql
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
```

## What to do in the Supabase dashboard

1. Go to https://supabase.com/dashboard and open your project (the same one as the notes app and Artifact Library).
2. In the left sidebar, click **SQL Editor**.
3. Click **+ New query** so you start with an empty box.
4. Paste the SQL above (everything between the ```sql and ``` lines, not those lines themselves).
5. Click **Run** (bottom-right), or press **Ctrl+Enter**.
6. You should see **"Success. No rows returned"**.
   - If Supabase shows a pop-up warning about "destructive operations" (because of the `drop` and `revoke` lines), that's expected. They only affect this new table. Click **Run this query**.
7. Check: in the left sidebar click **Table Editor**. `flashcard_links` should be in the list, empty, with a green or grey **RLS enabled** label (not a red "RLS disabled" warning).
8. Check: in the left sidebar go to **Database → Triggers**. `flashcard_links_keep_created_at` should be listed.

Your Artifact Library's `links` table is not touched.

## Next step
Build the app from the copied files and mockup_v2.html.
