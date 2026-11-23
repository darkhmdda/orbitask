# Datos, Supabase y seguridad

Este documento describe dónde y cómo guarda Orbitask sus datos: la base de datos local, el esquema remoto en Supabase, las políticas de acceso (RLS), el almacenamiento de archivos y la autenticación. Refleja el código de la versión **1.0.1+13**.

## Base de datos local

En Android, Linux y Windows se usa SQLite (`orbitask.sqlite`, en el directorio de soporte de la aplicación, con modo WAL y claves foráneas activas). En Web se usa el almacenamiento del navegador.

Tablas locales (nativo):

| Tabla | Contenido |
| ----- | --------- |
| `task_lists` | Listas. La lista `inbox` es del sistema y no se puede eliminar |
| `tasks` | Tareas, con `list_id` y `trashed_at` (Papelera) |
| `subtasks` | Subtareas de una tarea, con `position` |
| `reminders` | Recordatorios de una tarea |
| `task_attachments` | Metadatos de adjuntos |
| `app_settings` | Pares clave-valor: tema, vínculo con cuenta, marcas de sincronización |
| `sync_deletions` | Diario local de borrados definitivos (tombstones) |

Todas las fechas se guardan como enteros (milisegundos desde epoch). Los identificadores son texto generado en el cliente, lo que permite crear datos sin conexión sin colisiones.

Claves de `app_settings` relevantes:

| Clave | Uso |
| ----- | --- |
| `theme_id`, `theme_updated_at` | Tema activo y cuándo se cambió (para resolver conflictos entre dispositivos) |
| `cloud_account_id` | Cuenta a la que está vinculado este espacio local |
| `last_cloud_sync_at`, `last_cloud_upload_at` | Últimas sincronización y subida correctas |
| `last_tombstone_cleanup_at` | Última limpieza del diario de borrados |

El **vínculo con la cuenta** impide mezclar datos: la primera vez que se sincroniza, el espacio local queda ligado al usuario. Si luego inicia sesión otro usuario, la sincronización se bloquea con un mensaje en vez de combinar datos de dos cuentas.

## Esquema remoto (Supabase / Postgres)

Las migraciones están en `supabase/migrations/` y deben aplicarse en orden cronológico:

| Migración | Qué hace |
| --------- | -------- |
| `20261003020059_create_orbitask_sync_schema` | Tablas base, índices, RLS y trigger de alta de usuario |
| `20261003020114_lock_down_auth_trigger_function` | Revoca la ejecución pública de la función del trigger |
| `20261003022931_add_sync_deletions_journal` | Tabla `sync_deletions` |
| `20261003025205_enable_orbitask_postgres_realtime` | Activa Realtime para las tablas de sincronización |
| `20261004031728_add_usernames_and_profile_avatars` | `username`, `avatar_path` y bucket de avatares |
| `20261004033546_increase_profile_avatar_limit_to_3mb` | Sube el límite de avatar a 3 MB |
| `20261004182914_add_task_trash` | Columna `tasks.trashed_at` |
| `20261006012000_add_task_attachments` | Tabla y bucket de adjuntos |
| `20261006014500_enable_task_attachments_realtime` | Realtime para adjuntos |
| `20261006020500_allow_attachment_sync_deletions` | Permite el tipo `attachment` en el diario de borrados |
| `20261123180000_skip_stale_sync_updates` | Trigger que descarta las actualizaciones no más recientes que lo guardado, en las tablas de sincronización (verificación en `supabase/tests/`) |

### Tablas

Todas las tablas de datos tienen `user_id` (referencia a `auth.users`, con borrado en cascada) y, salvo `profiles` y `user_preferences`, clave primaria `(user_id, id)`. Los `id` son de texto, generados por el cliente.

| Tabla | Columnas principales |
| ----- | -------------------- |
| `profiles` | `id`, `display_name`, `username`, `avatar_path` |
| `user_preferences` | `user_id`, `theme_id`, `updated_at` |
| `task_lists` | `id`, `name`, `icon`, `is_system` |
| `tasks` | `id`, `title`, `description`, `priority` (0 a 3), `due_date`, `completed`, `list_id`, `trashed_at` |
| `subtasks` | `id`, `task_id`, `title`, `completed`, `position` |
| `reminders` | `id`, `task_id`, `scheduled_at`, `offset_minutes`, `enabled` |
| `task_attachments` | `id`, `task_id`, `name`, `mime_type`, `size_bytes` (máx. 15 MB), `storage_path` |
| `sync_deletions` | `entity_type` (`task_list`, `task`, `subtask`, `reminder`, `attachment`), `entity_id`, `deleted_at` |

