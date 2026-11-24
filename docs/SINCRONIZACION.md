# Sincronización

Este documento explica cómo sincroniza Orbitask los datos locales con Supabase: el flujo completo, cuándo se dispara, cómo se resuelven los conflictos y cuáles son sus límites actuales. Refleja el código de la versión **1.0.1+13**, leído de `lib/services/cloud_sync_service_native.dart` y `lib/screens/home/home_screen_sync.dart`. El servicio web (`cloud_sync_service_web.dart`) implementa el mismo comportamiento.

## Principios

- La base de datos local es la fuente con la que trabaja la interfaz. La nube es una réplica para compartir datos entre dispositivos.
- La sincronización es **bidireccional** y opera sobre **registros completos**, no sobre campos sueltos.
- Cada registro lleva un `updated_at`. Gana el más reciente.
- Los borrados definitivos se registran en un diario (`sync_deletions`) para que no reaparezcan.
- Un espacio local queda vinculado a una cuenta; si inicia sesión otra, la sincronización se bloquea (ver [DATOS_Y_SUPABASE.md](DATOS_Y_SUPABASE.md#base-de-datos-local)).

## Qué dispara una sincronización

| Disparador | Detalle |
| ---------- | ------- |
| Cambio local | Con un pequeño retardo para agrupar cambios (500 ms en Windows, 750 ms en el resto) |
| Realtime | Cuando Supabase avisa de un cambio, la fila se aplica en local al momento (ver [Cambios por Realtime](#cambios-por-realtime)). Solo los adjuntos, el tema y los casos que no se pueden aplicar sueltos lanzan una sincronización completa |
| Sondeo periódico | Cada 20 s en Windows y cada 30 s en el resto, como respaldo de Realtime |
| Manual | El usuario puede forzar una sincronización desde la interfaz |
| Reintento tras un fallo | Esperas de 5 s, 15 s, 30 s y 1 min (se repite 1 min mientras siga fallando) |

Si llega un disparador mientras ya hay una sincronización en curso, se encola y se ejecuta otra al terminar.

Realtime escucha las tablas `user_preferences`, `task_lists`, `tasks`, `subtasks`, `reminders`, `task_attachments` y `sync_deletions`, filtradas por `user_id`.

## Cambios por Realtime

Cada aviso de Realtime trae la fila que cambió. `applyRemoteChange` la aplica en la base local con la misma regla que la sincronización completa (solo si su `updated_at` es estrictamente mayor que el local) y devuelve:

| Resultado | Cuándo | Qué hace la interfaz |
| --------- | ------ | -------------------- |
| `applied` | La copia local cambió | Recarga los datos (agrupando los avisos que llegan en 150 ms) y reprograma solo los recordatorios de las tareas que cambiaron |
| `unchanged` | Es el eco de un cambio propio (misma fila, mismo `updated_at`) o una versión más antigua | Nada |
| `needsFullSync` | Adjuntos (hay que descargar el archivo), tema, borrados de filas, una cuenta distinta de la vinculada, un espacio sin vincular o una fila hija cuya tarea aún no ha llegado | Lanza una sincronización completa |

Los borrados llegan como filas nuevas de `sync_deletions`: se guardan en el diario local y se aplican al momento con las reglas de los [tombstones](#tombstones).

Hasta la versión 1.0.1, el dispositivo ignoraba Realtime durante 5 segundos desde el inicio de cada sincronización para no reaccionar a sus propios cambios. Eso también descartaba los cambios de los otros dispositivos que llegaban en esa ventana, que no aparecían hasta el siguiente sondeo (20–30 s). Con la detección del eco por `updated_at` esa ventana ya no existe.

### Recordatorios tras sincronizar

Tras una sincronización completa o un cambio de Realtime, `ReminderPlan.diff` compara las tareas y recordatorios de antes y de después y solo cancela y vuelve a programar los de las tareas que cambiaron. Antes se reprogramaban todos tras cada sincronización, y los avisos de una tarea borrada en otro dispositivo no se cancelaban porque la tarea ya no aparecía en la lista. Al abrir la app se sigue haciendo una reconciliación completa una vez.

## Flujo de `syncNow()`

1. **Comprobar el espacio local.** Verifica que pertenece al usuario autenticado.
2. **Tema.** Compara `theme_updated_at` local y remoto; prevalece el más reciente.
3. **Descargar borrados.** Trae `sync_deletions` y los fusiona con el diario local.
4. **Descargar datos.** Trae completas las tablas `task_lists`, `tasks`, `subtasks`, `reminders` y `task_attachments` del usuario.
5. **Fusionar en local.** Inserta o actualiza cada registro solo si el remoto tiene un `updated_at` **mayor** que el local (`WHERE excluded.updated_at > tabla.updated_at`).
6. **Aplicar borrados en local.** Elimina los registros marcados en el diario, salvo que el registro local sea posterior al borrado.
7. **Subir datos.** Sube con `upsert` las listas, tareas, subtareas y recordatorios locales que no existen en Supabase o son estrictamente más recientes que su copia remota (se compara con las versiones descargadas en el paso 4; los adjuntos siguen su propia comprobación). El servidor descarta, sin error, las filas cuyo `updated_at` no sea estrictamente mayor que el guardado (trigger `skip_stale_sync_updates`). Desde 1.0.1 **no sube** subtareas, recordatorios ni adjuntos cuya tarea ya no existe en local (evita el error de clave foránea `reminders_task_fk`).
8. **Subir y aplicar borrados en la nube.** Sube el diario local y elimina en Supabase los registros (y archivos de Storage) borrados, salvo que su `updated_at` sea posterior.
9. **Limpiar el diario.** Como máximo una vez al día (ver [Tombstones](#tombstones)).
10. **Registrar la hora** de la última sincronización correcta.

Después de una sincronización correcta, la interfaz recarga los datos y reprograma los recordatorios de las tareas que cambiaron (ver [Recordatorios tras sincronizar](#recordatorios-tras-sincronizar)).

## Resolución de conflictos

| Situación | Resultado |
| --------- | --------- |
| Mismo registro editado en dos dispositivos | Se queda **el registro entero** con mayor `updated_at` |
| Registro editado después de ser borrado en otro dispositivo | Sobrevive la edición (`updated_at` posterior al borrado) |
| Registro editado antes del borrado | Se elimina |
| Lista eliminada | Sus tareas se reasignan a la Bandeja de entrada (`inbox`) y luego se elimina la lista. La lista `inbox` nunca se elimina |
| Tema distinto en dos dispositivos | Gana el de `theme_updated_at` más reciente |

### Papelera

Enviar una tarea a la Papelera no es un borrado: se escribe `trashed_at` en la tarea y se sincroniza como cualquier otro cambio. La **eliminación permanente** sí crea tombstones, y desde 1.0.1 también para sus subtareas, recordatorios y adjuntos.

## Tombstones

Cada borrado definitivo se guarda en `sync_deletions` (`entity_type`, `entity_id`, `deleted_at`), tanto en local como en Supabase. Sirve para que un dispositivo que estuvo sin conexión no vuelva a subir un registro que otro eliminó.

- **Retención:** 365 días.
- **Limpieza:** como máximo una vez al día, y solo al final de una sincronización correcta, después de aplicar los tombstones en local y en la nube.

## Limitaciones conocidas

Estas limitaciones son del diseño actual y están pendientes de mejorar.

1. **Granularidad de registro completo.** Si dos dispositivos editan campos distintos de la misma tarea sin conexión, el registro más reciente sobrescribe al otro entero; los cambios del perdedor se pierden.
2. **Dependencia del reloj del cliente.** El `updated_at` lo escribe el dispositivo. Desde la migración `20261123180000_skip_stale_sync_updates`, el servidor ya no deja que una escritura más antigua o idéntica pise a una más nueva, lo que cierra la ventana entre descargar y subir. Pero el orden sigue dependiendo del reloj de cada dispositivo: uno con el reloj muy adelantado sigue ganando los conflictos.
3. **Descarga completa en cada pasada.** Cada ejecución descarga todas las tablas del usuario, hayan cambiado o no, y se repite cada 20 o 30 s. La subida ya envía solo las filas más recientes que su copia remota, pero el coste de la descarga crece con el número de tareas.
4. **Reacción en cadena entre dispositivos: resuelta.** El cliente no sube filas sin cambios, el servidor descarta las idénticas (trigger `skip_stale_sync_updates`) y los ecos que aun así lleguen por Realtime no modifican nada en local, así que no disparan nada más.
5. **Lógica duplicada.** Existe una versión nativa y otra web del servicio; cada corrección hay que hacerla dos veces.
6. **Pruebas parciales.** `test/realtime_sync_test.dart` prueba con dos dispositivos simulados cómo se aplican los cambios de Realtime (ediciones cruzadas, ecos, versiones antiguas, tombstones, listas eliminadas, filas de otra cuenta) y la regresión de `reminders_task_fk`; `test/reminder_plan_test.dart` prueba la reprogramación de recordatorios. La sincronización completa contra Supabase (`syncNow`) sigue sin pruebas automatizadas.
7. **Dispositivos muy antiguos.** Un dispositivo que pase más de 365 días sin sincronizar podría reintroducir registros cuyos tombstones ya se purgaron.
8. **Web.** Los datos locales viven en `localStorage`, con la cuota del navegador (alrededor de 5 MB según el navegador).

## Mejoras propuestas

No están implementadas.

- Corregir el desfase de reloj: que el servidor limite los `updated_at` futuros y que el cliente adopte el valor del servidor después de subir. El trigger actual no lo resuelve por sí solo, porque sustituir el valor en el servidor sin que el cliente lo adopte provocaría reenvíos continuos.
- Descarga incremental: pedir solo lo modificado desde la última sincronización (la subida ya es incremental).
- Fusionar por campo en lugar de por registro.
- Extraer la lógica de fusión a una capa común que dependa solo de una interfaz de almacenamiento, para unificar nativo y web y poder probar `syncNow` completo.
