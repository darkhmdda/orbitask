# Changelog

Todos los cambios importantes de Orbitask se documentan en este archivo.

## [Sin publicar]

### Añadido

- Nueva pestaña **Acerca de** en Ajustes, después de Notificaciones (en el móvil, «Info», para que quepan las cuatro pestañas). Muestra la versión instalada (en las versiones de prueba, su etiqueta, como `v0.19-dev`), las notas de esa versión y las de las anteriores, y un botón para descargar la última versión. En las versiones de prueba el botón lleva a la lista completa de versiones, porque la página de la última versión se salta las de prueba. En la web, el botón ofrece descargar la app.
- Logo nuevo: la "O" de Orbitask como un agujero negro, con un anillo en degradado de cian a naranja. Se aplica al icono de Android (ahora adaptativo, con versión monocroma para los iconos temáticos), a la web (que todavía mostraba el logo de Flutter), a Linux, a Windows y al logo dentro de la app. Las fuentes y el script que genera todos los iconos están en `branding/`.
- Widgets de pantalla de inicio para Android: **Todas las tareas**, **Próximas entregas** y **Calendario**. Usan los colores del tema activo de Orbitask.
  - Esquinas redondeadas, fechas relativas ("Hoy", "Mañana", "en 4 días", "Vencida · ayer") y el color de la casilla según la prioridad.
  - Al marcar una tarea, queda tachada al final de la lista y se puede desmarcar. Al completarla desde el widget se cancelan sus recordatorios al momento. El cambio se guarda en la base de datos y se sincroniza en cuanto la app está en marcha (al momento si sigue abierta en segundo plano, o la próxima vez que se abra).
  - El botón "+" abre directamente el formulario de nueva tarea. En el calendario, la tarea se propone con la fecha del día seleccionado.
  - Tocar una tarea la abre en la app.
  - Próximas entregas agrupa las tareas en Vencidas, Esta semana y Más adelante, con un recuadro de fecha.
  - El calendario muestra un punto en los días con tareas pendientes y, debajo, la agenda del día que se toque. Tocar el nombre del mes vuelve a hoy.
  - Se actualizan solos poco después de medianoche.
- Dos temas oscuros nuevos, Subaru y Asta. El identificador del tema se sincroniza como texto, por lo que las versiones anteriores de la app mostrarán el tema por defecto si otro dispositivo elige uno de estos.

### Corregido

- El tema ya no se revierte al cambiarlo mientras hay una sincronización en curso (se aplicaba el tema leído al empezar). Además, un tema elegido en un dispositivo ya no pierde frente a otro dispositivo con el reloj adelantado.
- Los recordatorios de una tarea borrada en otro dispositivo se cancelan al sincronizar. Antes seguían programados hasta reiniciar la app.
- Los widgets de Android ya no abren la base de datos local desde Kotlin. En la versión de prueba v0.10-dev lo hacían a la vez que la app, con dos copias distintas de SQLite en el mismo proceso, y eso podía corromper la base local ("database disk image is malformed"). Ahora la app les pasa las tareas y guarda ella misma lo que se marca en el widget.

### Cambiado

- `file_picker` pasa de la 10 a la 13. La API cambió (métodos estáticos y lectura con `readAsBytes()`), así que se migraron la elección de adjuntos, la foto de perfil y la descarga de adjuntos en Android y en la web. Los adjuntos de más de 15 MB se rechazan antes de leerlos cuando se conoce su tamaño, y la descarga indica el tipo MIME del archivo.
- El tema tiene su propia sincronización: se confirma con el botón «Aplicar tema», se sube al momento y los otros dispositivos lo aplican en cuanto les llega por Realtime, sin esperar a una sincronización de las tareas.
- Subida rápida: tras una edición, la app sube solo lo que cambió 300 ms después, sin descargar antes todas las tablas. Junto con la aplicación inmediata de Realtime, un cambio pasa de un dispositivo a otro en alrededor de un segundo. La sincronización completa sigue ejecutándose al abrir la app, cada 20–30 s y ante cualquier caso que la subida rápida no cubra (primera sincronización, un fallo).
- Sincronización más rápida: los cambios que avisa Realtime se aplican al momento con la fila que llega, sin descargar todas las tablas. El eco de los cambios propios se detecta por `updated_at` y se descarta, así que desaparece la ventana de 5 s en la que se ignoraban los avisos, que hacía que los cambios de otro dispositivo tardaran hasta 30 s. Tras sincronizar solo se reprograman los recordatorios de las tareas que cambiaron.
- Los adjuntos pasan de un dispositivo a otro en lo que tarda subir y bajar el archivo. Antes la tarea aparecía enseguida pero el adjunto esperaba a dos sincronizaciones completas (una al subir y otra al recibir). Ahora la subida rápida sube el archivo a Storage justo después de su tarea, y el otro dispositivo, al recibir el aviso de Realtime, descarga solo ese archivo. Si la tarea del adjunto todavía no ha llegado, o la subida o la descarga fallan, se sigue recurriendo a la sincronización completa.

