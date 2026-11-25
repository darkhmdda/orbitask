import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitask/core/app_version.dart';
import 'package:orbitask/core/changelog.dart';

const _muestra = '''
# Changelog

Texto de cabecera que se ignora.

## [Sin publicar]

### Añadido

- Pestaña **Acerca de**.
  - Con la versión en `pubspec.yaml`.
- Entrada que sigue
  en la línea siguiente.

### Interno

- Cambio técnico que no se muestra.

### Documentación

- README nuevo.

## [1.0.1] - 2026-10-06

Hotfix de estabilidad.

### Corregido

- Sincronización arreglada.

## [1.0.0] - 2026-10-05

### Interno

- Solo técnico.
''';

void main() {
  group('parseChangelog', () {
    final sections = parseChangelog(_muestra);

    test('lee las secciones en orden con su fecha', () {
      expect(sections.map((s) => s.title), [
        'Sin publicar',
        '1.0.1',
        '1.0.0',
      ]);
      expect(sections[0].isUnreleased, isTrue);
      expect(sections[0].date, isNull);
      expect(sections[1].date, '2026-10-06');
    });

    test('oculta los grupos Interno y Documentación', () {
      expect(sections[0].groups.map((g) => g.title), ['Añadido']);
      expect(sections[2].isEmpty, isTrue);
    });

    test('lee viñetas anidadas y une las líneas partidas', () {
      final blocks = sections[0].groups.single.blocks;
      expect(blocks, hasLength(3));
      expect(blocks[0].depth, 0);
      expect(blocks[1].depth, 1);
      expect(blocks[1].text, 'Con la versión en `pubspec.yaml`.');
      expect(blocks[2].text, 'Entrada que sigue en la línea siguiente.');
    });

    test('guarda la introducción como un grupo sin título', () {
      final intro = sections[1].groups.first;
      expect(intro.title, isNull);
      expect(intro.blocks.single.bullet, isFalse);
      expect(intro.blocks.single.text, 'Hotfix de estabilidad.');
    });
  });

  group('currentChangelogSection', () {
    final sections = parseChangelog(_muestra);

    test('una versión de prueba muestra la primera sección con contenido', () {
      final section = currentChangelogSection(
        sections,
        version: '1.0.1',
        preferLatest: true,
      );
      expect(section?.title, 'Sin publicar');
    });

    test('una versión estable muestra la de su número', () {
      final section = currentChangelogSection(
        sections,
        version: '1.0.1',
        preferLatest: false,
      );
      expect(section?.title, '1.0.1');
    });

    test('si no encuentra su número, muestra la primera con contenido', () {
      final section = currentChangelogSection(
        sections,
        version: '9.9.9',
        preferLatest: false,
      );
      expect(section?.title, 'Sin publicar');
    });

    test('se salta las secciones vacías', () {
      final soloVacias = parseChangelog('## [Sin publicar]\n\n## [1.0.0]\n');
      expect(
        currentChangelogSection(
          soloVacias,
          version: '1.0.0',
          preferLatest: true,
        ),
        isNull,
      );
    });
  });

  group('parseChangelogInline', () {
    test('separa negrita y código', () {
      expect(parseChangelogInline('Usa **Ajustes** y `flutter test`.'), const [
        ChangelogInline('Usa ', ChangelogInlineStyle.normal),
        ChangelogInline('Ajustes', ChangelogInlineStyle.bold),
        ChangelogInline(' y ', ChangelogInlineStyle.normal),
        ChangelogInline('flutter test', ChangelogInlineStyle.code),
        ChangelogInline('.', ChangelogInlineStyle.normal),
      ]);
    });

    test('deja tal cual los marcadores sin cerrar', () {
      expect(parseChangelogInline('a ** b ` c'), const [
        ChangelogInline('a ** b ` c', ChangelogInlineStyle.normal),
      ]);
    });
  });

  test('el CHANGELOG.md real se lee y su primera sección tiene contenido', () {
    final sections = parseChangelog(File('CHANGELOG.md').readAsStringSync());
    expect(sections, isNotEmpty);
    final current = currentChangelogSection(
      sections,
      version: '',
      preferLatest: true,
    );
    expect(current, isNotNull);
    expect(
      current!.groups.map((g) => g.title),
      isNot(contains('Interno')),
    );
  });

  group('OrbitaskVersion', () {
    test('una etiqueta con guion es una versión de prueba', () {
      const version = OrbitaskVersion(
        version: '1.0.1',
        buildNumber: '13',
        tag: 'v0.19-dev',
      );
      expect(version.isPrerelease, isTrue);
      expect(version.label, 'v0.19-dev');
      expect(version.detail, 'Basada en 1.0.1+13');
      expect(version.downloadUri.toString(), orbitaskReleasesUrl);
    });

    test('una etiqueta estable igual a la versión no repite «Basada en»', () {
      const version = OrbitaskVersion(
        version: '1.1.0',
        buildNumber: '14',
        tag: 'v1.1.0',
      );
      expect(version.isPrerelease, isFalse);
      expect(version.label, '1.1.0');
      expect(version.detail, 'Compilación 14');
      expect(
        version.downloadUri.toString(),
        '$orbitaskReleasesUrl/latest',
      );
    });

    test('una etiqueta igual a la versión pero sin «v» también coincide', () {
      const version = OrbitaskVersion(
        version: '1.1.0',
        buildNumber: '14',
        tag: '1.1.0',
      );
      expect(version.label, '1.1.0');
      expect(version.detail, 'Compilación 14');
    });

    test('una versión de prueba sobre la 1.1.0 sigue diciendo «Basada en»',
        () {
      const version = OrbitaskVersion(
        version: '1.1.0',
        buildNumber: '14',
        tag: 'v0.26-dev',
      );
      expect(version.isPrerelease, isTrue);
      expect(version.label, 'v0.26-dev');
      expect(version.detail, 'Basada en 1.1.0+14');
      expect(version.downloadUri.toString(), orbitaskReleasesUrl);
    });

    test('una etiqueta estable distinta de la versión mantiene «Basada en»',
        () {
      const version = OrbitaskVersion(
        version: '1.1.0',
        buildNumber: '14',
        tag: 'v1.2.0',
      );
      expect(version.isPrerelease, isFalse);
      expect(version.label, 'v1.2.0');
      expect(version.detail, 'Basada en 1.1.0+14');
    });

    test('sin etiqueta se muestra la versión y se enlaza la última estable',
        () {
      const version = OrbitaskVersion(version: '1.1.0', buildNumber: '14');
      expect(version.isPrerelease, isFalse);
      expect(version.label, '1.1.0');
      expect(version.detail, 'Compilación 14');
      expect(
        version.downloadUri.toString(),
        '$orbitaskReleasesUrl/latest',
      );
    });
  });
}
