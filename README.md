# Orbitask

**Tus tareas, siempre en órbita.**

Orbitask es una aplicación TO-DO multiplataforma desarrollada con Flutter para organizar tareas, prioridades, fechas, listas y subtareas. El objetivo es funcionar en Android, Windows y Linux y, en etapas posteriores, sincronizar tareas y recordatorios entre dispositivos.

## Estado actual — v0.7-dev

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
- Logo orbital de Orbitask adaptable al color principal de cada tema.
- Persistencia del tema validada tras cerrar y volver a abrir Orbitask en Linux/Crostini.
- v0.6-dev validado visualmente con los seis temas en Linux/Crostini.
- Base de autenticación con Supabase.
- Inicio de sesión y creación de cuenta mediante correo y contraseña.
- Sesión persistente administrada por Supabase.
- Orbitask sigue funcionando en modo local si no se proporcionan credenciales de Supabase.
- Estado de cuenta y cierre de sesión desde Ajustes.
- Copia inicial SQLite → Supabase validada con datos reales.
- Sincronización manual nube ↔ dispositivo en desarrollo: primero combina los datos remotos con SQLite por `updated_at` y después vuelve a subir el estado resultante.
- Registro de eliminaciones local y remoto mediante tombstones para evitar que tareas, listas, subtareas o recordatorios borrados reaparezcan.
- Las eliminaciones se aplican solo cuando el tombstone no es más antiguo que el elemento existente.
- Sincronización automática mientras Orbitask está abierto: al iniciar, después de cambios locales y mediante un ciclo periódico cada minuto.
- El tema seleccionado también se sincroniza por cuenta y resuelve conflictos usando `updated_at`, sin sobrescribir una preferencia más reciente con una más antigua.
- Supabase Realtime está habilitado para preferencias, listas, tareas, subtareas, recordatorios y tombstones. Los cambios remotos disparan una sincronización inmediata, manteniendo el ciclo periódico de un minuto como respaldo.
- Por seguridad, cada espacio SQLite local queda vinculado a una sola cuenta Supabase; una cuenta distinta se bloquea para evitar mezclar o subir datos de otro usuario.
- Al volver a Orbitask desde segundo plano, se fuerza un nuevo intento de sincronización.
- El indicador superior distingue entre `Sincronizando…`, `Nube conectada` y `Sin conexión`.
- El botón manual `Sincronizar ahora` se conserva para forzar una sincronización inmediata.

## Historial

- `v0.1-dev`: base visual, modelo Task y diseño responsive.
- `v0.2-dev`: CRUD, prioridades, fechas y filtros.
- `v0.3-dev`: SQLite y persistencia local.
- `v0.4-dev`: listas, subtareas, progreso y migración SQLite.
- `v0.4.1-dev`: limpieza de identidad Orbitask, migración de nombre de base de datos e iconos Material.
- `v0.5-dev`: recordatorios persistentes, edición y cancelación de avisos, y notificaciones locales validadas en Linux/Crostini.
- `v0.6-dev`: sistema de seis temas persistentes, paletas completas e identidad visual adaptable.
- `v0.7-dev`: autenticación con Supabase, sincronización bidireccional SQLite ↔ nube, tombstones de eliminación, preferencias por cuenta y Supabase Realtime.

## Configuración de Supabase

Orbitask no guarda claves privadas en el repositorio. Para habilitar cuentas, ejecuta la app con la URL del proyecto y la clave publicable de Supabase:

```bash
flutter run -d linux \\
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \\
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE
```

Sin estas variables Orbitask continúa funcionando en modo local, igual que en v0.6-dev. Nunca debe usarse una clave `service_role` dentro de la aplicación cliente.

## Roadmap

- Validar el flujo de confirmación de correo con una cuenta nueva usando el redirect configurado.
- Android.
- Windows.
- Preparar `v0.8-dev`.
- Versión estable `v1.0`.

## Tecnologías

- Flutter / Dart
- SQLite (`sqlite3`)
- `path_provider`

## Plataformas objetivo

- Android
- Windows
- Linux


### Redirect de confirmación de correo

Orbitask admite un redirect de autenticación opcional mediante:

```bash
--dart-define=SUPABASE_AUTH_REDIRECT_URL=<url-permitida-en-supabase>
```

La URL debe existir también en **Authentication → URL Configuration → Redirect URLs** del proyecto Supabase. Si no se define, Supabase usa el **Site URL** configurado en el proyecto.
