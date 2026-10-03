import 'package:flutter/material.dart';

class OrbitaskBrand extends StatelessWidget {
  const OrbitaskBrand({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final markSize = compact ? 30.0 : 38.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: markSize,
          height: markSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: markSize,
                height: markSize,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.primary,
                    width: 1.8,
                  ),
                ),
              ),
              Icon(
                Icons.check_rounded,
                color: scheme.primary,
                size: compact ? 19 : 23,
              ),
              Positioned(
                top: compact ? 2 : 3,
                right: compact ? 1 : 2,
                child: Container(
                  width: compact ? 7 : 9,
                  height: compact ? 7 : 9,
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surfaceContainerHigh,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 8 : 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Orb',
                style: TextStyle(color: scheme.onSurface),
              ),
              TextSpan(
                text: 'i',
                style: TextStyle(color: scheme.primary),
              ),
              TextSpan(
                text: 'task',
                style: TextStyle(color: scheme.onSurface),
              ),
            ],
          ),
          style: (compact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleLarge)
              ?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }
}
