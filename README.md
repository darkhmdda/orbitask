# Orbitask

**Tus tareas, siempre en órbita.**

Orbitask es una aplicación TO-DO multiplataforma desarrollada con Flutter para organizar tareas, listas, subtareas, prioridades, fechas y recordatorios.

Funciona de forma local y puede sincronizar datos entre dispositivos mediante Supabase.

## Estado actual — v0.9.0 estable

La versión estable actual de Orbitask es **v0.9.0**.

Orbitask v0.9.0 está validado oficialmente en:

- Android
- Linux x64
- Windows x64

Actualmente también se encuentra en desarrollo **v0.9.1**, una actualización centrada en hardening, pruebas automatizadas, mejoras de sincronización, reproducibilidad y la incorporación de **Web como cuarta plataforma oficial**.

### Estado de v0.9.1

Hasta el momento:

- Web: validado.
- Linux x64: validado.
- Android: validado.
- Windows x64: pendiente de validación final.
- PR a `main`: pendiente.
- Release estable `v0.9.1`: pendiente.

iOS y macOS todavía no forman parte de las plataformas soportadas oficialmente.

## Funciones principales

Orbitask incluye:

- CRUD completo de tareas.
- Captura rápida.
- Prioridades, fechas y horas límite.
- Listas personalizadas.
- Subtareas y progreso.
- Búsqueda, filtros y ordenamiento.
- Persistencia local con SQLite en Android, Linux y Windows.
- Persistencia local en navegador para Web.
- Recordatorios por tarea.
- Múltiples recordatorios relativos o personalizados.
- Edición, reprogramación y cancelación automática de recordatorios.
- Autenticación con Supabase.
- Inicio de sesión, registro y cierre de sesión.
- Recuperación y cambio de contraseña.
- Sincronización bidireccional entre almacenamiento local y Supabase.
- Supabase Realtime.
- Resolución de cambios mediante `updated_at`.
- Reintentos automáticos de sincronización.
- Estado visible de sincronización.
- Tombstones para eliminaciones definitivas.
- Papelera de tareas.
- Restauración de tareas.
- Vaciado de Papelera.
- Eliminación permanente.
- Sincronización de Papelera entre dispositivos.
- Perfil de usuario.
- Nombre y avatar.
- Preferencias sincronizadas por cuenta.
- Interfaz adaptable para escritorio, móvil y navegador.
- Identidad propia de Orbitask.
- 12 temas visuales.

## Descargar Orbitask

La versión estable actual se encuentra en GitHub Releases:

https://github.com/darkhmdda/orbitask/releases/tag/v0.9.0

### Android

Descarga:

`Orbitask-v0.9-android.apk`

Después abre el APK desde Android y confirma la instalación.

Si Android lo solicita, permite temporalmente la instalación de aplicaciones desde esa fuente.

### Windows x64

#### Instalador recomendado

Descarga:

`Orbitask-v0.9-windows-setup.exe`

Ejecuta el instalador y sigue los pasos del asistente.

Orbitask se instalará como una aplicación normal de Windows y podrá abrirse desde el menú Inicio.

#### Versión portable

También está disponible:

`Orbitask-v0.9-windows-x64-portable.zip`

Para utilizarla:

1. Descomprime el ZIP completo.
2. Mantén `orbitask.exe` junto con las carpetas y archivos incluidos.
3. Ejecuta `orbitask.exe`.

La compilación actual de Windows no utiliza firma de código comercial, por lo que Windows puede mostrar una advertencia de SmartScreen.

### Linux x64

#### Instalador recomendado

Descarga:

`Orbitask-v0.9-linux-amd64.deb`

En distribuciones basadas en Debian o Ubuntu:

```bash
sudo apt install ./Orbitask-v0.9-linux-amd64.deb
```

Después puedes abrir Orbitask desde el menú de aplicaciones o desde la terminal:

```bash
orbitask
```

