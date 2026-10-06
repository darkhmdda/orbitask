# Checklist de cierre — Orbitask v1.0.0

Fecha de revisión: 2026-10-05

Este documento registra la validación final de Orbitask v1.0.0 antes de su cierre temporal como versión estable.

## Versión

- [x] `pubspec.yaml` en `1.0.0+12`.
- [x] Release `v1.0.0` creada en GitHub.
- [x] Artefactos oficiales publicados.
- [x] Web desplegada mediante GitHub Pages.

## Plataformas oficiales

- [x] Android.
- [x] Linux x64.
- [x] Windows x64.
- [x] Web.

iOS y macOS permanecen fuera del soporte oficial de v1.0.0.

## Funcionalidad principal

- [x] CRUD de tareas.
- [x] Listas personalizadas.
- [x] Subtareas y progreso.
- [x] Prioridades.
- [x] Fechas y horas límite.
- [x] Búsqueda, filtros y ordenamiento.
- [x] Captura rápida.
- [x] Recordatorios.
- [x] Papelera y restauración.
- [x] Eliminación definitiva mediante tombstones.
- [x] Autenticación Supabase.
- [x] Sincronización bidireccional.
- [x] Supabase Realtime.
- [x] Perfil con nombre visible, username y avatar.
- [x] Temas visuales.
- [x] Archivos adjuntos.
- [x] Atajos de teclado en escritorio y Web.

## Validación por plataforma

### Android

- [x] Probado en dispositivo físico Android 15 / ARM64.
- [x] Autenticación y sincronización funcionales.
- [x] Perfil funcional.
- [x] Adjuntos funcionales.
- [x] Build release firmada generada correctamente.
- [x] APK publicado en GitHub Releases.

### Linux x64

- [x] Aplicación validada en Linux/Crostini.
- [x] Atajos de teclado validados.
- [x] Perfil validado.
- [x] Adjuntos validados.
- [x] Selector de temas corregido para entornos sin fuentes emoji.
- [x] Paquete `.deb` generado y publicado.
- [x] Paquete `.deb` v1.0.0 instalado y validado.
- [x] Portable `.tar.gz` publicado.

### Windows x64

- [x] Aplicación validada.
- [x] Atajos de teclado validados.
- [x] Perfil validado.
- [x] Adjuntos y descargas validados.
- [x] Instalador publicado.
- [x] Portable publicado.

### Web

- [x] Aplicación desplegada mediante GitHub Pages.
- [x] Autenticación y sincronización validadas.
- [x] Perfil validado.
- [x] Adjuntos validados.
- [x] Atajos Web validados.
- [x] Temas validados.
- [x] Corregido el exceso de cuota de `localStorage` provocado por bytes de adjuntos.

## Artefactos publicados

- [x] `Orbitask-v1.0.0-android.apk`
- [x] `Orbitask-v1.0.0-linux-amd64.deb`
- [x] `Orbitask-v1.0.0-linux-x64-portable.tar.gz`
- [x] `Orbitask-v1.0.0-windows-setup.exe`
- [x] `Orbitask-v1.0.0-windows-x64-portable.zip`
- [x] `SHA256SUMS-android-v1.0.0.txt`
- [x] `SHA256SUMS-linux-v1.0.0.txt`
- [x] `SHA256SUMS-windows-v1.0.0.txt`

## SHA-256 conocidos

```text
bd54e94f3c5a3b536b9f174337ac6bae62a52d2f035abb47802b4d8dcdfec93a  Orbitask-v1.0.0-android.apk
8111b9d038ab2a47b6abfa86b5a4976cc80ec38f36a90ea5514d12d8d9d081b0  Orbitask-v1.0.0-linux-amd64.deb
7d794a83927a3708f17d038f8ce263219876bd5150eefced4d3250795b18ba61  Orbitask-v1.0.0-linux-x64-portable.tar.gz
91e192f85c74c07c22d0c86b51c433850c28d16a3e1a81eb54c1094ff12bcdd8  Orbitask-v1.0.0-windows-setup.exe
80322f18d067af9dd8f695cdd8ea6b86c7f4bc7b845c0cd1f3dc949954972d0e  Orbitask-v1.0.0-windows-x64-portable.zip
```

## Repositorio y CI

- [x] Protección de `main`.
- [x] Flutter CI configurado.
- [x] Tests automatizados.
- [x] Build Web en CI.
- [x] Deploy Web automático.
- [x] Scripts de release Android, Linux y Windows.
- [x] Dependabot configurado.
- [x] Licencia MIT.

## Pendientes de cierre del repositorio

Estos puntos no invalidan las builds publicadas, pero forman parte de la limpieza final del repositorio:

- [ ] Integrar la migración que permite tombstones de tipo `attachment` en Supabase.
- [ ] Actualizar README a v1.0.0.
- [ ] Actualizar CHANGELOG a v1.0.0.
- [ ] Actualizar las notas de la release v1.0.0.
- [ ] Limpiar workflows históricos que ya no sean necesarios.
- [ ] Resolver o clasificar PRs de Dependabot pendientes.
- [ ] Ejecutar y confirmar CI final de `main`.

## Resultado

Orbitask v1.0.0 cuenta con builds oficiales para Android, Linux x64 y Windows x64, además de Web desplegada. La funcionalidad principal fue validada en las cuatro plataformas oficiales.

Este checklist se conserva como registro del cierre temporal de v1.0.0 y puede actualizarse al completar la limpieza final del repositorio.
