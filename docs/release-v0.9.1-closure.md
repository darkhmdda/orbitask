# Cierre oficial — Orbitask v0.9.1

Fecha de cierre: 2026-10-05

Orbitask v0.9.1 queda oficialmente cerrado y publicado como versión estable.

## Estado final

- Release: `v0.9.1`
- Tag: `v0.9.1`
- Commit de release: `1e7b5e060d1078726d396f795b1c6551c6ac9914`
- PR de cierre: #9 — Release Orbitask v0.9.1
- CI final: PASS
- `flutter analyze`: sin issues
- `flutter test`: 14/14 PASS

## Plataformas oficiales validadas

- Android
- Linux x64
- Windows x64
- Web

## Puntos del ciclo completados

1. Soporte oficial Web.
2. Ajustes y validación de Web.
3. Hardening de dependencias, scripts y repositorio.
4. Licencia MIT.
5. Refactor de `home_screen.dart` por responsabilidades.
6. Validación final multiplataforma.
7. Merge a `main`, tag y publicación de `v0.9.1`.

Resultado: 7/7 puntos completados.

## Artefactos publicados

- `Orbitask-v0.9.1-android.apk`
- `Orbitask-v0.9.1-linux-amd64.deb`
- `Orbitask-v0.9.1-linux-x64-portable.tar.gz`
- `Orbitask-v0.9.1-windows-setup.exe`
- `Orbitask-v0.9.1-windows-x64-portable.zip`
- `SHA256SUMS.txt`

## SHA-256

```text
02818945c54d0214a81b988f84fcac6ceaa7f1e9781dbd18cc59eeea4f4bb56b  Orbitask-v0.9.1-android.apk
3b59ae7bacd76d238ed5e9ece9b40ff7d704929110d7b26af5dbf3e7392d9a20  Orbitask-v0.9.1-linux-amd64.deb
3add91f924945f83c544639b45788ab14cd884da24d5254526f7fd29f00a1d4e  Orbitask-v0.9.1-linux-x64-portable.tar.gz
7eaddd2846aec2e865139b5cd48e9678701633f66bf5c05d9cb248823cd565aa  Orbitask-v0.9.1-windows-setup.exe
0fd561ebdc6ff168db3fe06636b49c35eed81e5709ffe656d0a658bce5de028e  Orbitask-v0.9.1-windows-x64-portable.zip
```

## Limpieza post-release

- Eliminada la rama remota `chore/v0.9.1-hardening`.
- Eliminada la rama remota temporal `darkhmdda-patch-1`.
- Eliminado `Orbitask-v0.9.1-test-android.apk` de la prerelease histórica `v0.9-dev`.
- La prerelease `v0.9-dev` se conserva como referencia histórica.
- Las ramas automáticas de Dependabot se conservan para revisión posterior.
- Los tags de archivo históricos se conservan.

## Nota

La versión v0.9.1 queda cerrada. Cualquier cambio posterior debe entrar en un nuevo ciclo de desarrollo.
