alter table public.sync_deletions
  drop constraint if exists sync_deletions_entity_type_check;

alter table public.sync_deletions
  add constraint sync_deletions_entity_type_check
  check (entity_type in ('task_list','task','subtask','reminder','attachment'));
