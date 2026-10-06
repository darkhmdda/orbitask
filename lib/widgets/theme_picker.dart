import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ThemePicker extends StatelessWidget {
  const ThemePicker({
    super.key,
    required this.currentThemeId,
    required this.onSelected,
  });

  final String currentThemeId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 500
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppTheme.presets
              .map(
                (preset) => SizedBox(
                  width: cardWidth,
                  child: _ThemePreviewCard(
                    preset: preset,
                    selected: currentThemeId == preset.id,
                    onTap: () => onSelected(preset.id),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ThemePreviewCard extends StatefulWidget {
  const _ThemePreviewCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final OrbitaskThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemePreviewCard> createState() => _ThemePreviewCardState();
}

class _ThemePreviewCardState extends State<_ThemePreviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final selected = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _hovered && !selected ? 1.012 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: selected
                    ? Color.alphaBlend(
                        preset.accent.withValues(alpha: 0.10),
                        preset.surface,
                      )
                    : (_hovered ? preset.hover : preset.surface),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? preset.accent
                      : (_hovered
                          ? preset.accent.withValues(alpha: 0.60)
                          : preset.border),
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: preset.accent.withValues(alpha: 0.18),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? preset.accent.withValues(alpha: 0.16)
                          : preset.surface2,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: selected
                            ? preset.accent.withValues(alpha: 0.75)
                            : preset.border.withValues(alpha: 0.6),
                      ),
                    ),
                    child: _ThemePresetIcon(preset: preset),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                preset.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: preset.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: preset.accent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'En uso',
                                  style: TextStyle(
                                    color: preset.chipSelectedText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              preset.light
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              color: preset.muted,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              preset.light ? 'Tema claro' : 'Tema oscuro',
                              style: TextStyle(
                                color: preset.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            _ColorDot(color: preset.accent),
                            const SizedBox(width: 5),
                            _ColorDot(color: preset.accent2),
                            const SizedBox(width: 5),
                            _ColorDot(color: preset.hover),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? preset.accent : Colors.transparent,
                      border: Border.all(
                        color: selected ? preset.accent : preset.muted,
                        width: 1.6,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            color: preset.chipSelectedText,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _ThemePresetIcon extends StatelessWidget {
  const _ThemePresetIcon({required this.preset});

  final OrbitaskThemePreset preset;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      return Icon(
        _linuxIconFor(preset.id),
        size: 22,
        color: preset.accent,
      );
    }

    return Text(
      preset.icon,
      style: const TextStyle(fontSize: 21),
    );
  }

  IconData _linuxIconFor(String id) {
    return switch (id) {
      'rimuru' => Icons.water_drop_rounded,
      'emilia' => Icons.favorite_rounded,
      'itsuki' => Icons.local_florist_rounded,
      'rem' => Icons.ac_unit_rounded,
      'veldora' => Icons.circle_rounded,
      'luffy' => Icons.light_mode_rounded,
      'senku' => Icons.science_rounded,
      'marin' => Icons.favorite_rounded,
      'gojo' => Icons.circle_rounded,
      'deku' => Icons.bolt_rounded,
      'eren' => Icons.air_rounded,
      'zoro' => Icons.circle_rounded,
      _ => Icons.palette_rounded,
    };
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
