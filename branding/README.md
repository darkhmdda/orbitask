# Logo e iconos de Orbitask

El logo es la "O" gruesa del logo anterior con la luz de un agujero negro: núcleo negro con brillo violeta en el borde, halo, y un anillo inclinado en degradado de cian a naranja que cruza la "O" por delante.

Todo sale de una única definición vectorial en `build_branding.py`. Para cambiar colores, grosores o inclinación, edita las constantes del principio del script y vuelve a generar.

## Archivos fuente

| Archivo | Uso |
| ------- | --- |
| `orbitask-mark.svg` | Marca sola, fondo transparente |
| `orbitask-icon.svg` | Icono cuadrado redondeado con fondo oscuro |
| `orbitask-logo.svg` / `.png` | Marca + "Orbitask" sobre fondo oscuro |
| `orbitask-logo-transparent.svg` | Marca + "Orbitask", fondo transparente (solo para fondos oscuros: el texto es claro) |
| `wordmark_orbitask.txt` | El texto "Orbitask" convertido a trazos (Montserrat SemiBold) |

## Regenerar los iconos

Requisitos: `python3`, `rsvg-convert` (paquete `librsvg2-bin`) e ImageMagick (`imagemagick`).

```bash
python3 branding/build_branding.py
```

Sobrescribe:

| Plataforma | Archivos |
| ---------- | -------- |
| Android | `mipmap-*/ic_launcher.png` (Android 7 y anteriores), `ic_launcher_foreground.png` e `ic_launcher_monochrome.png` (icono adaptativo e iconos temáticos), `mipmap-anydpi-v26/ic_launcher.xml`, `values/ic_launcher_background.xml` |
| Web | `web/favicon.png`, `web/icons/Icon-*.png` (incluidos los *maskable*) |
| Linux | `linux/runner/resources/orbitask.png` (ventana y paquete `.deb`) |
| Windows | `windows/runner/resources/app_icon.ico` (16 a 256 px; también lo usa el instalador) |
| App | `assets/branding/orbitask_mark.png` (logo de la pantalla de inicio y del login) |

Las carpetas `ios` y `macos` no se regeneran porque esas plataformas no tienen soporte.

## Medidas importantes

- **Android adaptativo:** la marca ocupa el 62 % del ancho de la capa para quedar dentro de la zona segura (círculo de 66 dp de 108 dp), sea cual sea la forma de recorte del launcher.
- **Web maskable:** la marca cabe en el círculo del 80 % que exige el formato.
- **Corte del anillo:** donde el anillo cruza la "O" hay un hueco transparente (máscara), no pintado del color del fondo, así que el logo funciona sobre temas claros y oscuros.