Casi todas las tablas tienen `created_at` y `updated_at` (`user_preferences` solo tiene `updated_at` y `sync_deletions` usa `deleted_at`). Las subtareas, recordatorios y adjuntos dependen de su tarea con borrado en cascada. Una tarea depende de su lista por clave foránea.

Restricciones de `profiles.username`: formato `^[a-z0-9_]{3,24}$` y unicidad sin distinguir mayúsculas.

### Alta de usuario

Un trigger sobre `auth.users` (`handle_new_orbitask_user`, `security definer`, con `search_path` vacío) crea para cada usuario nuevo:

- su fila en `profiles` (con `display_name` si se envió al registrarse),
- su fila en `user_preferences` (tema inicial `emilia`),
- cinco listas: Bandeja de entrada (`inbox`, del sistema), Universidad, Personal, Proyectos y Compras.

Los nombres de las listas iniciales están fijos en español dentro de la migración.

## Políticas de acceso (RLS)

RLS está activado en **todas** las tablas. Reglas comunes:

- Se revoca todo acceso al rol `anon`; solo `authenticated` tiene permisos.
- Cada política compara `(select auth.uid())` con `user_id` (o `id` en `profiles`). Las de inserción y actualización usan además `WITH CHECK`, de modo que no se puede escribir una fila a nombre de otro usuario.
- Un usuario solo ve, crea, modifica y borra sus propias filas.
- `profiles` permite `select` y `update` propios. La fila la crea el trigger, no el cliente.

## Storage

| Bucket | Visibilidad | Límite | Notas |
| ------ | ----------- | ------ | ----- |
| `task-attachments` | **Privado** | 15 MB por archivo | Archivos adjuntos a tareas |
| `profile-avatars` | **Público** | 3 MB | Solo `image/jpeg`, `image/png` e `image/webp` |

En ambos buckets, las políticas sobre `storage.objects` exigen que el **primer segmento de la ruta sea el `auth.uid()` del usuario**. Es decir, cada usuario solo puede subir, leer, modificar y borrar dentro de su propia carpeta (`<user_id>/...`).

Como el bucket de avatares es público, cualquiera que conozca la URL de un avatar puede verlo.

## Autenticación

Se usa Supabase Auth con correo y contraseña (`AuthService`):

- registro, inicio y cierre de sesión;
- recuperación de contraseña por correo;
- cambio de contraseña desde Ajustes, pidiendo antes la contraseña actual;
- sesión persistente administrada por el SDK.

Enlaces de retorno (deben estar permitidos en la configuración de Auth de Supabase):

| Plataforma | Redirect |
| ---------- | -------- |
| Android y Windows | `com.darkhmdda.orbitask://login-callback` |
| Web | La URL donde se sirve la app (por ejemplo, `https://darkhmdda.github.io/orbitask/`) y `http://localhost:8080` en desarrollo |

## Configurar tu propio proyecto de Supabase

1. Crea un proyecto en Supabase.
2. Aplica las migraciones de `supabase/migrations/` en orden (con la CLI de Supabase o pegándolas en el editor SQL).
3. En Authentication, añade a la lista de URLs de redirección permitidas las de la tabla anterior.
4. Compila o ejecuta la app con `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` y `SUPABASE_AUTH_REDIRECT_URL` (ver [BUILDS_Y_DISTRIBUCION.md](BUILDS_Y_DISTRIBUCION.md)).

## Consideraciones de seguridad

- **La clave publicable no es un secreto**, pero solo es segura mientras RLS esté bien configurado. Este esquema lo está. Si añades tablas, activa RLS y crea sus políticas desde el primer momento.
- Nunca incluyas una clave `service_role` en la app, en el repositorio ni en los workflows.
- La URL del proyecto y la clave publicable de las builds oficiales se pasan a los workflows de GitHub Actions mediante variables del repositorio (`SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`), no están escritas en el código. Esto facilita cambiarlas, pero no las oculta: acaban dentro de cada binario y de la web, y por eso su seguridad depende de RLS. Los valores que ya estuvieron en commits anteriores siguen visibles en el historial de git.
- El registro está abierto: cualquiera puede crear una cuenta en el proyecto de Supabase de las builds oficiales. Hay límite de tamaño por archivo, pero **no hay una cuota total de almacenamiento por usuario** en las migraciones.
- La firma de Android (`android/key.properties` y el keystore) no se versiona y debe respaldarse fuera del repositorio.
