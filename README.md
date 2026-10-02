# Orbitask

**Tus tareas, siempre en órbita.**

Orbitask es una aplicación TO-DO multiplataforma desarrollada con Flutter para organizar tareas, prioridades, fechas, listas y subtareas. El objetivo es funcionar en Android, Windows y Linux y, en etapas posteriores, sincronizar tareas y recordatorios entre dispositivos.

## Estado actual — v0.4.1-dev

- CRUD de tareas.
- Captura rápida.
- Prioridades.
- Fechas y horas límite.
- Filtros de tareas.
- Persistencia local con SQLite.
- Listas personalizadas.
- Subtareas y progreso.
- Migración de datos de versiones anteriores.
- Identidad nativa Orbitask en Android, Linux y Windows.
- Migración segura de `todo_app.sqlite` a `orbitask.sqlite`.
- Iconos Material para listas, sin depender de emojis del sistema.
- Interfaz adaptable para escritorio y pantallas pequeñas.
- Linux validado hasta v0.4-dev; v0.4.1-dev pendiente de validación local.

## Historial

- `v0.1-dev`: base visual, modelo Task y diseño responsive.
- `v0.2-dev`: CRUD, prioridades, fechas y filtros.
- `v0.3-dev`: SQLite y persistencia local.
- `v0.4-dev`: listas, subtareas, progreso y migración SQLite.
- `v0.4.1-dev`: limpieza de identidad Orbitask, migración de nombre de base de datos e iconos Material.

## Roadmap

- `v0.5-dev`: recordatorios y notificaciones.
- Cuenta de usuario y Supabase.
- Sincronización entre dispositivos.
- Android.
- Windows.
- Versión estable `v1.0`.

## Tecnologías

- Flutter / Dart
- SQLite (`sqlite3`)
- `path_provider`

## Plataformas objetivo

- Android
- Windows
- Linux
