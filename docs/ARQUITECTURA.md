# Arquitectura

Este documento describe cómo está organizado Orbitask: capas, estructura del código, diferencias entre plataformas, recordatorios y widgets de Android. Refleja el código de la versión **1.0.1+13**.

## Visión general

Orbitask es una app Flutter con enfoque **local primero** (*offline-first*):

- Todos los datos viven primero en una base de datos local. La app funciona completa sin conexión.
- Si hay un proyecto de Supabase configurado y el usuario inicia sesión, un servicio de sincronización combina los datos locales con los remotos.
- La interfaz solo habla con el repositorio local. Nunca lee ni escribe directamente en Supabase, salvo el perfil.

```
┌─────────────────────────────────────────────────────────┐
│  Pantallas y widgets (lib/screens, lib/widgets)         │
└───────────────┬─────────────────────────┬───────────────┘
                │                         │
        ┌───────▼────────┐        ┌───────▼─────────────┐
        │ TodoRepository │        │ Servicios           │
        │ (CRUD local)   │        │ auth · sync · perfil│
        └───────┬────────┘        │ notificaciones      │
                │                 └───────┬─────────────┘
        ┌───────▼────────┐                │
        │ LocalDatabase  │◄───────────────┘
        │ SQLite / web   │        ┌───────────────────────┐
        └────────────────┘        │ Supabase (opcional)   │
                                  │ Auth · Postgres · RLS │
                                  │ Realtime · Storage    │
                                  └───────────────────────┘
```

## Arranque

`lib/main.dart` hace lo siguiente, en este orden:

1. Si `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` están definidos (`CloudConfig.isConfigured`), inicializa Supabase. Si no, `supabaseClient` queda en `null` y la app trabaja solo en local.
2. Abre la base de datos local (`LocalDatabase.open()`).
3. Crea el repositorio y los servicios: notificaciones, autenticación, sincronización y perfil.
4. Inicializa las notificaciones y lanza `OrbitaskApp`.

`OrbitaskApp` (`lib/app.dart`) aplica el tema guardado en la configuración local y delega en `AuthGate`, que decide si mostrar la pantalla de acceso o la pantalla principal.

## Estructura del código

```
lib/
├── main.dart                  Arranque e inyección de dependencias
├── app.dart                   MaterialApp, tema activo
├── core/
│   ├── config/cloud_config.dart   Variables --dart-define de Supabase
│   ├── theme/app_theme.dart       14 temas (solo definiciones de color)
│   └── list_icons.dart            Iconos disponibles para listas
├── models/                    Task, Subtask, Reminder, TaskList,
│                              TaskAttachment, OrbitaskProfile
├── database/                  LocalDatabase (native / web)
├── repositories/              TodoRepository (native / web)
├── services/
│   ├── auth_service.dart          Registro, acceso, recuperación, cambio de contraseña
│   ├── profile_service.dart       Nombre, username y avatar
│   ├── cloud_sync_service_*.dart  Sincronización (native / web)
│   ├── notification_service_*.dart Recordatorios (native / web)
│   └── attachment_opener_*.dart   Abrir o descargar adjuntos (native / web)
├── screens/
│   ├── auth/                  AuthGate, AuthScreen
│   ├── home/                  Pantalla principal (dividida en varios archivos)
│   ├── task_form/             Formulario de tarea
│   └── list_manager/          Administración de listas
└── widgets/                   TaskCard, selector de tema, marca Orbitask
```

`home_screen.dart` es una clase grande dividida en extensiones por responsabilidad: `home_screen_sync.dart` (sincronización), `home_screen_task_actions.dart` (acciones sobre tareas y Papelera), `home_screen_settings.dart` (ajustes y cuenta) y `home_screen_widgets.dart` (piezas de interfaz).

## Implementaciones por plataforma

Cuatro piezas tienen una versión para plataformas nativas y otra para Web, y se eligen con exports condicionales. Por ejemplo, `lib/database/local_database.dart` contiene:

```dart
export 'local_database_web.dart'
    if (dart.library.io) 'local_database_native.dart';
```

| Pieza | Nativa (Android, Linux, Windows) | Web |
| ----- | -------------------------------- | --- |
| `LocalDatabase` | SQLite (`sqlite3`), modo WAL, claves foráneas activas | Persistencia en el navegador (`localStorage`) |
| `TodoRepository` | Consultas SQL | Lógica equivalente sobre los datos del navegador |
| `CloudSyncService` | SQL local + Supabase | Equivalente para Web |
| `NotificationService` | Notificaciones locales / temporizadores del sistema | Notificaciones del navegador |

