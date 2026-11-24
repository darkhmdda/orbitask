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
| Realtime | Cuando Supabase avisa de un cambio en alguna tabla del usuario |
| Sondeo periódico | Cada 20 s en Windows y cada 30 s en el resto, como respaldo de Realtime |
| Manual | El usuario puede forzar una sincronización desde la interfaz |
| Reintento tras un fallo | Esperas de 5 s, 15 s, 30 s y 1 min (se repite 1 min mientras siga fallando) |

Si llega un disparador mientras ya hay una sincronización en curso, se encola y se ejecuta otra al terminar.

Realtime escucha las tablas `user_preferences`, `task_lists`, `tasks`, `subtasks`, `reminders`, `task_attachments` y `sync_deletions`, filtradas por `user_id`.

Para no reaccionar a sus propios cambios, el dispositivo **ignora los eventos de Realtime durante 5 segundos** desde el inicio de cada sincronización.

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

Después de una sincronización correcta, la interfaz recarga los datos y reconcilia los recordatorios.

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
4. **Posible reacción en cadena entre dispositivos.** Antes de la migración `20261123180000`, un `upsert` de filas sin cambios generaba eventos de Realtime para los otros dispositivos, que sincronizaban a su vez, y la única protección era la ventana de 5 s basada en tiempo. Ahora el cliente ya no sube las filas sin cambios y el servidor omite las que lleguen idénticas, de modo que esas escrituras no generan evento, lo que debería eliminar la reacción en cadena. Falta confirmarlo midiendo el tráfico real; la ventana de 5 s se mantiene como respaldo.
5. **Lógica duplicada.** Existe una versión nativa y otra web del servicio; cada corrección hay que hacerla dos veces.
6. **Sin pruebas automatizadas** del servicio de sincronización, el fusionado ni los tombstones.
7. **Dispositivos muy antiguos.** Un dispositivo que pase más de 365 días sin sincronizar podría reintroducir registros cuyos tombstones ya se purgaron.
8. **Web.** Los datos locales viven en `localStorage`, con la cuota del navegador (alrededor de 5 MB según el navegador).

## Mejoras propuestas

No están implementadas.

- Corregir el desfase de reloj: que el servidor limite los `updated_at` futuros y que el cliente adopte el valor del servidor después de subir. El trigger actual no lo resuelve por sí solo, porque sustituir el valor en el servidor sin que el cliente lo adopte provocaría reenvíos continuos.
- Descarga incremental: pedir solo lo modificado desde la última sincronización (la subida ya es incremental).
- Identificar el dispositivo de origen en cada cambio para ignorar eventos propios de Realtime sin depender de una ventana de tiempo.
- Fusionar por campo en lugar de por registro.
- Extraer la lógica de fusión a una capa común que dependa solo de una interfaz de almacenamiento, y escribir pruebas con dos "dispositivos" simulados, empezando por una prueba de regresión del error de `reminders_task_fk`.
