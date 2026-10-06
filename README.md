# Orbitask

**Tus tareas, siempre en órbita.**

Orbitask es una aplicación TO-DO multiplataforma desarrollada con Flutter para organizar tareas, listas, subtareas, prioridades, fechas, recordatorios y archivos adjuntos. Funciona de forma local y puede sincronizar datos entre dispositivos mediante Supabase.

## Estado actual — v1.0.0 estable

Orbitask v1.0.0 está validado en:

- Android
- Linux x64
- Windows x64
- Web

Estas son las plataformas soportadas oficialmente en v1.0.0. iOS y macOS continúan fuera del soporte oficial por ahora.

La versión actual incluye:

- CRUD completo de tareas.
- Captura rápida.
- Prioridades, fechas y horas límite.
- Listas personalizadas.
- Subtareas y progreso.
- Búsqueda, filtros y ordenamiento.
- Persistencia local con SQLite en Android, Linux y Windows.
- Persistencia local en navegador para Web.
- Recordatorios persistentes por tarea.
- Múltiples recordatorios relativos o personalizados.
- Edición, reprogramación y cancelación automática de recordatorios.
- Autenticación con Supabase.
- Inicio de sesión, registro, cierre de sesión y recuperación/cambio de contraseña.
- Sincronización bidireccional entre almacenamiento local y Supabase.
- Supabase Realtime.
- Resolución de cambios mediante `updated_at`.
- Cola/reintentos de sincronización y estado visible de conexión.
- Tombstones para eliminaciones definitivas.
- Papelera de tareas con restauración, vaciado y eliminación permanente.
- Sincronización de Papelera entre dispositivos.
- Archivos adjuntos en tareas.
- Vista previa de imágenes y descarga/apertura de documentos según plataforma.
- Perfil de usuario con nombre visible, username y avatar.
- Preferencias sincronizadas por cuenta.
- Interfaz adaptable para escritorio, móvil y navegador.
- Atajos de teclado en Windows, Linux y Web.
- Identidad nativa Orbitask en Android, Linux y Windows.
- Web compatible con navegadores modernos.
- 12 temas visuales.
- Icono propio de Orbitask en las plataformas nativas.

## Descargar Orbitask

Las compilaciones oficiales se publican en **GitHub Releases**:

https://github.com/darkhmdda/orbitask/releases/tag/v1.0.0

### Android

Descarga:

`Orbitask-v1.0.0-android.apk`

Después abre el APK desde Android y confirma la instalación.

Si Android lo solicita, permite temporalmente la instalación de aplicaciones desde esa fuente.

### Windows x64

#### Instalador recomendado

Descarga:

`Orbitask-v1.0.0-windows-setup.exe`

Ejecuta el instalador y sigue los pasos del asistente.

Orbitask se instalará como una aplicación normal de Windows y podrá abrirse desde el menú Inicio o desde el acceso directo si se seleccionó durante la instalación.

#### Versión portable

También está disponible:

`Orbitask-v1.0.0-windows-x64-portable.zip`

Para utilizarla:

1. Descomprime el ZIP completo.
2. Mantén `orbitask.exe` junto con las carpetas y archivos incluidos.
3. Ejecuta `orbitask.exe`.

La compilación actual no utiliza firma de código de Windows, por lo que Windows puede mostrar una advertencia de SmartScreen.

### Linux x64

#### Instalador recomendado

Descarga:

`Orbitask-v1.0.0-linux-amd64.deb`

En distribuciones basadas en Debian o Ubuntu:

```bash
sudo apt install ./Orbitask-v1.0.0-linux-amd64.deb
```

Después puedes abrir Orbitask desde el menú de aplicaciones o desde la terminal:

```bash
orbitask
```

#### Versión portable

También está disponible:

`Orbitask-v1.0.0-linux-x64-portable.tar.gz`

Ejemplo de uso:

```bash
mkdir -p ~/Applications/orbitask
cd ~/Applications/orbitask

curl -L \
  -o Orbitask-v1.0.0-linux-x64-portable.tar.gz \
  https://github.com/darkhmdda/orbitask/releases/download/v1.0.0/Orbitask-v1.0.0-linux-x64-portable.tar.gz

tar -xzf Orbitask-v1.0.0-linux-x64-portable.tar.gz
chmod +x orbitask
./orbitask
```