Los bytes de los adjuntos no se guardan en `localStorage` en Web, porque agotan su cuota rápidamente.

> **Consecuencia de mantenimiento:** la lógica de sincronización y de repositorio existe dos veces. Cualquier corrección debe aplicarse en ambas versiones (el hotfix 1.0.1 tuvo que hacerlo). Ver [Limitaciones conocidas](SINCRONIZACION.md#limitaciones-conocidas).

## Base de datos local

El esquema SQLite se crea y migra al abrir la base de datos (`_createAndMigrate`). Las migraciones se hacen con `CREATE TABLE IF NOT EXISTS` y comprobando columnas con `PRAGMA table_info` antes de `ALTER TABLE`, no con un número de versión (`user_version`). Detalle del esquema en [DATOS_Y_SUPABASE.md](DATOS_Y_SUPABASE.md#base-de-datos-local).

En el primer arranque, si existe una base de datos de nombres anteriores (`todo_app.sqlite`), se copia al nombre actual (`orbitask.sqlite`) para conservar los datos.

## Recordatorios y notificaciones

Cada tarea puede tener varios recordatorios, relativos a la fecha límite o con fecha y hora propias. Se pueden editar, reprogramar y cancelar. Cómo se entregan depende de la plataforma:

| Plataforma | Mecanismo | Limitación |
| ---------- | --------- | ---------- |
| Android | Notificaciones locales programadas (`zonedSchedule`). Pide el permiso de alarmas exactas; si no se concede, usa programación inexacta y avisa. | Con alarma inexacta la hora puede desviarse |
| Linux | Temporizadores de usuario de systemd (`systemd-run --user`) más `notify-send` | Requiere `systemd-run` y `notify-send` disponibles |
| Windows | Notificaciones locales | — |
| Web | Notificaciones del navegador, con permiso del usuario | Solo funcionan con la pestaña abierta (no hay Push / Service Worker) |

Al abrir la app o tras sincronizar, los recordatorios se reconcilian con las tareas actuales.

## Widgets de Android

Hay tres widgets de pantalla de inicio, escritos en Kotlin en `android/app/src/main/kotlin/com/darkhmdda/orbitask/`:

| Widget | Clase |
| ------ | ----- |
| Hoy | `OrbitaskTodayWidget` |
| Resumen | `OrbitaskSummaryWidget` |
| Calendario | `OrbitaskCalendarWidget` |

Cómo funcionan:

1. Flutter llama al `MethodChannel` `com.darkhmdda.orbitask/widgets`, método `updateWidgets`, y le pasa los colores del tema activo. Se guardan en `SharedPreferences` (`orbitask_widget`).
2. `OrbitaskWidgetData.refreshFromDatabase` abre `orbitask.sqlite` **en solo lectura** directamente desde Kotlin, lee las tareas fuera de la Papelera y calcula los contadores (pendientes, completadas, importantes, hoy, próximos siete días, vencidas).
3. Se refrescan los tres widgets.

**Acoplamiento a tener presente:** el código Kotlin depende del nombre del archivo (`orbitask.sqlite`), de su ubicación (`filesDir`) y de los nombres de columna de la tabla `tasks`. Si cambia el esquema local, hay que actualizar también `OrbitaskWidgetData`.

**Estado:** los widgets están implementados pero no figuran en ninguna release ni en el CHANGELOG publicado, y su diseño visual está pendiente de rediseño.

## Temas

Hay 14 temas, definidos en `lib/core/theme/app_theme.dart` solo como paletas de color. El tema elegido se guarda en la configuración local (`theme_id`, con `theme_updated_at`) y se sincroniza por cuenta en la tabla `user_preferences`. Si el identificador guardado no existe, se normaliza a uno válido.

## Pruebas y CI

Las pruebas están en `test/`:

- `models_test.dart`: modelos `Task`, `Reminder`, `Subtask` y `TaskList`.
- `todo_repository_test.dart`: repositorio sobre SQLite en memoria (`LocalDatabase.openInMemoryForTesting()`).

El workflow `flutter_ci.yml` ejecuta `flutter analyze`, `flutter test` y `flutter build web` en cada push y pull request hacia `main`. **No hay pruebas automatizadas del servicio de sincronización**; es la parte más compleja del proyecto.
