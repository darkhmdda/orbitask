# Orbitask

**Tus tareas, siempre en órbita.**

Orbitask es una aplicación TO-DO multiplataforma desarrollada con Flutter para organizar tareas, prioridades, fechas, listas y subtareas. El objetivo es funcionar en Android, Windows y Linux y, en etapas posteriores, sincronizar tareas y recordatorios entre dispositivos.

## Estado actual — v0.6-dev

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
- Linux v0.4.1-dev validado con análisis limpio y persistencia confirmada tras reinicio.
- Recordatorios persistentes por tarea.
- Múltiples recordatorios relativos o personalizados.
- Programación/cancelación automática de notificaciones.
- Prueba manual de notificación desde Ajustes.
- En Linux/Crostini, los recordatorios usan temporizadores de usuario del sistema y sobreviven al cierre de Orbitask.
- Edición directa de recordatorios conservando su identificador y reprogramando el mismo timer.
- Cancelación automática del timer al completar o eliminar una tarea.
- Persistencia de recordatorios confirmada tras cerrar y volver a abrir Orbitask.
- v0.5-dev validado en Linux/Crostini con notificaciones reales entregadas con Orbitask cerrada.
- Selector de temas visuales: Rimuru, Emilia, Itsuki, Rem, Veldora y Zoro.
- Tema elegido persistente en SQLite.
- Paleta completa aplicada a fondo, superficies, botones, chips, selección e iconos.
- Nueva identidad visual adaptable de Orbitask con marca tipo órbita + check.
- Persistencia del tema validada tras cerrar y volver a abrir Orbitask en Linux/Crostini.
- v0.6-dev validado visualmente con los seis temas en Linux/Crostini.

## Historial

- `v0.1-dev`: base visual, modelo Task y diseño responsive.
- `v0.2-dev`: CRUD, prioridades, fechas y filtros.
- `v0.3-dev`: SQLite y persistencia local.
- `v0.4-dev`: listas, subtareas, progreso y migración SQLite.
- `v0.4.1-dev`: limpieza de identidad Orbitask, migración de nombre de base de datos e iconos Material.
- `v0.5-dev`: recordatorios persistentes, edición y cancelación de avisos, y notificaciones locales validadas en Linux/Crostini.
- `v0.6-dev`: sistema de seis temas persistentes, paletas completas e identidad visual adaptable.

## Roadmap

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
