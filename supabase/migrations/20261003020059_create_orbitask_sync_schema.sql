create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  theme_id text not null default 'emilia',
  updated_at timestamptz not null default now()
);

create table public.task_lists (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  name text not null,
  icon text not null default 'list',
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create table public.tasks (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  title text not null,
  description text not null default '',
  priority smallint not null default 0 check (priority between 0 and 3),
  due_date timestamptz,
  completed boolean not null default false,
  list_id text not null default 'inbox',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  constraint tasks_list_fk
    foreign key (user_id, list_id)
    references public.task_lists(user_id, id)
    on update cascade
);

create table public.subtasks (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  task_id text not null,
  title text not null,
  completed boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  constraint subtasks_task_fk
    foreign key (user_id, task_id)
    references public.tasks(user_id, id)
    on delete cascade
);

create table public.reminders (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  task_id text not null,
  scheduled_at timestamptz not null,
  offset_minutes integer,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, id),
  constraint reminders_task_fk
    foreign key (user_id, task_id)
    references public.tasks(user_id, id)
    on delete cascade
);

create index task_lists_user_id_idx on public.task_lists(user_id);
create index tasks_user_id_idx on public.tasks(user_id);
create index tasks_user_list_idx on public.tasks(user_id, list_id);
create index tasks_user_updated_idx on public.tasks(user_id, updated_at);
create index subtasks_user_task_idx on public.subtasks(user_id, task_id);
create index reminders_user_task_idx on public.reminders(user_id, task_id);
create index reminders_user_scheduled_idx on public.reminders(user_id, scheduled_at);

alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.task_lists enable row level security;
alter table public.tasks enable row level security;
alter table public.subtasks enable row level security;
alter table public.reminders enable row level security;

revoke all on public.profiles from anon;
revoke all on public.user_preferences from anon;
revoke all on public.task_lists from anon;
revoke all on public.tasks from anon;
revoke all on public.subtasks from anon;
revoke all on public.reminders from anon;

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.user_preferences to authenticated;
grant select, insert, update, delete on public.task_lists to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;
grant select, insert, update, delete on public.subtasks to authenticated;
grant select, insert, update, delete on public.reminders to authenticated;

create policy "profiles_select_own"
on public.profiles for select to authenticated
using ((select auth.uid()) = id);

create policy "profiles_update_own"
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "preferences_select_own"
on public.user_preferences for select to authenticated
using ((select auth.uid()) = user_id);

create policy "preferences_insert_own"
on public.user_preferences for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "preferences_update_own"
on public.user_preferences for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "lists_select_own"
on public.task_lists for select to authenticated
using ((select auth.uid()) = user_id);

create policy "lists_insert_own"
on public.task_lists for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "lists_update_own"
on public.task_lists for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "lists_delete_own"
on public.task_lists for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "tasks_select_own"
on public.tasks for select to authenticated
using ((select auth.uid()) = user_id);

create policy "tasks_insert_own"
on public.tasks for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "tasks_update_own"
on public.tasks for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "tasks_delete_own"
on public.tasks for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "subtasks_select_own"
on public.subtasks for select to authenticated
using ((select auth.uid()) = user_id);

create policy "subtasks_insert_own"
on public.subtasks for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "subtasks_update_own"
on public.subtasks for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "subtasks_delete_own"
on public.subtasks for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "reminders_select_own"
on public.reminders for select to authenticated
using ((select auth.uid()) = user_id);

create policy "reminders_insert_own"
on public.reminders for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "reminders_update_own"
on public.reminders for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "reminders_delete_own"
on public.reminders for delete to authenticated
using ((select auth.uid()) = user_id);

create or replace function public.handle_new_orbitask_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, nullif(new.raw_user_meta_data ->> 'display_name', ''));

  insert into public.user_preferences (user_id, theme_id)
  values (new.id, 'emilia');

  insert into public.task_lists (
    user_id, id, name, icon, is_system
  ) values
    (new.id, 'inbox', 'Bandeja de entrada', 'inbox', true),
    (new.id, 'university', 'Universidad', 'school', false),
    (new.id, 'personal', 'Personal', 'home', false),
    (new.id, 'projects', 'Proyectos', 'computer', false),
    (new.id, 'shopping', 'Compras', 'shopping', false);

  return new;
end;
$$;

create trigger on_auth_user_created_orbitask
after insert on auth.users
for each row execute procedure public.handle_new_orbitask_user();
