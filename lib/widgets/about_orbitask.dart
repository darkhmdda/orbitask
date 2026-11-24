import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_version.dart';
import '../core/changelog.dart';
import 'orbitask_brand.dart';

/// Pestaña «Acerca de» de Ajustes: versión, notas y descarga.
class AboutOrbitask extends StatefulWidget {
  const AboutOrbitask({super.key, required this.compact});

  final bool compact;

  @override
  State<AboutOrbitask> createState() => _AboutOrbitaskState();
}

class _AboutData {
  const _AboutData(this.version, this.sections);

  final OrbitaskVersion version;
  final List<ChangelogSection> sections;
}

class _AboutOrbitaskState extends State<AboutOrbitask> {
  late final Future<_AboutData> _data = _load();

  Future<_AboutData> _load() async {
    var version = '?';
    var buildNumber = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      buildNumber = info.buildNumber;
    } catch (_) {
      // Sin versión se sigue mostrando el resto.
    }

    var sections = const <ChangelogSection>[];
    try {
      sections = parseChangelog(await rootBundle.loadString('CHANGELOG.md'));
    } catch (_) {
      // Sin notas se sigue mostrando la versión y la descarga.
    }

    return _AboutData(
      OrbitaskVersion(
        version: version,
        buildNumber: buildNumber,
        tag: orbitaskReleaseTag,
        isWeb: kIsWeb,
      ),
      sections,
    );
  }

  Future<void> _openDownload(Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('No se pudo abrir $uri')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AboutData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildContent(context, data);
      },
    );
  }

  Widget _buildContent(BuildContext context, _AboutData data) {
    final theme = Theme.of(context);
    final version = data.version;
    final current = currentChangelogSection(
      data.sections,
      version: version.version,
      preferLatest: version.isPrerelease || version.isWeb,
    );
    final older = data.sections
        .where((section) => section != current && !section.isEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Acerca de',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _VersionCard(
            version: version,
            compact: widget.compact,
            onDownload: () => _openDownload(version.downloadUri),
          ),
          const SizedBox(height: 20),
          if (current != null) ...[
            Text(
              !current.isUnreleased
                  ? 'Novedades de la versión ${current.title}'
                  : version.isPrerelease
                      ? 'Novedades de esta versión de prueba'
                      : 'Cambios aún sin publicar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ChangelogSectionView(section: current),
          ] else
            Text(
              'No hay notas de la versión disponibles.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (older.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Versiones anteriores',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            for (final section in older)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                title: Text(_sectionLabel(section)),
                children: [ChangelogSectionView(section: section)],
              ),
          ],
        ],
      ),
    );
  }

  static String _sectionLabel(ChangelogSection section) {
    final title = section.isUnreleased ? 'En desarrollo' : section.title;
    return section.date == null ? title : '$title · ${section.date}';
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.compact,
    required this.onDownload,
  });

  final OrbitaskVersion version;
  final bool compact;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OrbitaskBrand(compact: true),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              version.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (version.isPrerelease)
              Chip(
                label: const Text('Versión de prueba'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text('${version.detail} · ${_platformName()}', style: muted),
        if (version.isWeb) ...[
          const SizedBox(height: 8),
          Text(
            'La web se actualiza sola al publicar cambios. Recarga la página para tener la última versión.',
            style: muted,
          ),
        ],
      ],
    );

    final button = FilledButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download_rounded),
      label: Text(
        version.isWeb
            ? 'Descargar la app'
            : version.isPrerelease
                ? 'Ver versiones'
                : 'Descargar la última versión',
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, const SizedBox(height: 14), button],
            )
          : Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 12),
                button,
              ],
            ),
    );
  }

  static String _platformName() {
    if (kIsWeb) {
      return 'Web';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }
}

/// Muestra una sección del changelog: grupos, viñetas y párrafos.
class ChangelogSectionView extends StatelessWidget {
  const ChangelogSectionView({super.key, required this.section});

  final ChangelogSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    for (final group in section.groups) {
      if (group.title != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              group.title!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }
      for (final block in group.blocks) {
        children.add(_buildBlock(theme, block));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildBlock(ThemeData theme, ChangelogBlock block) {
    final text = Text.rich(
      TextSpan(children: _spans(theme, block.text)),
      style: theme.textTheme.bodyMedium,
    );
    if (!block.bullet) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: text,
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * block.depth, top: 3, bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Text(
              block.depth == 0 ? '•' : '◦',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(child: text),
        ],
      ),
    );
  }

  static List<InlineSpan> _spans(ThemeData theme, String text) {
    return [
      for (final part in parseChangelogInline(text))
        switch (part.style) {
          ChangelogInlineStyle.normal => TextSpan(text: part.text),
          ChangelogInlineStyle.bold => TextSpan(
              text: part.text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ChangelogInlineStyle.code => TextSpan(
              text: part.text,
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
        },
    ];
  }
}