#### Versión portable

También está disponible:

`Orbitask-v0.9-linux-x64-portable.tar.gz`

Ejemplo:

```bash
mkdir -p ~/Applications/orbitask
cd ~/Applications/orbitask

curl -L \
  -o Orbitask-v0.9-linux-x64-portable.tar.gz \
  https://github.com/darkhmdda/orbitask/releases/download/v0.9.0/Orbitask-v0.9-linux-x64-portable.tar.gz

tar -xzf Orbitask-v0.9-linux-x64-portable.tar.gz
chmod +x orbitask
./orbitask
```

Para volver a abrir la versión portable:

```bash
~/Applications/orbitask/orbitask
```

> La build publicada está dirigida a Linux x64. La disponibilidad de bibliotecas del sistema puede variar entre distribuciones.

## Web

Orbitask Web forma parte del ciclo de desarrollo de **v0.9.1**.

Actualmente ya fue validado con:

- build de producción;
- persistencia local en navegador;
- inicio de sesión con Supabase;
- carga de tareas y listas;
- creación y edición de tareas;
- sincronización con Android y Linux;
- Papelera;
- restauración;
- eliminación definitiva;
- perfil de usuario;
- Supabase Realtime;
- reintentos automáticos de sincronización.

La versión Web todavía no forma parte de la release estable `v0.9.0`.

## Verificar descargas

Las releases incluyen:

`SHA256SUMS.txt`

Este archivo contiene los hashes SHA-256 de las compilaciones publicadas.

En Linux:

```bash
sha256sum -c SHA256SUMS.txt
```

En Windows PowerShell:

```powershell
Get-FileHash .\Orbitask-v0.9-windows-setup.exe -Algorithm SHA256
```

## Funcionamiento local y en la nube

Orbitask utiliza SQLite como almacenamiento local en Android, Linux y Windows.

En Web utiliza almacenamiento persistente del navegador.

La aplicación puede seguir trabajando localmente sin una conexión activa a Supabase.

Cuando Supabase está configurado y el usuario inicia sesión:

- los datos locales y remotos se combinan;
- los cambios se sincronizan automáticamente;
- Realtime permite reaccionar a cambios realizados desde otros dispositivos;
- los eventos Realtime se filtran por la cuenta autenticada;
- existe sincronización periódica;
- los errores transitorios se reintentan automáticamente;
- el usuario puede forzar una sincronización manual;
- cada espacio local queda vinculado a una cuenta para evitar mezclar datos entre usuarios.

## Papelera

Eliminar una tarea desde la vista principal la mueve primero a la Papelera.

Desde la Papelera se puede:

- restaurar una tarea;
- eliminarla permanentemente;
- vaciar toda la Papelera.

Las tareas enviadas a la Papelera también sincronizan su estado entre los dispositivos de la misma cuenta.

La eliminación permanente utiliza tombstones para impedir que información antigua reaparezca durante una sincronización posterior.

## Recordatorios

Orbitask permite programar recordatorios por tarea.

Los recordatorios pueden ser:

- relativos a la fecha límite;
- personalizados con fecha y hora.

También pueden editarse, reprogramarse y cancelarse.

### Android

Los recordatorios utilizan notificaciones locales de Android y pueden funcionar aunque Orbitask esté cerrado.

### Linux

Los recordatorios persistentes utilizan temporizadores de usuario de `systemd` y `notify-send`.

Esto permite que el recordatorio pueda ejecutarse aunque Orbitask ya no esté abierto.

### Web

Los recordatorios Web funcionan mientras Orbitask permanece abierto en la pestaña.

Actualmente Orbitask Web no utiliza notificaciones push desde servidor, por lo que no puede garantizar recordatorios persistentes con el navegador completamente cerrado.

### Sincronización de recordatorios

Los datos de los recordatorios se sincronizan mediante Supabase.

