# Builds, CI/CD y distribución

Este documento explica cómo se compila Orbitask para cada plataforma, qué hacen los workflows de GitHub Actions y cómo se prepara una release. Refleja el repositorio en la versión **1.0.1+13**.

## Versión

La versión de la aplicación está en `pubspec.yaml` (`version: 1.0.1+13`: nombre de versión y número de build). Debe coincidir con la última entrada del [CHANGELOG](../CHANGELOG.md).

## Configuración de Supabase en las builds

La app recibe su configuración en tiempo de compilación con `--dart-define`:

| Variable | Descripción |
| -------- | ----------- |
| `SUPABASE_URL` | URL del proyecto de Supabase |
| `SUPABASE_PUBLISHABLE_KEY` | Clave **publicable** (nunca `service_role`) |
| `SUPABASE_AUTH_REDIRECT_URL` | Redirect de autenticación de la plataforma |

Sin `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` la app arranca en modo solo local. Los scripts de release **exigen** las variables para evitar publicar por accidente una build oficial sin nube.

Valores de `SUPABASE_AUTH_REDIRECT_URL` por plataforma:

| Plataforma | Valor |
| ---------- | ----- |
| Android, Windows y Linux | `com.darkhmdda.orbitask://login-callback` |
| Web | La URL pública (por ejemplo `https://darkhmdda.github.io/orbitask/`) o `http://localhost:8080` en desarrollo |

## Android

Script: `installer/android/build_release.sh`.

```bash
export SUPABASE_URL=https://TU-PROYECTO.supabase.co
export SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE
# Opcional; por defecto es com.darkhmdda.orbitask://login-callback
export SUPABASE_AUTH_REDIRECT_URL=com.darkhmdda.orbitask://login-callback

bash installer/android/build_release.sh
```

Genera `build/app/outputs/flutter-apk/app-release.apk`.

**Firma.** La build de release requiere `android/key.properties` con los datos del keystore; sin él, Gradle aborta con un mensaje claro. El keystore y sus contraseñas **no se versionan** y deben respaldarse en un lugar seguro fuera del repositorio. Si se pierde, no se podrán publicar actualizaciones firmadas con la misma clave.

**Permisos declarados:** `INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` y `SCHEDULE_EXACT_ALARM`.

## Linux x64

Scripts en `installer/linux/`:

| Archivo | Función |
| ------- | ------- |
| `build_release.sh` | Compila la build de release |
| `build_deb.sh` | Empaqueta el `.deb` |
| `DEBIAN/control` | Metadatos del paquete |
| `usr/share/applications/orbitask.desktop` | Entrada del menú de aplicaciones |

Entregables: `Orbitask-<versión>-linux-amd64.deb` y `Orbitask-<versión>-linux-x64-portable.tar.gz`. Instalación:

```bash
sudo apt install ./Orbitask-<versión>-linux-amd64.deb
```

Los recordatorios en Linux usan `systemd-run` y `notify-send`; el paquete debe poder contar con ellos en el sistema destino.

## Windows x64

Archivos: `installer/build_windows_installer.ps1` y `installer/orbitask.iss` (script de Inno Setup).

Entregables: instalador `Orbitask-<versión>-windows-setup.exe` y versión portable `Orbitask-<versión>-windows-x64-portable.zip`. La compilación **no tiene firma de código**, por lo que Windows puede mostrar la advertencia de SmartScreen.

## Web

La web se compila con `flutter build web --release --base-href /orbitask/` y se publica en GitHub Pages desde el workflow `deploy_web.yml`. Para probarla en local:

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=http://localhost:8080

cd build/web
python3 -m http.server 8080 --bind 0.0.0.0
```

La URL de redirect usada debe estar permitida en la configuración de Auth de Supabase.

## Workflows de GitHub Actions

| Workflow | Cuándo se ejecuta | Qué hace |
| -------- | ----------------- | -------- |
| `flutter_ci.yml` | Push y pull request hacia `main` | `flutter analyze`, `flutter test` y `flutter build web` |
| `deploy_web.yml` | Push a `main` y manual | Compila la web y la despliega en GitHub Pages |
| `release_linux_v1.yml` | Manual, y push a `main` solo si cambia el propio workflow | Compila Linux, calcula SHA-256 y sube los artefactos a la release |
| `release_windows_v1.yml` | Manual | Compila Windows, crea el ZIP portable y el instalador con Inno Setup |
| `dependabot.yml` | Semanal | Propone actualizaciones de dependencias de `pub` y de GitHub Actions |

### Aspectos a tener en cuenta

- **Cada push a `main` despliega la web.** Todo lo que llegue a `main` queda público en la Web al momento.
- **Los workflows de release están atados a v1.0.0.** Sus nombres, la versión pasada al instalador de Windows y la release a la que suben los archivos están escritos a mano. Para una versión nueva hay que parametrizarlos o duplicarlos.
- **La configuración de Supabase está dentro de los workflows.** `deploy_web.yml` y `release_windows_v1.yml` llevan la URL y la clave publicable escritas directamente, y `release_linux_v1.yml` las **extrae con una expresión regular del archivo del workflow de Windows**. Funciona, pero es frágil: cambiar el formato de esa línea rompe la build de Linux. Lo recomendable es usar variables del repositorio (`vars.*`).
- **Android no tiene workflow de release.** El APK se compila en local, porque la clave de firma no está en el repositorio.

## Flujo de ramas recomendado

- `main` es la línea estable. Todo lo que entra se despliega en la Web.
- El trabajo nuevo se hace en una rama aparte (por ejemplo `develop` o una rama por tarea) y se integra a `main` mediante pull request, para que `flutter_ci.yml` valide antes de fusionar.
- Una release se marca con un tag (`vX.Y.Z`) sobre `main`. No se modifican tags ya publicados.

## Proceso de release

1. Actualizar la versión en `pubspec.yaml`.
2. Mover las entradas de "Sin publicar" del CHANGELOG a la nueva versión, con fecha.
3. Comprobar en local: `flutter analyze` y `flutter test`.
4. Compilar cada plataforma (Android en local; Linux y Windows por workflow o en local).
5. Generar los hashes SHA-256 por plataforma (`SHA256SUMS-<plataforma>-<versión>.txt`).
6. Probar la instalación de cada artefacto en un entorno limpio.
7. Crear el tag y la release en GitHub y subir artefactos y hashes.
8. Confirmar que la Web desplegada corresponde a la versión.

Los checklists de las versiones 0.9.1 y 1.0.0 (`docs/release-checklist-*.md` y `docs/release-*-closure.md`) se conservan como registro histórico.

## Verificar una descarga

```bash
# Linux
sha256sum Orbitask-<versión>-linux-amd64.deb
```

```powershell
# Windows (PowerShell)
Get-FileHash .\Orbitask-<versión>-windows-setup.exe -Algorithm SHA256
```

El resultado debe coincidir con el valor del archivo `SHA256SUMS-<plataforma>-<versión>.txt` de la release.
