-- Descarta las actualizaciones que no son estrictamente más recientes que lo guardado.
--
-- Problema: el cliente sube todas sus filas con un upsert incondicional
-- (INSERT ... ON CONFLICT DO UPDATE). Si otro dispositivo escribió algo más nuevo
-- entre la descarga y la subida, una copia antigua lo sobrescribía; además, subir filas
-- idénticas generaba cambios y eventos de Realtime innecesarios.
--
-- Solución: un trigger BEFORE UPDATE que devuelve NULL (omite la actualización de esa
-- fila, sin error) cuando el updated_at entrante no es mayor que el almacenado.
--
-- Qué NO cambia:
--   * El orden sigue dependiendo de updated_at, que escribe el cliente. Un dispositivo
--     con el reloj muy adelantado puede seguir ganando conflictos.
--   * Los INSERT (filas nuevas) no se tocan.
--   * Las tablas profiles y sync_deletions no llevan el trigger: profiles se edita fuera
--     del flujo de sincronización y sync_deletions no usa updated_at.

create or replace function public.skip_stale_sync_updates()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- pg_trigger_depth() > 1 significa que la actualización la provoca otro trigger
  -- (por ejemplo una acción de clave foránea). Esas se dejan pasar siempre.
  if pg_trigger_depth() > 1 then
    return new;
  end if;

  if new.updated_at <= old.updated_at then
    return null;
  end if;

  return new;
end;
$$;

revoke all on function public.skip_stale_sync_updates() from public, anon, authenticated;

drop trigger if exists task_lists_skip_stale_updates on public.task_lists;
create trigger task_lists_skip_stale_updates
before update on public.task_lists
for each row execute function public.skip_stale_sync_updates();

drop trigger if exists tasks_skip_stale_updates on public.tasks;
create trigger tasks_skip_stale_updates
before update on public.tasks
for each row execute function public.skip_stale_sync_updates();

drop trigger if exists subtasks_skip_stale_updates on public.subtasks;
create trigger subtasks_skip_stale_updates
before update on public.subtasks
for each row execute function public.skip_stale_sync_updates();

drop trigger if exists reminders_skip_stale_updates on public.reminders;
create trigger reminders_skip_stale_updates
before update on public.reminders
for each row execute function public.skip_stale_sync_updates();

drop trigger if exists task_attachments_skip_stale_updates on public.task_attachments;
create trigger task_attachments_skip_stale_updates
before update on public.task_attachments
for each row execute function public.skip_stale_sync_updates();

drop trigger if exists user_preferences_skip_stale_updates on public.user_preferences;
create trigger user_preferences_skip_stale_updates
before update on public.user_preferences
for each row execute function public.skip_stale_sync_updates();

-- Para revertir esta migración:
--   drop trigger if exists task_lists_skip_stale_updates on public.task_lists;
--   drop trigger if exists tasks_skip_stale_updates on public.tasks;
--   drop trigger if exists subtasks_skip_stale_updates on public.subtasks;
--   drop trigger if exists reminders_skip_stale_updates on public.reminders;
--   drop trigger if exists task_attachments_skip_stale_updates on public.task_attachments;
--   drop trigger if exists user_preferences_skip_stale_updates on public.user_preferences;
--   drop function if exists public.skip_stale_sync_updates();