Sin embargo, cada dispositivo programa sus propias notificaciones locales.

Por ejemplo, un recordatorio creado en un dispositivo puede sincronizarse con otro, pero el segundo dispositivo necesita recibir y procesar ese cambio antes de la hora del aviso para poder programar su notificación local.

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

El tema seleccionado puede sincronizarse por cuenta.

## Configuración de desarrollo

### Requisitos principales

- Flutter
- Dart
- Git
- SQLite
- Supabase para autenticación y sincronización

Clona el repositorio:

```bash
git clone https://github.com/darkhmdda/orbitask.git
cd orbitask
flutter pub get
```

Orbitask no almacena claves privadas de Supabase en el repositorio.

Para desarrollo se utilizan variables `dart-define`.

Nunca debe utilizarse una clave `service_role` dentro de la aplicación cliente.

### Linux

Ejemplo:

```bash
flutter run -d linux \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=https://github.com/darkhmdda/orbitask
```

Para generar una release Linux preparada para Supabase:

```bash
export SUPABASE_URL=https://TU-PROYECTO.supabase.co
export SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE
export SUPABASE_AUTH_REDIRECT_URL=https://github.com/darkhmdda/orbitask

bash installer/linux/build_release.sh
```

El script evita generar accidentalmente un paquete oficial sin configuración de Supabase.

### Android

Orbitask utiliza el callback:

```text
com.darkhmdda.orbitask://login-callback
```

Debe estar permitido también en:

**Supabase → Authentication → URL Configuration → Redirect URLs**

Ejemplo:

```bash
flutter run -d <ANDROID_DEVICE> \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.darkhmdda.orbitask://login-callback
```

Para generar el APK release:

```bash
export SUPABASE_URL=https://TU-PROYECTO.supabase.co
export SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE
export SUPABASE_AUTH_REDIRECT_URL=com.darkhmdda.orbitask://login-callback

bash installer/android/build_release.sh
```

El script requiere que exista la configuración local de firma Android antes de construir la release.

### Web

Para generar Orbitask Web:

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=http://localhost:8080
```

Para probarlo localmente:

```bash
cd build/web
python3 -m http.server 8080 --bind 0.0.0.0
```

Después abre:

```text
http://localhost:8080
```

El redirect utilizado debe estar permitido en la configuración de autenticación de Supabase.

## Pruebas y CI

Orbitask cuenta actualmente con:

- pruebas automatizadas de modelos;
- pruebas de repositorio SQLite;
- 14 tests automatizados;
- `flutter analyze`;
- `flutter test`;
- build Web dentro de GitHub Actions;
- Dependabot para revisar actualizaciones de dependencias.

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
- GitHub Actions

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
- `v0.9-dev`: productividad, búsqueda, filtros, ordenamiento, mejoras de sincronización, perfil, identidad visual, builds de distribución y Papelera.
- `v0.9.0`: primera versión estable del ciclo v0.9.
- `v0.9.1` (en desarrollo): hardening, Web, tests, CI, reproducibilidad, mejoras de sincronización y empaquetado.

## Estado del proyecto

**v0.9.0** es la versión estable actual.

Está publicada para:

- Android
- Linux x64
- Windows x64

La antigua `v0.9-dev` se conserva como prerelease histórica.

El trabajo de `v0.9.1` ya tiene validados:

- Web;
- Linux x64;
- Android.

Windows x64 todavía debe pasar la validación final antes de cerrar la actualización.

Después de completar esa validación se realizará:

1. PR de `chore/v0.9.1-hardening` hacia `main`.
2. Revisión de CI.
3. Merge.
4. Tag `v0.9.1`.
5. Generación de artefactos finales.
6. Generación de `SHA256SUMS.txt`.
7. Publicación de GitHub Release `v0.9.1`.

## Licencia

Orbitask se distribuye bajo la licencia MIT.

Consulta el archivo `LICENSE` para ver los términos completos.