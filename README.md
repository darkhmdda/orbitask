# Orbitask

**Tus tareas, siempre en órbita.**

Orbitask es una aplicación de tareas multiplataforma hecha con Flutter. Organiza tareas en listas, con subtareas, prioridades, fechas, recordatorios y archivos adjuntos. Funciona sin conexión con una base de datos local y, si inicias sesión, sincroniza entre dispositivos mediante Supabase.

- **Web:** <https://darkhmdda.github.io/orbitask/>
- **Descargas (Android, Windows, Linux):** [GitHub Releases](https://github.com/darkhmdda/orbitask/releases)
- **Licencia:** MIT

## Estado

La versión del código en `main` es **1.0.1+13**. Es un hotfix de estabilidad de la sincronización sobre la v1.0.0 (consulta el [CHANGELOG](CHANGELOG.md)). La versión Web se despliega desde `main`, por lo que siempre refleja el código más reciente.

| Plataforma | Estado |
| ---------- | ------ |
| Android | Soportada |
| Windows x64 | Soportada |
| Linux x64 | Soportada |
| Web | Soportada |
| iOS / macOS | Fuera de soporte oficial (las carpetas existen, pero no se compilan ni se prueban) |

## Funciones

- Tareas con prioridad, fecha y hora límite, descripción y archivos adjuntos (hasta 15 MB por archivo).
- Listas personalizadas, subtareas con progreso, búsqueda, filtros y ordenamiento.
- Captura rápida y atajos de teclado.
- Múltiples recordatorios por tarea (relativos o con fecha y hora personalizada).
- Papelera con restauración, vaciado y eliminación permanente.
- Cuenta con correo y contraseña, perfil (nombre visible, username y avatar) y preferencias sincronizadas.
- Sincronización entre dispositivos con Supabase (Realtime más sondeo periódico) y modo local sin conexión.
- 14 temas de color, adaptables a escritorio, móvil y navegador.
- Widgets de pantalla de inicio en Android (calendario, resumen y "hoy"). Están en el código pero todavía no forman parte de ninguna release, y su diseño está pendiente de revisión.

## Instalación

Las compilaciones oficiales se publican en [GitHub Releases](https://github.com/darkhmdda/orbitask/releases), junto con archivos `SHA256SUMS` por plataforma.

### Android

Descarga el APK, ábrelo y confirma la instalación. Si Android lo pide, permite temporalmente instalar desde esa fuente.

### Windows x64

Usa el instalador `*-windows-setup.exe` o la versión portable `*-windows-x64-portable.zip` (descomprime el ZIP completo y ejecuta `orbitask.exe`). La build no tiene firma de código, así que Windows puede mostrar una advertencia de SmartScreen.

### Linux x64

En Debian o Ubuntu:

```bash
sudo apt install ./Orbitask-<versión>-linux-amd64.deb
orbitask
```

También hay una versión portable `*-linux-x64-portable.tar.gz`. La disponibilidad de bibliotecas del sistema puede variar entre distribuciones.

### Verificar una descarga

```bash
# Linux
sha256sum Orbitask-<versión>-linux-amd64.deb
```

```powershell
# Windows (PowerShell)
Get-FileHash .\Orbitask-<versión>-windows-setup.exe -Algorithm SHA256
```

Compara el resultado con el archivo `SHA256SUMS-<plataforma>-<versión>.txt` de la release.

## Atajos de teclado

| Acción | Windows / Linux | Web |
| ------ | --------------- | --- |
| Nueva tarea | `Ctrl + N` | `Alt + N` |
| Buscar | `Ctrl + F` | `Alt + B` |
| Captura rápida | `Ctrl + K` | `Alt + Q` |
| Administrar listas | `Ctrl + L` | `Alt + L` |
| Ajustes | `Ctrl + ,` | `Alt + A` |

En Web se usa `Alt` para no chocar con los atajos del navegador. Android usa la interfaz táctil.

## Desarrollo

Requisitos: Flutter (canal stable, Dart ^3.13), Git y, opcionalmente, un proyecto de Supabase.

```bash
git clone https://github.com/darkhmdda/orbitask.git
cd orbitask
flutter pub get
flutter analyze
flutter test
```

Sin configuración de Supabase, la app arranca en **modo solo local**. Para activar cuenta y sincronización, pasa tu proyecto con `--dart-define`:

```bash
flutter run -d linux \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.darkhmdda.orbitask://login-callback
```

Usa siempre la clave **publicable**. Nunca pongas una clave `service_role` dentro de la app. Para preparar tu propio proyecto de Supabase (migraciones, RLS y Storage), mira [docs/DATOS_Y_SUPABASE.md](docs/DATOS_Y_SUPABASE.md).

## Documentación

| Documento | Contenido |
| --------- | --------- |
| [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) | Capas, estructura del código, plataformas, recordatorios y widgets de Android |
| [docs/DATOS_Y_SUPABASE.md](docs/DATOS_Y_SUPABASE.md) | Modelo de datos local y remoto, RLS, Storage, autenticación y seguridad |
| [docs/SINCRONIZACION.md](docs/SINCRONIZACION.md) | Cómo funciona la sincronización, conflictos, tombstones y limitaciones conocidas |
| [docs/BUILDS_Y_DISTRIBUCION.md](docs/BUILDS_Y_DISTRIBUCION.md) | Builds por plataforma, firma, CI/CD y proceso de release |
| [CHANGELOG.md](CHANGELOG.md) | Historial de cambios por versión |

## Licencia

MIT. Consulta el archivo [LICENSE](LICENSE).