> La build publicada está dirigida a Linux x64. La disponibilidad de bibliotecas del sistema puede variar entre distribuciones.

### Web

Orbitask Web está disponible en:

https://darkhmdda.github.io/orbitask/

La versión Web utiliza almacenamiento persistente del navegador, autenticación y sincronización con Supabase. En v1.0.0 también incluye archivos adjuntos, perfil y atajos de teclado.

## Verificar descargas

La release v1.0.0 publica hashes SHA-256 separados por plataforma:

- `SHA256SUMS-android-v1.0.0.txt`
- `SHA256SUMS-linux-v1.0.0.txt`
- `SHA256SUMS-windows-v1.0.0.txt`

En Linux puedes verificar un archivo descargado con:

```bash
sha256sum Orbitask-v1.0.0-linux-amd64.deb
```

En Windows PowerShell:

```powershell
Get-FileHash .\Orbitask-v1.0.0-windows-setup.exe -Algorithm SHA256
```

## Archivos adjuntos

Orbitask v1.0.0 permite adjuntar archivos a las tareas y sincronizarlos entre dispositivos.

- Las imágenes pueden visualizarse desde Orbitask.
- Los documentos pueden descargarse o abrirse según las capacidades de cada plataforma.
- Linux, Windows, Android y Web cuentan con soporte de adjuntos.
- La sincronización utiliza Supabase junto con el almacenamiento local correspondiente a cada plataforma.

## Perfil

Cada cuenta puede configurar:

- Nombre visible.
- Username.
- Avatar.

Los datos del perfil se almacenan y sincronizan mediante Supabase.

## Atajos de teclado

Windows y Linux incluyen:

| Atajo | Acción |
| --- | --- |
| `Ctrl + N` | Nueva tarea |
| `Ctrl + F` | Buscar |
| `Ctrl + K` | Captura rápida |
| `Ctrl + L` | Administrar listas |
| `Ctrl + ,` | Ajustes |

En Web se utilizan combinaciones `Alt` para evitar conflictos con los atajos habituales del navegador:

| Atajo Web | Acción |
| --- | --- |
| `Alt + N` | Nueva tarea |
| `Alt + B` | Buscar |
| `Alt + Q` | Captura rápida |
| `Alt + L` | Administrar listas |
| `Alt + A` | Ajustes |

Android utiliza la interfaz táctil y no depende de estos atajos.

## Funcionamiento local y en la nube

Orbitask usa SQLite como almacenamiento local en Android, Linux y Windows.

En Web utiliza almacenamiento persistente del navegador para conservar los datos locales sin almacenar innecesariamente los bytes de adjuntos en `localStorage`.

La aplicación puede seguir trabajando localmente sin una conexión activa a Supabase.

Cuando Supabase está configurado y el usuario inicia sesión:

- los datos locales y remotos se combinan;
- los cambios se sincronizan automáticamente;
- Realtime permite reaccionar a cambios realizados desde otros dispositivos;
- los eventos Realtime se filtran por la cuenta autenticada;
- existe un ciclo periódico de sincronización;
- los fallos transitorios se reintentan automáticamente con backoff;
- el usuario también puede forzar una sincronización manual;
- cada espacio local queda vinculado a una cuenta para evitar mezclar información entre usuarios.

## Papelera

Eliminar una tarea desde la vista principal la mueve primero a la Papelera.

Desde la Papelera se puede restaurar, eliminar permanentemente o vaciar toda la Papelera.

Las eliminaciones definitivas utilizan tombstones para impedir que datos antiguos reaparezcan durante una sincronización posterior.

## Recordatorios

Orbitask permite programar múltiples recordatorios por tarea, relativos o con fecha y hora personalizada.

Los recordatorios pueden editarse, reprogramarse y cancelarse.

- Linux/Crostini: temporizadores de usuario del sistema.
- Android: notificaciones locales.
- Web: notificaciones del navegador cuando el usuario concede permiso y la aplicación permanece abierta.

El soporte Web de recordatorios persistentes con la pestaña cerrada requeriría Push/Service Worker y no forma parte de v1.0.0.

