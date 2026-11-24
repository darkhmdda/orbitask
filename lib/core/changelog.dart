/// Lectura del `CHANGELOG.md` que la app lleva como asset.
///
/// Solo entiende el subconjunto de Markdown que usa el archivo: secciones
/// `## [versión] - fecha`, grupos `### Título`, viñetas con sangría,
/// párrafos, **negrita** y `código`. Los grupos `### Interno` y
/// `### Documentación` no se muestran en la app: recogen cambios técnicos
/// (workflows, migraciones, documentos del repositorio).
library;

/// Grupos que la app no muestra.
const Set<String> changelogHiddenGroups = {'Interno', 'Documentación'};

/// Título de la sección con los cambios aún sin versión.
const String changelogUnreleasedTitle = 'Sin publicar';

class ChangelogSection {
  const ChangelogSection({
    required this.title,
    required this.date,
    required this.groups,
  });

  /// Texto entre corchetes: `1.0.1` o `Sin publicar`.
  final String title;

  /// Fecha tras el guion, si la hay (`2026-10-06`).
  final String? date;

  final List<ChangelogGroup> groups;

  bool get isUnreleased => title == changelogUnreleasedTitle;

  bool get isEmpty => groups.every((group) => group.blocks.isEmpty);
}

class ChangelogGroup {
  const ChangelogGroup({required this.title, required this.blocks});

  /// Título del `###`. Es `null` para los párrafos que van antes del primer
  /// grupo (la introducción de la versión).
  final String? title;

  final List<ChangelogBlock> blocks;
}

class ChangelogBlock {
  const ChangelogBlock({
    required this.text,
    required this.bullet,
    this.depth = 0,
  });

  final String text;
  final bool bullet;

  /// Nivel de sangría de la viñeta (0 = primer nivel).
  final int depth;
}

enum ChangelogInlineStyle { normal, bold, code }

class ChangelogInline {
  const ChangelogInline(this.text, this.style);

  final String text;
  final ChangelogInlineStyle style;

  @override
  bool operator ==(Object other) =>
      other is ChangelogInline && other.text == text && other.style == style;

  @override
  int get hashCode => Object.hash(text, style);

  @override
  String toString() => '${style.name}($text)';
}

final RegExp _sectionPattern = RegExp(r'^##\s+\[([^\]]+)\](?:\s*-\s*(.+))?\s*$');
final RegExp _groupPattern = RegExp(r'^###\s+(.+?)\s*$');
final RegExp _bulletPattern = RegExp(r'^(\s*)[-*]\s+(.*)$');

/// Convierte el changelog en secciones, de la más reciente a la más antigua.
///
/// Se ignora todo lo que va antes de la primera sección y los grupos de
/// [changelogHiddenGroups].
List<ChangelogSection> parseChangelog(String markdown) {
  final sections = <ChangelogSection>[];

  String? sectionTitle;
  String? sectionDate;
  var groups = <ChangelogGroup>[];
  String? groupTitle;
  var blocks = <ChangelogBlock>[];
  var skipGroup = false;
  var lastWasText = false;

  void closeGroup() {
    if (!skipGroup && blocks.isNotEmpty) {
      groups.add(ChangelogGroup(title: groupTitle, blocks: blocks));
    }
    blocks = <ChangelogBlock>[];
    groupTitle = null;
    skipGroup = false;
    lastWasText = false;
  }

  void closeSection() {
    if (sectionTitle == null) {
      return;
    }
    closeGroup();
    sections.add(
      ChangelogSection(title: sectionTitle, date: sectionDate, groups: groups),
    );
    groups = <ChangelogGroup>[];
  }

  for (final rawLine in markdown.split('\n')) {
    final line = rawLine.trimRight();

    final section = _sectionPattern.firstMatch(line);
    if (section != null) {
      closeSection();
      sectionTitle = section.group(1)!.trim();
      sectionDate = section.group(2)?.trim();
      continue;
    }
    if (sectionTitle == null) {
      continue;
    }

    final group = _groupPattern.firstMatch(line);
    if (group != null) {
      closeGroup();
      groupTitle = group.group(1);
      skipGroup = changelogHiddenGroups.contains(groupTitle);
      continue;
    }

    if (line.trim().isEmpty) {
      lastWasText = false;
      continue;
    }

    final bullet = _bulletPattern.firstMatch(line);
    if (bullet != null) {
      blocks.add(
        ChangelogBlock(
          text: bullet.group(2)!.trim(),
          bullet: true,
          depth: bullet.group(1)!.length ~/ 2,
        ),
      );
      lastWasText = true;
      continue;
    }

    // Línea de texto: continúa el bloque anterior o empieza un párrafo.
    final text = line.trim();
    if (lastWasText && blocks.isNotEmpty) {
      final previous = blocks.removeLast();
      blocks.add(
        ChangelogBlock(
          text: '${previous.text} $text',
          bullet: previous.bullet,
          depth: previous.depth,
        ),
      );
    } else {
      blocks.add(ChangelogBlock(text: text, bullet: false));
    }
    lastWasText = true;
  }
  closeSection();

  return sections;
}

/// Elige la sección que corresponde a la versión instalada.
///
/// En las versiones de prueba y en la web (que siempre sale de `main`) es la
/// primera sección con contenido, normalmente «Sin publicar». En una versión
/// estable se busca la de su número y, si no está, la primera con contenido.
ChangelogSection? currentChangelogSection(
  List<ChangelogSection> sections, {
  required String version,
  required bool preferLatest,
}) {
  final nonEmpty = sections.where((section) => !section.isEmpty);
  if (!preferLatest) {
    for (final section in nonEmpty) {
      if (section.title == version) {
        return section;
      }
    }
  }
  return nonEmpty.isEmpty ? null : nonEmpty.first;
}

/// Separa el texto en tramos normales, en **negrita** y en `código`.
List<ChangelogInline> parseChangelogInline(String text) {
  final result = <ChangelogInline>[];
  final buffer = StringBuffer();

  void flush() {
    if (buffer.isNotEmpty) {
      result.add(
        ChangelogInline(buffer.toString(), ChangelogInlineStyle.normal),
      );
      buffer.clear();
    }
  }

  var index = 0;
  while (index < text.length) {
    if (text.startsWith('`', index)) {
      final end = text.indexOf('`', index + 1);
      if (end > index + 1) {
        flush();
        result.add(
          ChangelogInline(
            text.substring(index + 1, end),
            ChangelogInlineStyle.code,
          ),
        );
        index = end + 1;
        continue;
      }
    } else if (text.startsWith('**', index)) {
      final end = text.indexOf('**', index + 2);
      if (end > index + 2) {
        flush();
        result.add(
          ChangelogInline(
            text.substring(index + 2, end),
            ChangelogInlineStyle.bold,
          ),
        );
        index = end + 2;
        continue;
      }
    }
    buffer.write(text[index]);
    index++;
  }
  flush();
  return result;
}
