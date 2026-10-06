create table if not exists public.task_attachments (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  task_id text not null,
  name text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes >= 0 and size_bytes <= 15728640),
  storage_path text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  constraint task_attachments_task_fk
    foreign key (user_id, task_id)
    references public.tasks(user_id, id)
    on delete cascade
);

create index if not exists task_attachments_user_task_idx
  on public.task_attachments(user_id, task_id);

alter table public.task_attachments enable row level security;

revoke all on public.task_attachments from anon;
grant select, insert, update, delete on public.task_attachments to authenticated;

drop policy if exists "task_attachments_select_own" on public.task_attachments;
create policy "task_attachments_select_own"
on public.task_attachments for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "task_attachments_insert_own" on public.task_attachments;
create policy "task_attachments_insert_own"
on public.task_attachments for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "task_attachments_update_own" on public.task_attachments;
create policy "task_attachments_update_own"
on public.task_attachments for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "task_attachments_delete_own" on public.task_attachments;
create policy "task_attachments_delete_own"
on public.task_attachments for delete to authenticated
using ((select auth.uid()) = user_id);

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit
)
values (
  'task-attachments',
  'task-attachments',
  false,
  15728640
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit;

drop policy if exists "orbitask_attachment_insert_own" on storage.objects;
create policy "orbitask_attachment_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'task-attachments'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "orbitask_attachment_update_own" on storage.objects;
create policy "orbitask_attachment_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'task-attachments'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'task-attachments'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "orbitask_attachment_select_own" on storage.objects;
create policy "orbitask_attachment_select_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'task-attachments'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "orbitask_attachment_delete_own" on storage.objects;
create policy "orbitask_attachment_delete_own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'task-attachments'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
