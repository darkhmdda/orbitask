# Orbitask

**Tus tareas, siempre en órbita.**

Orbitask es una aplicación TO-DO multiplataforma desarrollada con Flutter para organizar tareas, listas, subtareas, prioridades, fechas y recordatorios. Funciona de forma local con SQLite y puede sincronizar datos entre dispositivos mediante Supabase.

## Estado actual — v0.9.0 estable

Orbitask v0.9.0 está validado en:

- Android
- Linux x64
- Windows x64

Estas son las plataformas soportadas oficialmente en v0.9.0.

En el ciclo de hardening posterior a v0.9.0, **Web ya fue habilitado y validado como plataforma oficial para la siguiente versión estable**. iOS y macOS continúan fuera del soporte oficial por ahora.

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
- Perfil de usuario con nombre y avatar.
- Preferencias sincronizadas por cuenta.
- Interfaz adaptable para escritorio, móvil y navegador.
- Identidad nativa Orbitask en Android, Linux y Windows.
- Web compatible con navegadores modernos.
- 12 temas visuales.
- Icono propio de Orbitask en las plataformas nativas.

## Descargar Orbitask

Las compilaciones se publican en **GitHub Releases**:

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

Orbitask se instalará como una aplicación normal de Windows y podrá abrirse desde el menú Inicio o desde el acceso directo si se seleccionó durante la instalación.

#### Versión portable

También está disponible:

`Orbitask-v0.9-windows-x64-portable.zip`

Para utilizarla:

1. Descomprime el ZIP completo.
2. Mantén `orbitask.exe` junto con las carpetas y archivos incluidos.
3. Ejecuta `orbitask.exe`.

La compilación actual no utiliza firma de código de Windows, por lo que Windows puede mostrar una advertencia de SmartScreen.

### Linux x64

#### Instalador recomendado

Descarga:

`Orbitask-v0.9-linux-amd64.deb`

En distribuciones basadas en Debian o Ubuntu puedes instalarlo desde la carpeta donde descargaste el archivo:

```bash
sudo apt install ./Orbitask-v0.9-linux-amd64.deb
```

Después de instalarlo puedes abrir Orbitask desde el menú de aplicaciones o desde la terminal:

```bash
orbitask
```

#### Versión portable

También está disponible:

`Orbitask-v0.9-linux-x64-portable.tar.gz`

Ejemplo de instalación manual:

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

Para volver a abrir la versión portable después:

```bash
~/Applications/orbitask/orbitask
```

> La build publicada está dirigida a Linux x64. La disponibilidad de bibliotecas del sistema puede variar entre distribuciones.

## Verificar descargas

Cada release incluye:

`SHA256SUMS.txt`

Este archivo contiene los hashes SHA-256 de las compilaciones publicadas.

En Linux, si los archivos descargados y `SHA256SUMS.txt` están en la misma carpeta:

```bash
sha256sum -c SHA256SUMS.txt
```

En Windows PowerShell puedes consultar el hash de un archivo, por ejemplo:

```powershell
Get-FileHash .\Orbitask-v0.9-windows-setup.exe -Algorithm SHA256
```

## Funcionamiento local y en la nube

Orbitask usa SQLite como almacenamiento local en Android, Linux y Windows.

En Web utiliza almacenamiento persistente del navegador para conservar listas, tareas, subtareas, recordatorios, preferencias y tombstones entre recargas.

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

Desde la Papelera se puede:

- restaurar una tarea;
- eliminarla permanentemente;
- vaciar toda la Papelera.

Las tareas enviadas a la Papelera también sincronizan su estado entre los dispositivos de la misma cuenta.

La eliminación permanente utiliza tombstones para impedir que datos antiguos reaparezcan durante una sincronización posterior.

## Recordatorios

Orbitask permite programar recordatorios por tarea.

Los recordatorios pueden ser relativos o utilizar una fecha y hora personalizada.

También pueden editarse, reprogramarse y cancelarse cuando sea necesario.

En Linux/Crostini los recordatorios persistentes utilizan temporizadores de usuario del sistema.

En Android se utilizan notificaciones locales.

En Web, los recordatorios funcionan mientras Orbitask permanece abierto en la pestaña. El soporte de recordatorios persistentes del navegador queda limitado por las capacidades y permisos del propio navegador.

Los recordatorios se cancelan o reprograman cuando corresponde al completar, editar, enviar a Papelera, restaurar o eliminar una tarea.

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

Orbitask no guarda claves privadas de Supabase en el repositorio.

Para desarrollo se utilizan variables `dart-define`.

Ejemplo en Linux:

```bash
flutter run -d linux \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=https://github.com/darkhmdda/orbitask
```

Nunca debe utilizarse una clave `service_role` dentro de la aplicación cliente.

### Web — desarrollo local

Para ejecutar Orbitask Web con autenticación y sincronización:

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=http://localhost:8080
```

Después puede servirse la compilación localmente, por ejemplo:

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

Ese redirect debe estar permitido también en:

**Supabase → Authentication → URL Configuration → Redirect URLs**

Ejemplo:

```bash
flutter run -d <ANDROID_DEVICE> \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.darkhmdda.orbitask://login-callback
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
- `v0.9-dev`: productividad, búsqueda, filtros, ordenamiento, mejoras de sincronización, cuenta y perfil, 12 temas, identidad visual, builds de distribución y Papelera.
- `v0.9.0`: primera versión estable del ciclo v0.9 para Android, Linux x64 y Windows x64.
- `v0.9.1` (en desarrollo): hardening, tests/CI, reproducibilidad, mejoras de sincronización y soporte oficial de Web.

## Estado del proyecto

Orbitask v0.9.0 es la versión estable actual del proyecto.

La release estable `v0.9.0` incluye:

- APK para Android.
- Instalador `.deb` para Linux x64.
- Versión portable para Linux x64.
- Instalador para Windows x64.
- Versión portable para Windows x64.
- Archivo `SHA256SUMS.txt` para verificar las descargas.

La antigua release `v0.9-dev` se conserva únicamente como prerelease histórica del ciclo de desarrollo.

El trabajo posterior a v0.9.0 se centra en mantenimiento, reproducibilidad del backend, tests automatizados, CI, hardening del repositorio y la incorporación de Web como cuarta plataforma oficial para la siguiente versión estable.

Actualmente el soporte Web del ciclo v0.9.1 ya fue validado con build de producción, persistencia local en navegador, autenticación con Supabase y sincronización real entre Web y dispositivos móviles, incluyendo creación de tareas, Papelera, restauración y eliminación definitiva.