## Temas

Orbitask incluye 12 temas visuales:

- Rimuru
- Emilia
- Itsuki
- Rem
- Veldora
- Zoro
- Luffy
- Senku
- Marin Kitagawa
- Satoru Gojo
- Deku
- Eren

El tema elegido puede sincronizarse por cuenta.

## Configuración de desarrollo

### Requisitos principales

- Flutter
- Dart
- Git
- SQLite
- Proyecto Supabase opcional para autenticación y sincronización

Clona el repositorio:

```bash
git clone https://github.com/darkhmdda/orbitask.git
cd orbitask
flutter pub get
```

Orbitask no guarda claves privadas de Supabase en el repositorio. Para desarrollo se utilizan variables `dart-define`.

Ejemplo:

```bash
flutter run -d linux \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.darkhmdda.orbitask://login-callback
```

Nunca debe utilizarse una clave `service_role` dentro de la aplicación cliente.

### Web — desarrollo local

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=http://localhost:8080
```

Después:

```bash
cd build/web
python3 -m http.server 8080 --bind 0.0.0.0
```

El redirect usado para Web debe estar permitido en la configuración de autenticación de Supabase.

### Android — callback nativo

Orbitask utiliza:

```text
com.darkhmdda.orbitask://login-callback
```

Ese redirect debe estar permitido en Supabase.

## Builds de release

Los scripts y workflows de distribución requieren la configuración de Supabase para evitar generar accidentalmente una build oficial en modo solo local.

### Linux

```bash
export SUPABASE_URL=https://TU-PROYECTO.supabase.co
export SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE
export SUPABASE_AUTH_REDIRECT_URL=com.darkhmdda.orbitask://login-callback

bash installer/linux/build_release.sh
```

### Android

La firma Android se configura localmente mediante `android/key.properties`. El keystore y sus contraseñas no deben subirse al repositorio.

```bash
export SUPABASE_URL=https://TU-PROYECTO.supabase.co
export SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE
export SUPABASE_AUTH_REDIRECT_URL=com.darkhmdda.orbitask://login-callback

bash installer/android/build_release.sh
```

## Tecnologías

- Flutter
- Dart
- SQLite
- Supabase Auth
- Supabase Database
- Supabase Realtime
- Supabase Storage
- Git
- GitHub

## Historial principal

- `v0.1-dev`: base visual, modelo Task y diseño responsive.
- `v0.2-dev`: CRUD, prioridades, fechas y filtros.
- `v0.3-dev`: SQLite y persistencia local.
- `v0.4-dev`: listas, subtareas, progreso y migración SQLite.
- `v0.4.1-dev`: identidad Orbitask y migración de base de datos.
- `v0.5-dev`: recordatorios persistentes y notificaciones.
- `v0.6-dev`: sistema de temas.
- `v0.7-dev`: autenticación, sincronización bidireccional, tombstones y Realtime.
- `v0.8-dev`: consolidación multiplataforma Android, Linux y Windows.
- `v0.9-dev`: productividad, búsqueda, filtros, sincronización, cuenta, perfil, temas, builds y Papelera.
- `v0.9.0`: primera versión estable para Android, Linux x64 y Windows x64.
- `v0.9.1`: hardening, tests/CI, reproducibilidad y soporte oficial Web.
- `v1.0.0`: primera versión estable completa del proyecto, con Android, Linux, Windows y Web; adjuntos, perfil ampliado, atajos de teclado y distribución multiplataforma.

## Estado del proyecto

**Orbitask v1.0.0 es la versión estable actual.**

La release incluye:

- APK para Android.
- Instalador `.deb` para Linux x64.
- Versión portable para Linux x64.
- Instalador para Windows x64.
- Versión portable para Windows x64.
- Hashes SHA-256 por plataforma.
- Web desplegada mediante GitHub Pages.

v1.0.0 representa un punto de cierre estable del proyecto. El repositorio puede retomarse en el futuro para nuevas versiones sin que exista actualmente una versión posterior comprometida.

## Licencia

Orbitask se distribuye bajo la licencia MIT. Consulta el archivo `LICENSE` para ver los términos completos.
