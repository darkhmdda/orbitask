# Changelog

Todos los cambios importantes de Orbitask se documentan en este archivo.

## [0.9.1] - 2026-10-05

### Añadido

- Soporte oficial de Web como cuarta plataforma de Orbitask.
- Persistencia local en navegador para listas, tareas, subtareas, recordatorios, preferencias y tombstones.
- Sincronización Web con Supabase y otros dispositivos.
- Build Web validado automáticamente en GitHub Actions.
- Tests automatizados de modelos y repositorio SQLite.
- Reproducibilidad del esquema Supabase mediante migraciones versionadas.
- Dependabot para revisiones semanales de dependencias.
- Licencia MIT.
- Automatización de versión para paquetes Linux y Windows.
- Dependencias runtime declaradas en el paquete Debian.

### Mejorado

- Realtime filtrado por cuenta y por tablas de Orbitask.
- Reintentos automáticos de sincronización con backoff.
- Separación de almacenamiento, repositorio, sincronización y notificaciones entre Web y plataformas nativas.
- Identidad Web actualizada de `todo_app` a Orbitask.
- README actualizado con Web, desarrollo, sincronización y licencia.
- Protección de `main` mediante reglas de GitHub.
- Sincronización más reactiva en Windows, Android, Linux y Web.
- Refactor de `home_screen.dart` por responsabilidades: widgets auxiliares, sincronización, acciones de tareas/Papelera y ajustes/cuenta.

### Validado

- `flutter analyze` sin errores.
- 14 tests automatizados.
- Build de producción Web correcta.
- Sincronización real Web ↔ Supabase ↔ Android validada con creación, Papelera, restauración y eliminación definitiva.
- Linux, Android y Windows validados funcionalmente para v0.9.1.
- Refactor de Home validado con `flutter analyze` sin issues y 14/14 tests.

## [0.9.0] - 2026-10-05

Primera versión estable del ciclo v0.9 para Android, Linux x64 y Windows x64.
