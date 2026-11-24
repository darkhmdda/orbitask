# Orbitask: guía para Claude

App de tareas en Flutter con Supabase. Funciona en Android, web (GitHub Pages), Linux y Windows. Repo: `darkhmdda/orbitask`.

## Reglas de trabajo

- Todo en **español**: código nuevo, comentarios, commits, PRs y documentación.
- Opinión sincera y sin adulación. Si algo es mala idea, se dice.
- Los nombres que da el usuario se respetan **exactamente** (temas Emilia, Subaru, Asta, Luffy, Goku, Veldora…).
- **Cada cambio va en su propia rama y su PR.** Nunca se hace commit directo en `main`.
- Antes de cada push: `flutter analyze && flutter test` sin errores.
- No se escriben claves ni secretos en el código ni en la documentación. Las claves de Supabase llegan por `--dart-define` (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`).
- El keystore de Android **nunca** entra al repo. Vive en los secretos de GitHub (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`).
- Cada cambio visible se anota en `CHANGELOG.md`, sección `[Sin publicar]`.

## Cómo prueba el usuario

1. Fusiona el PR en `main`.
2. Lanza manualmente el workflow **Release Orbitask Android** (`release_android.yml`) con una etiqueta `vX.Y-dev` y *prerelease*. El workflow crea un **borrador** de release con el APK firmado y su `.sha256`.
3. Pega las notas, publica la pre-release y descarga el APK en su teléfono (Honor, Android).
4. La web se despliega sola al fusionar en `main` (`deploy_web.yml`).

Al terminar un cambio, entrega también unas **notas de release** listas para pegar, en Markdown y en español, que empiecen por `> ⚠️ **Versión de prueba (pre-release).**`.

## Arquitectura (lo que no hay que romper)

Detalle en `docs/ARQUITECTURA.md`, `docs/SINCRONIZACION.md` y `docs/DATOS_Y_SUPABASE.md`.

- **Base local:** SQLite con el paquete Dart `sqlite3` (FFI). **El código Kotlin nunca abre `orbitask.sqlite`.** Dos copias de SQLite en el mismo proceso corrompen la base ("database disk image is malformed"); ya pasó en la v0.10-dev.
- **Widgets de Android** (`android/app/src/main/kotlin/com/darkhmdda/orbitask/`): la app les pasa las tareas en JSON por el MethodChannel `com.darkhmdda.orbitask/widgets` (`updateWidgets`, `takePendingAction`, `takeWidgetToggles`; de Kotlin a Dart `widgetTasksChanged`). Lo que se marca en el widget se guarda como *toggle* pendiente y lo aplica Dart. Las clases `OrbitaskTodayWidget` y `OrbitaskSummaryWidget` conservan esos nombres para no romper los widgets ya colocados.
- **Sincronización** (`lib/services/cloud_sync_service_native.dart` y `_web.dart`, que reflejan la misma lógica):
  - Gana el último en escribir, según `updated_at`. El trigger `skip_stale_sync_updates` del servidor descarta las filas que no son más nuevas.
  - Realtime aplica cada cambio fila a fila (`applyRemoteChange`). Si no puede, pide una sincronización completa.
  - La subida rápida (`pushLocalChanges`) sube solo lo cambiado desde `cloud_push_watermark`.
  - El **tema** tiene su propia sincronización (`pushTheme` / `applyRemoteTheme`, tabla `user_preferences`) y se aplica con el botón «Aplicar tema».
- **Recordatorios:** `flutter_local_notifications`. Tras sincronizar se recalculan con `ReminderPlan.diff`. El id de notificación es FNV-1a de 31 bits y Kotlin calcula el mismo.
- **Marca:** `branding/build_branding.py` genera todos los iconos y logos (ver `branding/README.md`).

## Entorno

- Flutter estable (el CI usa `channel: stable`); el SDK de Dart pide `^3.13.0`.
- Android: AGP 9.1.1, Gradle 9.5.1, Java 17 en el workflow.
- Los APK firmados se compilan **solo en GitHub Actions**, no en local.
- Dependabot agrupa las subidas menores y de parche (`pub-menores`, `actions-menores`). Las mayores llegan por separado y se revisan una a una: leer el changelog y migrar el código si hace falta, como se hizo con `file_picker` 13.

## Pendiente (noviembre de 2026)

1. Terminar los PRs de dependencias: `pub-menores`, `actions/setup-java` v6 y `actions/upload-artifact` v7. Probarlos con la `v0.17-dev`.
2. Probar el toggle del widget con la app cerrada del todo.
3. Parametrizar `release_linux_v1.yml` y `release_windows_v1.yml` como el de Android. Ahora están atados a la v1.0.0.
4. Sacar la **1.1.0** estable para todas las plataformas con lo que hay en `[Sin publicar]`.
5. Opcional: descarga incremental en la sincronización (requiere una migración en Supabase).
