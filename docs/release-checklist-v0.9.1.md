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
- [ ] Crear/editar/completar tarea
- [x] Sincronización con Supabase
- [ ] Recordatorio persistente
- [ ] Papelera/restauración/eliminación definitiva

## Android

- [ ] flutter build apk --release
- [ ] Verificar versión 0.9.1+11
- [ ] Instalar APK de release
- [ ] Inicio de sesión
- [ ] Crear/editar/completar tarea
- [ ] Sincronización con Web/Linux
- [ ] Recordatorios
- [ ] Papelera/restauración/eliminación definitiva

## Windows x64

- [ ] flutter build windows --release
- [ ] Generar instalador Inno Setup
- [ ] Verificar nombre Orbitask-v0.9.1-windows-setup.exe
- [ ] Instalar/abrir Orbitask
- [ ] Inicio de sesión
- [ ] Crear/editar/completar tarea
- [ ] Sincronización
- [ ] Papelera/restauración/eliminación definitiva

## Cierre

- [ ] Confirmar CI en verde
- [ ] Confirmar rama limpia
- [ ] Crear PR de chore/v0.9.1-hardening a main
- [ ] Revisar required checks de main
- [ ] Merge del PR
- [ ] Crear tag v0.9.1
- [ ] Generar artefactos finales
- [ ] Generar SHA256SUMS.txt
- [ ] Publicar GitHub Release v0.9.1
