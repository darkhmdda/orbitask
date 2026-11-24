import 'package:material_ui/material_ui.dart';

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
    final markHeight = compact ? 28.0 : 36.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OrbitaskLogoMark(height: markHeight),
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

/// Marca de Orbitask (agujero negro con anillo).
///
/// Es una imagen generada por `branding/build_branding.py` a partir del logo
/// vectorial. Tiene sus propios colores, así que no depende del tema.
class OrbitaskLogoMark extends StatelessWidget {
  const OrbitaskLogoMark({
    super.key,
    required this.height,
  });

  static const String assetPath = 'assets/branding/orbitask_mark.png';
  static const double _aspectRatio = 480 / 263;

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      width: height * _aspectRatio,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Logo de Orbitask',
    );
  }
}
