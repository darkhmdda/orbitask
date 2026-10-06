# Cierre temporal — Orbitask v1.0.0

Fecha de cierre técnico: 2026-10-06

Orbitask v1.0.0 representa la primera versión estable completa del proyecto y su punto de cierre temporal. El proyecto no se considera abandonado ni discontinuado: queda en un estado estable que permite retomarlo posteriormente si se decide iniciar un nuevo ciclo.

## Estado de la versión

- Versión: `1.0.0+12`
- Release: `v1.0.0`
- Estado: estable
- Plataformas oficiales: Android, Linux x64, Windows x64 y Web
- Licencia: MIT

## Alcance completado

Orbitask v1.0.0 incluye un gestor de tareas multiplataforma con:

- tareas, listas y subtareas;
- prioridades, fechas y horas límite;
- búsqueda, filtros y ordenamiento;
- captura rápida;
- recordatorios;
- Papelera y eliminación definitiva;
- autenticación de usuario;
- sincronización mediante Supabase;
- Realtime;
- perfiles con nombre visible, username y avatar;
- preferencias y temas;
- archivos adjuntos;
- atajos de teclado en Windows, Linux y Web;
- persistencia local adaptada a plataformas nativas y navegador.

## Plataformas oficiales

### Android

Orbitask fue probado en un dispositivo físico Android 15 ARM64. Se validaron la aplicación, autenticación, sincronización, perfil y adjuntos.

La build release firmada se publicó como:

`Orbitask-v1.0.0-android.apk`

### Linux x64

Orbitask fue validado en Linux/Crostini. Se comprobaron funcionamiento general, sincronización, perfil, adjuntos, atajos de teclado y temas.

Se publicaron:

- `Orbitask-v1.0.0-linux-amd64.deb`
- `Orbitask-v1.0.0-linux-x64-portable.tar.gz`

El paquete `.deb` oficial v1.0.0 fue instalado y validado.

### Windows x64

La versión Windows fue validada con soporte de perfil, adjuntos, descargas y atajos de teclado.

Se publicaron:

- `Orbitask-v1.0.0-windows-setup.exe`
- `Orbitask-v1.0.0-windows-x64-portable.zip`

### Web

Orbitask Web se encuentra desplegado mediante GitHub Pages.

Se validaron:

- autenticación;
- sincronización;
- perfil;
- temas;
- archivos adjuntos;
- atajos de teclado;
- persistencia local.

Durante el ciclo v1.0.0 se corrigió el almacenamiento de bytes de adjuntos en `localStorage` para evitar exceder la cuota del navegador.

## Artefactos oficiales

```text
Orbitask-v1.0.0-android.apk
Orbitask-v1.0.0-linux-amd64.deb
Orbitask-v1.0.0-linux-x64-portable.tar.gz
Orbitask-v1.0.0-windows-setup.exe
Orbitask-v1.0.0-windows-x64-portable.zip
SHA256SUMS-android-v1.0.0.txt
SHA256SUMS-linux-v1.0.0.txt
SHA256SUMS-windows-v1.0.0.txt
```

## SHA-256

```text
bd54e94f3c5a3b536b9f174337ac6bae62a52d2f035abb47802b4d8dcdfec93a  Orbitask-v1.0.0-android.apk
8111b9d038ab2a47b6abfa86b5a4976cc80ec38f36a90ea5514d12d8d9d081b0  Orbitask-v1.0.0-linux-amd64.deb
7d794a83927a3708f17d038f8ce263219876bd5150eefced4d3250795b18ba61  Orbitask-v1.0.0-linux-x64-portable.tar.gz
91e192f85c74c07c22d0c86b51c433850c28d16a3e1a81eb54c1094ff12bcdd8  Orbitask-v1.0.0-windows-setup.exe
80322f18d067af9dd8f695cdd8ea6b86c7f4bc7b845c0cd1f3dc949954972d0e  Orbitask-v1.0.0-windows-x64-portable.zip
```

## Plataformas no oficiales

iOS y macOS permanecen en el árbol Flutter del repositorio con la identidad de Orbitask normalizada, pero no fueron parte de la validación ni distribución oficial de v1.0.0.

No debe interpretarse su presencia en el repositorio como soporte oficial.

## Limitaciones conocidas

- Los recordatorios Web persistentes con la pestaña cerrada requerirían una implementación futura basada en Push/Service Worker.
- Las builds Windows no utilizan actualmente firma de código, por lo que SmartScreen puede mostrar una advertencia.
- Las actualizaciones mayores de dependencias deben revisarse y probarse antes de integrarse.
- iOS y macOS no están soportados oficialmente.

## Estado del desarrollo

Con v1.0.0, Orbitask entra en una pausa de desarrollo planificada.

Esto significa:

- la versión actual se considera utilizable y estable;
- no existe obligación de iniciar inmediatamente una v1.1.0;
- el repositorio y su historial permanecen disponibles;
- cualquier desarrollo futuro puede partir de este estado estable;
- los cambios posteriores deberán volver a pasar por CI y validación multiplataforma.

## Nota sobre el cierre

El cierre es temporal y técnico, no una declaración de abandono del proyecto.

Orbitask puede retomarse en el futuro para mantenimiento, nuevas plataformas o nuevas funcionalidades. Hasta entonces, v1.0.0 queda como la versión estable de referencia.
