-- Verificación de 20261123180000_skip_stale_sync_updates.sql
--
-- Se ejecuta completo en el editor SQL de Supabase. Usa tu primer usuario de auth.users,
-- crea una lista y una tarea de prueba, hace las comprobaciones y lo REVIERTE todo
-- (rollback), de modo que no deja datos.
--
-- Resultado esperado:
--   * Sin la migración: falla en la prueba 1 ("una escritura más antigua sobrescribió...").
--   * Con la migración: termina con el aviso "OK: todas las comprobaciones pasaron".
--
-- Si el editor muestra un error, ejecuta además `rollback;` por si la transacción
-- quedó abierta.

begin;

do $$
declare
  uid uuid := (select id from auth.users order by created_at limit 1);
  t0 timestamptz := '2026-01-01 10:00:00+00';
  v_title text;
  v_updated timestamptz;
  n integer;
begin
  if uid is null then
    raise exception 'No hay usuarios en auth.users para probar.';
  end if;

  insert into public.task_lists (user_id, id, name, updated_at)
  values (uid, 'zz-test-list', 'Prueba', t0);

  insert into public.tasks (user_id, id, title, list_id, updated_at)
  values (uid, 'zz-test-task', 'original', 'zz-test-list', t0);

  -- 1) Un upsert más antiguo NO debe sobrescribir.
  insert into public.tasks (user_id, id, title, list_id, updated_at)
  values (uid, 'zz-test-task', 'vieja', 'zz-test-list', t0 - interval '1 hour')
  on conflict (user_id, id) do update
    set title = excluded.title, list_id = excluded.list_id, updated_at = excluded.updated_at;

  select title into v_title from public.tasks where user_id = uid and id = 'zz-test-task';
  if v_title <> 'original' then
    raise exception 'FALLO 1: una escritura más antigua sobrescribió la fila (título = %).', v_title;
  end if;

  -- 2) Un upsert con el MISMO updated_at tampoco debe cambiar nada.
  insert into public.tasks (user_id, id, title, list_id, updated_at)
  values (uid, 'zz-test-task', 'misma-fecha', 'zz-test-list', t0)
  on conflict (user_id, id) do update
    set title = excluded.title, list_id = excluded.list_id, updated_at = excluded.updated_at;

  select title into v_title from public.tasks where user_id = uid and id = 'zz-test-task';
  if v_title <> 'original' then
    raise exception 'FALLO 2: una escritura con la misma fecha cambió la fila (título = %).', v_title;
  end if;

  -- 3) Un upsert MÁS NUEVO sí debe aplicarse.
  insert into public.tasks (user_id, id, title, list_id, updated_at)
  values (uid, 'zz-test-task', 'nueva', 'zz-test-list', t0 + interval '1 hour')
  on conflict (user_id, id) do update
    set title = excluded.title, list_id = excluded.list_id, updated_at = excluded.updated_at;

  select title, updated_at into v_title, v_updated
  from public.tasks where user_id = uid and id = 'zz-test-task';
  if v_title <> 'nueva' or v_updated <> t0 + interval '1 hour' then
    raise exception 'FALLO 3: una escritura más reciente no se aplicó (título = %, updated_at = %).', v_title, v_updated;
  end if;

  -- 4) Un UPDATE directo sin cambiar updated_at no debe afectar a ninguna fila.
  update public.tasks set title = 'directo'
  where user_id = uid and id = 'zz-test-task';
  get diagnostics n = row_count;
  if n <> 0 then
    raise exception 'FALLO 4: un UPDATE sin updated_at nuevo afectó % fila(s).', n;
  end if;

  -- 5) Un UPDATE directo con updated_at mayor sí debe aplicarse.
  update public.tasks set title = 'directo-nuevo', updated_at = t0 + interval '2 hours'
  where user_id = uid and id = 'zz-test-task';
  get diagnostics n = row_count;
  if n <> 1 then
    raise exception 'FALLO 5: un UPDATE con updated_at mayor afectó % fila(s) en lugar de 1.', n;
  end if;

  -- 6) Los INSERT de filas nuevas no se ven afectados.
  insert into public.tasks (user_id, id, title, list_id, updated_at)
  values (uid, 'zz-test-task-2', 'segunda', 'zz-test-list', t0);
  select count(*) into n from public.tasks where user_id = uid and id = 'zz-test-task-2';
  if n <> 1 then
    raise exception 'FALLO 6: el INSERT de una fila nueva no se aplicó.';
  end if;

  raise notice 'OK: todas las comprobaciones pasaron';
end;
$$;

rollback;
