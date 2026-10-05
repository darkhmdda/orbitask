# Orbitask v0.9.1 — Checklist de validación final

## Validación automática

- [ ] GitHub Actions: Analyze and test
- [ ] GitHub Actions: Build Web
- [x] flutter analyze sin issues
- [x] flutter test con todos los tests en PASS

## Web

- [x] Build de producción Web
- [x] Persistencia local tras recargar
- [x] Inicio de sesión con Supabase
- [x] Carga de listas y tareas de la cuenta
- [x] Creación de tarea y sincronización con Android
- [x] Papelera sincronizada
- [x] Restauración sincronizada
- [x] Eliminación definitiva sincronizada
- [x] Identidad Web Orbitask

## Linux x64

- [x] flutter build linux --release
- [x] Generar paquete .deb
- [x] Verificar versión 0.9.1
- [x] Abrir Orbitask
- [x] Crear/editar/completar tarea
- [x] Sincronización
- [x] Recordatorios en Windows
- [x] Recordatorio creado en Windows recibido también en Android tras sincronización con Supabase
- [x] Recordatorio persistente
- [x] Papelera/restauración/eliminación definitiva

## Android

- [x] flutter build apk --release
- [x] Verificar versión 0.9.1+11
- [x] APK firmado con esquema v2
- [x] Instalar APK de release
- [x] Inicio de sesión
- [x] Crear/editar/completar tarea
- [x] Sincronización con Web/Linux
- [x] Recordatorios
- [x] Papelera/restauración/eliminación definitiva

## Windows x64

- [x] flutter build windows --release
- [x] Generar instalador Inno Setup
- [x] Verificar nombre Orbitask-v0.9.1-windows-setup.exe
- [x] Instalar/abrir Orbitask
- [x] Inicio de sesión
- [x] Crear/editar/completar tarea
- [x] Sincronización
- [x] Papelera/restauración/eliminación definitiva

## Cierre

- [x] Mejora de sincronización multiplataforma validada con analyze, tests y build Web

- [x] Sincronización Windows optimizada y validada

- [x] Confirmar CI en verde
- [ ] Confirmar rama limpia
- [ ] Crear PR de chore/v0.9.1-hardening a main
- [ ] Revisar required checks de main
- [ ] Merge del PR
- [ ] Crear tag v0.9.1
- [ ] Generar artefactos finales
- [ ] Generar SHA256SUMS.txt
- [ ] Publicar GitHub Release v0.9.1