### Documentación

- README con el logo nuevo arriba y el icono al final, y enlace a `branding/README.md`.
- README actualizado a la versión 1.0.1.
- Nueva documentación técnica en `docs/`: arquitectura, datos y Supabase, sincronización (con sus limitaciones conocidas) y builds y distribución.
- Se elimina el documento `.docx` externo a favor de documentación en markdown versionada junto al código.

### Interno

- Gradle pasa de la 9.3.1 a la 9.5.1 (con la 9.3.1 el build de Android mostraba un aviso).
- Android Gradle Plugin pasa de la 9.1.1 a la 9.3.1 y Kotlin de la 2.4.0 a la 2.4.20, las versiones de la plantilla de Flutter 3.50. Con las anteriores, el build avisaba de que Flutter dejaría de admitirlas pronto.
- `release_android.yml` compila con Java 21 en lugar de 17: el lint de AGP 9.3.1 usa `List.removeLast()`, que no existe en Java 17, y la compilación fallaba con `NoSuchMethodError`. La app sigue generando bytecode para Java 17.
- `release_linux.yml` compila en `ubuntu-24.04` en lugar de `ubuntu-latest` (que pasó a 26.04). En la `v0.22-dev` el ejecutable de Linux salió marcado como x86-64-v3 y no arrancaba en CPU sin AVX2 («CPU ISA level is lower than required»). Un paso nuevo comprueba con `readelf` que ningún binario exige x86-64-v3 o superior.
- Los workflows de Linux y Windows se parametrizan como el de Android (entradas `tag` y `prerelease`) y pasan a llamarse `release_linux.yml` y `release_windows.yml`. Antes estaban atados a la v1.0.0. Los tres dejan sus archivos en un único borrador de release por etiqueta (`.github/scripts/release_draft.sh`) y nunca modifican una release publicada. Las apps de escritorio también reciben `ORBITASK_TAG`, así que la pestaña Info muestra la etiqueta.
- Los workflows usan `actions/checkout@v5` (la v4 funciona con Node.js 20, que GitHub Actions ya no recomienda).
- La sección `### Interno` del changelog recoge los cambios técnicos. La pestaña Acerca de no la muestra, igual que `### Documentación`.
- `release_android.yml` pasa la etiqueta de la release a la app con `--dart-define=ORBITASK_TAG`. Antes las versiones de prueba se identificaban como 1.0.1.
- Nuevas dependencias: `package_info_plus` (versión instalada) y `url_launcher` (abrir la página de descarga). El `CHANGELOG.md` se incluye como asset de la app.
- Migración de `package:flutter/material.dart` a `package:material_ui`. Flutter 3.50 marca el import anterior como obsoleto y `flutter analyze` (y con él el CI) fallaba con 12 avisos.
- El despliegue de la web separa la compilación y la publicación en dos jobs, como recomienda `actions/deploy-pages`, y sube a `upload-pages-artifact@v4` y `checkout@v5`. Con todo en un mismo job, la publicación fallaba de vez en cuando porque no encontraba el artefacto recién subido.
- Nuevo workflow manual `release_android.yml`: compila un APK firmado con la clave guardada en los secretos del repositorio y lo deja en un borrador de release. Así ya no hace falta el SDK de Android en la máquina local.
- Los workflows de Web, Windows y Linux leen la URL y la clave publicable de Supabase de variables del repositorio en lugar de tenerlas escritas en el código. Fallan con un mensaje claro si faltan. El workflow de Linux ya no extrae esos valores con una expresión regular del workflow de Windows, y pasa a ejecutarse solo de forma manual (antes también se disparaba al modificar su propio archivo en `main`, lo que volvía a subir y sobrescribir los artefactos de la release).
- Supabase: nuevo trigger `skip_stale_sync_updates` (migración `20261123180000`). El servidor descarta, sin error, las actualizaciones de las tablas de sincronización cuyo `updated_at` no sea estrictamente mayor que el guardado. Evita que una copia antigua sobrescriba datos más recientes y que las filas idénticas generen cambios y eventos de Realtime. No resuelve los relojes desajustados de los dispositivos.
- Sincronización: la subida ahora solo envía las listas, tareas, subtareas y recordatorios que no existen en Supabase o son más recientes que su copia remota (antes subía todo en cada pasada). Se añade `RemoteVersions` con pruebas unitarias; el trigger del servidor sigue como red de seguridad.

## [1.0.1] - 2026-10-06

Hotfix de estabilidad para la sincronización de tareas y sus datos relacionados.

### Corregido

- La sincronización ya no intenta subir subtareas, recordatorios o adjuntos cuyo `task_id` no corresponde a una tarea local existente.
- La eliminación permanente de una tarea registra también tombstones para sus subtareas, recordatorios y adjuntos antes de eliminar los datos locales.
- Se evita el error de clave foránea `reminders_task_fk` observado en Web cuando quedaba un recordatorio local antiguo asociado a una tarea ya eliminada.
- La protección se aplica tanto al servicio de sincronización Web como al nativo.


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
