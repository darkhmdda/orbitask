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

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final OrbitaskThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: preset.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? preset.accent : preset.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: preset.accent.withValues(alpha: 0.16),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: preset.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: preset.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  preset.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: TextStyle(
                        color: preset.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.light ? 'Tema claro' : 'Tema oscuro',
                      style: TextStyle(
                        color: preset.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
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
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: preset.accent,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
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
