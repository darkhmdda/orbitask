# Orbitask

**Tus tareas, siempre en órbita.**

Orbitask es una aplicación TO-DO multiplataforma desarrollada con Flutter para organizar tareas, listas, subtareas, prioridades, fechas y recordatorios. Funciona de forma local con SQLite y puede sincronizar datos entre dispositivos mediante Supabase.

## Estado actual — v0.9-dev

Orbitask v0.9-dev está validado en:

- Android
- Linux x64
- Windows x64

La versión actual incluye:

- CRUD completo de tareas.
- Captura rápida.
- Prioridades, fechas y horas límite.
- Listas personalizadas.
- Subtareas y progreso.
- Búsqueda, filtros y ordenamiento.
- Persistencia local con SQLite.
- Recordatorios persistentes por tarea.
- Múltiples recordatorios relativos o personalizados.
- Edición, reprogramación y cancelación automática de recordatorios.
- Autenticación con Supabase.
- Inicio de sesión, registro, cierre de sesión y recuperación/cambio de contraseña.
- Sincronización bidireccional SQLite ↔ Supabase.
- Supabase Realtime.
- Resolución de cambios mediante `updated_at`.
- Cola/reintentos de sincronización y estado visible de conexión.
- Tombstones para eliminaciones definitivas.
- Papelera de tareas con restauración, vaciado y eliminación permanente.
- Sincronización de Papelera entre dispositivos.
- Perfil de usuario con nombre y avatar.
- Preferencias sincronizadas por cuenta.
- Interfaz adaptable para escritorio y móvil.
- Identidad nativa Orbitask en Android, Linux y Windows.
- 12 temas visuales.
- Icono propio de Orbitask en las tres plataformas.

## Descargar Orbitask

Las compilaciones se publican en **GitHub Releases**:

https://github.com/darkhmdda/orbitask/releases/tag/v0.9-dev

### Android

Descarga:

`Orbitask-v0.9-android-universal.apk`

Después abre el APK desde Android y confirma la instalación. Si Android lo solicita, permite temporalmente la instalación de aplicaciones desde esa fuente.

### Windows x64

Descarga:

`Orbitask-v0.9-windows-x64.zip`

1. Descomprime el ZIP completo.
2. No separes `orbitask.exe` de los demás archivos y carpetas incluidos.
3. Abre `orbitask.exe`.

La compilación actual no utiliza firma de código de Windows, por lo que Windows puede mostrar una advertencia de SmartScreen.

### Linux x64

Puedes descargar y ejecutar Orbitask desde la terminal:

```bash
mkdir -p ~/Applications/orbitask
cd ~/Applications/orbitask

curl -L   -o Orbitask-v0.9-linux-x64.tar.gz   https://github.com/darkhmdda/orbitask/releases/download/v0.9-dev/Orbitask-v0.9-linux-x64.tar.gz

tar -xzf Orbitask-v0.9-linux-x64.tar.gz
chmod +x bundle/orbitask
./bundle/orbitask
```

Para volver a abrirlo después:

```bash
~/Applications/orbitask/bundle/orbitask
```

> La build publicada está dirigida a Linux x64. La disponibilidad de bibliotecas del sistema puede variar entre distribuciones.

## Verificar descargas

Cada release incluye `SHA256SUMS.txt`.

En Linux:

```bash
sha256sum -c SHA256SUMS.txt
```

En Windows PowerShell puedes obtener el hash de un archivo con:

```powershell
Get-FileHash .\Orbitask-v0.9-windows-x64.zip -Algorithm SHA256
```

## Funcionamiento local y en la nube

Orbitask usa SQLite como almacenamiento local. La aplicación puede seguir trabajando localmente sin una conexión activa a Supabase.

Cuando Supabase está configurado y el usuario inicia sesión:

- los datos locales y remotos se combinan;
- los cambios se sincronizan automáticamente;
- Realtime permite reaccionar a cambios de otros dispositivos;
- existe un ciclo periódico de respaldo;
- el usuario también puede forzar una sincronización manual;
- cada espacio local queda vinculado a una cuenta para evitar mezclar información entre usuarios.

## Papelera

Eliminar una tarea desde la vista principal la mueve primero a la Papelera.

Desde la Papelera se puede:

- restaurar una tarea;
- eliminarla permanentemente;
- vaciar toda la Papelera.

Las tareas enviadas a la Papelera también sincronizan su estado entre los dispositivos de la misma cuenta. La eliminación permanente utiliza el sistema de tombstones para impedir que datos antiguos reaparezcan durante una sincronización posterior.

## Recordatorios

Orbitask permite programar recordatorios por tarea.

En Linux/Crostini los recordatorios persistentes utilizan temporizadores de usuario del sistema. En Android se utilizan notificaciones locales. Los recordatorios se cancelan o reprograman cuando corresponde al completar, editar, enviar a Papelera, restaurar o eliminar una tarea.

## Temas

Orbitask incluye 12 temas:

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
- proyecto Supabase opcional para Auth y sincronización

Clona el repositorio:

```bash
git clone https://github.com/darkhmdda/orbitask.git
cd orbitask
flutter pub get
```

Orbitask no guarda claves privadas de Supabase en el repositorio.

Para desarrollo usa variables `dart-define`:

```bash
flutter run -d linux \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=https://github.com/darkhmdda/orbitask
```

Nunca debe usarse una clave `service_role` dentro de la aplicación cliente.

### Android — callback nativo

Orbitask usa:

```text
com.darkhmdda.orbitask://login-callback
```

Ese redirect debe estar permitido también en **Supabase → Authentication → URL Configuration → Redirect URLs**.

Ejemplo:

```bash
flutter run -d <ANDROID_DEVICE> \
  --dart-define=SUPABASE_URL=https://TU-PROYECTO.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICABLE \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=com.darkhmdda.orbitask://login-callback
```

## Tecnologías

- Flutter / Dart
- SQLite
- Supabase Auth
- Supabase Database
- Supabase Realtime
- Supabase Storage
- Git / GitHub

## Historial principal

- `v0.1-dev`: base visual, modelo Task y diseño responsive.
- `v0.2-dev`: CRUD, prioridades, fechas y filtros.
- `v0.3-dev`: SQLite y persistencia local.
- `v0.4-dev`: listas, subtareas, progreso y migración SQLite.
- `v0.4.1-dev`: identidad Orbitask y migración de base de datos.
- `v0.5-dev`: recordatorios persistentes y notificaciones.
- `v0.6-dev`: sistema de temas.
- `v0.7-dev`: Auth, sincronización bidireccional, tombstones y Realtime.
- `v0.8-dev`: consolidación multiplataforma Android/Linux/Windows.
- `v0.9-dev`: productividad, búsqueda/filtros/ordenamiento, mejoras de sync, cuenta/perfil, 12 temas, identidad visual, builds de distribución y Papelera.

## Estado del proyecto

La rama de desarrollo de v0.9 ha sido validada funcionalmente en Android, Linux y Windows. La release `v0.9-dev` contiene paquetes para las tres plataformas y un archivo de hashes SHA-256.

El siguiente cierre del proyecto contempla la consolidación de la versión estable y su documentación completa.
