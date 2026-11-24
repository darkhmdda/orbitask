#!/usr/bin/env python3
"""Genera el logo de Orbitask y todos los iconos de la app a partir de una
única definición vectorial.

Logo: la "O" gruesa del logo anterior con la luz de un agujero negro (núcleo
negro, halo violeta) y un anillo inclinado en degradado de cian a naranja.

Requisitos: Python 3, `rsvg-convert` (librsvg) e ImageMagick (`convert`).
El texto "Orbitask" ya está convertido a trazos en `wordmark_orbitask.txt`
(Montserrat SemiBold), así que no hace falta tener la fuente instalada.

Uso, desde la raíz del repositorio:

    python3 branding/build_branding.py

Escribe los SVG fuente en `branding/` y los PNG/ICO en las carpetas de cada
plataforma (Android, Web, Linux, Windows) y en `assets/branding/`.
"""
import os
import shutil
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

BG = "#09090F"
TILT = -20
O_OUT, O_IN = 232, 162
RING_OUT = (470, 128)
RING_IN = (442, 82)
RING_IN_DY = -30
O_STOPS = [(0, "#4F7BFF"), (0.45, "#A88CFF"), (0.75, "#FF8F7A"), (1, "#FF5A5F")]
RING_STOPS = [(0, "#46E0FF"), (0.25, "#5B8CFF"), (0.5, "#9A5CFF"), (0.75, "#FF5C9E"), (1, "#FFA24C")]


# --- piezas SVG ------------------------------------------------------------

def _stops(items):
    return "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in items)


def _ellipse(cx, cy, rx, ry):
    return (f"M{cx - rx},{cy} a{rx},{ry} 0 1,0 {2 * rx},0 "
            f"a{rx},{ry} 0 1,0 {-2 * rx},0 Z")


def _ring_band():
    return _ellipse(0, 0, *RING_OUT) + " " + _ellipse(0, RING_IN_DY, *RING_IN)


def _o_band():
    return _ellipse(0, 0, O_OUT, O_OUT) + " " + _ellipse(0, 0, O_IN, O_IN)


def _defs(p):
    return f"""
<linearGradient id="{p}o" x1="{-O_OUT}" y1="{-O_OUT}" x2="{O_OUT}" y2="{O_OUT * 0.7:.0f}" gradientUnits="userSpaceOnUse">{_stops(O_STOPS)}</linearGradient>
<linearGradient id="{p}ring" x1="{-RING_OUT[0]}" y1="0" x2="{RING_OUT[0]}" y2="0" gradientUnits="userSpaceOnUse">{_stops(RING_STOPS)}</linearGradient>
<radialGradient id="{p}core" cx="0" cy="0" r="{O_IN}" gradientUnits="userSpaceOnUse">
  <stop offset="0" stop-color="#020203"/><stop offset="0.78" stop-color="#05040A"/>
  <stop offset="0.93" stop-color="#2A1B5C"/><stop offset="1" stop-color="#6B4BFF"/>
</radialGradient>
<radialGradient id="{p}halo" cx="0" cy="0" r="360" gradientUnits="userSpaceOnUse">
  <stop offset="0.5" stop-color="#7A5CFF" stop-opacity="0.30"/>
  <stop offset="0.8" stop-color="#3A2A8F" stop-opacity="0.08"/>
  <stop offset="1" stop-color="#000000" stop-opacity="0"/>
</radialGradient>
<filter id="{p}glow" x="-40%" y="-80%" width="180%" height="260%"><feGaussianBlur stdDeviation="16"/></filter>
<clipPath id="{p}front"><rect x="-700" y="0" width="1400" height="400"/></clipPath>
<mask id="{p}cut" maskUnits="userSpaceOnUse" x="-700" y="-700" width="1400" height="1400">
  <rect x="-700" y="-700" width="1400" height="1400" fill="#fff"/>
  <g transform="rotate({TILT})" clip-path="url(#{p}front)">
    <path d="{_ring_band()}" fill="#000" fill-rule="evenodd" stroke="#000" stroke-width="20" stroke-linejoin="round"/>
  </g>
</mask>
<linearGradient id="{p}word" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#F5F7FF"/><stop offset="1" stop-color="#DCCFFF"/></linearGradient>
"""


def mark(p, halo=True, glow=0.9):
    """Marca centrada en (0,0). El corte donde el anillo cruza la O es
    transparente de verdad (máscara), así que funciona sobre cualquier fondo."""
    band, ob = _ring_band(), _o_band()
    parts = []
    if halo:
        parts.append(f'<circle r="360" fill="url(#{p}halo)"/>')
    if glow:
        parts.append(f'<path d="{ob}" fill="url(#{p}o)" fill-rule="evenodd" filter="url(#{p}glow)" opacity="{glow}" mask="url(#{p}cut)"/>')
        parts.append(f'<path transform="rotate({TILT})" d="{band}" fill="url(#{p}ring)" fill-rule="evenodd" filter="url(#{p}glow)" opacity="{glow * 0.9:.2f}"/>')
    parts += [
        f'<path transform="rotate({TILT})" d="{band}" fill="url(#{p}ring)" fill-rule="evenodd"/>',
        f'<circle r="{O_IN}" fill="url(#{p}core)"/>',
        f'<path d="{ob}" fill="url(#{p}o)" fill-rule="evenodd" mask="url(#{p}cut)"/>',
        f'<g transform="rotate({TILT})" clip-path="url(#{p}front)"><path d="{band}" fill="url(#{p}ring)" fill-rule="evenodd"/></g>',
    ]
    return "".join(parts)


