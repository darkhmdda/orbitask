# Changelog

Todos los cambios importantes de Orbitask se documentan en este archivo.

## [1.0.0] - 2026-10-05

Primera versión estable completa de Orbitask y punto de cierre temporal del proyecto.

### Añadido

- Archivos adjuntos en tareas con soporte en Android, Linux, Windows y Web.
- Vista previa de imágenes y apertura/descarga de documentos según las capacidades de cada plataforma.
- Sincronización de adjuntos mediante Supabase.
- Nombre visible, username y avatar para el perfil de usuario.
- Atajos de teclado en Windows y Linux:
  - `Ctrl + N`: nueva tarea.
  - `Ctrl + F`: buscar.
  - `Ctrl + K`: captura rápida.
  - `Ctrl + L`: administrar listas.
  - `Ctrl + ,`: ajustes.
- Atajos Web adaptados para evitar conflictos con el navegador:
  - `Alt + N`: nueva tarea.
  - `Alt + B`: buscar.
  - `Alt + Q`: captura rápida.
  - `Alt + L`: administrar listas.
  - `Alt + A`: ajustes.
- Builds oficiales v1.0.0 para Android, Linux x64 y Windows x64.
- APK firmado para Android.
- Paquete `.deb` y versión portable `.tar.gz` para Linux x64.
- Instalador y versión portable `.zip` para Windows x64.
- Archivos SHA-256 separados para Android, Linux y Windows.
- Workflow de publicación para Linux v1.0.0.

### Mejorado

- Experiencia de escritorio compartida entre Windows y Linux para los atajos de teclado.
- Compatibilidad de los atajos con Web sin interferir con Android.
- Manejo de archivos adjuntos específico para cada plataforma.
- Perfil sincronizado mediante Supabase.
- Selector de temas en Linux para no depender de fuentes de emoji ausentes en algunas distribuciones.
- Persistencia Web para evitar almacenar los bytes de adjuntos directamente en `localStorage`.
- Recarga de bytes de adjuntos Web cuando no están persistidos localmente.
- Distribución multiplataforma consolidada alrededor de la identidad Orbitask.
- Preparación de release para Windows y Linux mediante GitHub Actions.

### Corregido

- Iconos de temas que podían desaparecer en Linux por falta de fuentes de emoji.
- Cuota de `localStorage` en Web al trabajar con archivos adjuntos.
- Publicación automática de la release Windows v1.0.0 cuando la release todavía no existía.
- Manejo de descarga de adjuntos en Windows.
- Sincronización de eliminaciones de adjuntos: se prepara la restricción de `sync_deletions` para aceptar el tipo `attachment`.

### Validado

- Android 15 / ARM64 probado en dispositivo físico.
- APK release Android generado correctamente con firma de release.
- Linux x64 probado con el paquete `.deb` v1.0.0 instalado sobre una instalación anterior.
- Windows x64 validado con instalador y build portable.
- Web validada con adjuntos, perfil, temas y atajos de teclado.
- Sincronización entre las plataformas soportadas y Supabase.
- Perfil con nombre visible, username y avatar.
- Adjuntos en las cuatro plataformas soportadas.
- Atajos de teclado en Windows, Linux y Web.
- Release oficial v1.0.0 publicada con artefactos de Android, Linux y Windows.

### Plataformas oficiales

- Android.
- Linux x64.
- Windows x64.
- Web.

iOS y macOS no forman parte del soporte oficial de Orbitask v1.0.0.

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
