create table public.sync_deletions (
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null check (entity_type in ('task_list','task','subtask','reminder')),
  entity_id text not null,
  deleted_at timestamptz not null default now(),
  primary key (user_id, entity_type, entity_id)
);

create index sync_deletions_user_deleted_idx
on public.sync_deletions(user_id, deleted_at);

alter table public.sync_deletions enable row level security;

revoke all on public.sync_deletions from anon;
grant select, insert, update, delete on public.sync_deletions to authenticated;

create policy "sync_deletions_select_own"
on public.sync_deletions for select to authenticated
using ((select auth.uid()) = user_id);

create policy "sync_deletions_insert_own"
on public.sync_deletions for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "sync_deletions_update_own"
on public.sync_deletions for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "sync_deletions_delete_own"
on public.sync_deletions for delete to authenticated
using ((select auth.uid()) = user_id);