def mark_monochrome(p):
    """Silueta de un solo color (iconos temáticos de Android 13+)."""
    band, ob = _ring_band(), _o_band()
    return (f'<path transform="rotate({TILT})" d="{band}" fill="#fff" fill-rule="evenodd"/>'
            f'<path d="{ob}" fill="#fff" fill-rule="evenodd" mask="url(#{p}cut)"/>')


def _svg(size, body, background=None, radius=0):
    w, h = size if isinstance(size, tuple) else (size, size)
    back = ""
    if background:
        back = f'<rect width="{w}" height="{h}" rx="{radius}" fill="{background}"/>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
            f"{back}{body}</svg>\n")


def icon_svg(scale, background=BG, radius=0, halo=True, mono=False, size=1024):
    p = "m"
    inner = mark_monochrome(p) if mono else mark(p, halo=halo)
    body = (f"<defs>{_defs(p)}</defs>"
            f'<g transform="translate({size / 2},{size / 2}) scale({scale})">{inner}</g>')
    return _svg(size, body, background, radius)


def lockup_svg(background=BG):
    with open(os.path.join(HERE, "wordmark_orbitask.txt")) as f:
        header, d = f.read().split("\n", 1)
    text_units = float(header.split()[0])
    p, w = "l", 1200
    text_w = 780
    s = text_w / text_units
    body = (f"<defs>{_defs(p)}</defs>"
            f'<g transform="translate(600,470) scale(0.98)">{mark(p)}</g>'
            f'<g transform="translate({(w - text_w) / 2},920) scale({s:.5f})"><path d="{d}" fill="url(#{p}word)"/></g>')
    return _svg(w, body, background)


# --- exportación -------------------------------------------------------------

def write(path, content):
    path = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)
    return path


def render(svg_text, out, width, height=None):
    out = os.path.join(ROOT, out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as tmp:
        tmp.write(svg_text)
    cmd = ["rsvg-convert", "-w", str(width)]
    if height:
        cmd += ["-h", str(height)]
    subprocess.run(cmd + [tmp.name, "-o", out], check=True)
    os.unlink(tmp.name)
    return out


def main():
    for tool in ("rsvg-convert", "convert"):
        if not shutil.which(tool):
            raise SystemExit(f"Falta {tool}: instala librsvg2-bin e imagemagick.")

    # Fuentes vectoriales.
    write("branding/orbitask-mark.svg", icon_svg(1.0, background=None))
    write("branding/orbitask-icon.svg", icon_svg(0.86, radius=225))
    write("branding/orbitask-logo.svg", lockup_svg())
    write("branding/orbitask-logo-transparent.svg", lockup_svg(background=None))
    render(lockup_svg(), "branding/orbitask-logo.png", 1200)
    render(icon_svg(0.86, radius=225), "branding/orbitask-icon.png", 256)

    rounded = icon_svg(0.86, radius=225)       # escritorio y Android antiguo
    full = icon_svg(0.92)                      # web: cuadrado completo
    maskable = icon_svg(0.76)                  # web maskable: zona segura del 80 %
    favicon = icon_svg(1.0)                    # pestaña: lo más grande posible
    foreground = icon_svg(0.675, background=None)           # Android adaptativo
    monochrome = icon_svg(0.675, background=None, mono=True)

    # Android.
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, factor in densities.items():
        res = f"android/app/src/main/res/mipmap-{name}"
        render(rounded, f"{res}/ic_launcher.png", int(48 * factor))
        render(foreground, f"{res}/ic_launcher_foreground.png", int(108 * factor))
        render(monochrome, f"{res}/ic_launcher_monochrome.png", int(108 * factor))
    write("android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml", """<?xml version="1.0" encoding="utf-8"?>
<!-- Generado por branding/build_branding.py -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
""")
    write("android/app/src/main/res/values/ic_launcher_background.xml", f"""<?xml version="1.0" encoding="utf-8"?>
<!-- Generado por branding/build_branding.py -->
<resources>
    <color name="ic_launcher_background">{BG}</color>
</resources>
""")

    # Web.
    render(full, "web/icons/Icon-192.png", 192)
    render(full, "web/icons/Icon-512.png", 512)
    render(maskable, "web/icons/Icon-maskable-192.png", 192)
    render(maskable, "web/icons/Icon-maskable-512.png", 512)
    render(favicon, "web/favicon.png", 32)

    # Linux (ventana y paquete .deb, que lo instala en hicolor/256x256).
    render(rounded, "linux/runner/resources/orbitask.png", 256)

    # Windows: .ico con varios tamaños.
    tmpdir = tempfile.mkdtemp()
    pngs = [render(rounded, os.path.join(tmpdir, f"{s}.png"), s) for s in (16, 24, 32, 48, 64, 128, 256)]
    subprocess.run(["convert", *pngs, os.path.join(ROOT, "windows/runner/resources/app_icon.ico")], check=True)
    shutil.rmtree(tmpdir)

    # Logo dentro de la app (sin halo, para que se vea limpio también en temas claros).
    app_mark = icon_svg(1.0, background=None, halo=False, size=1100)
    out = render(app_mark, "assets/branding/orbitask_mark.png", 1100)
    subprocess.run(["convert", out, "-trim", "+repage", "-resize", "480x", out], check=True)
    print("Listo.")


if __name__ == "__main__":
    main()
