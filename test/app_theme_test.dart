import 'package:flutter_test/flutter_test.dart';
import 'package:orbitask/core/theme/app_theme.dart';

double _contrast(double a, double b) {
  final hi = a > b ? a : b;
  final lo = a > b ? b : a;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('AppTheme', () {
    test('los identificadores de los temas son únicos', () {
      final ids = AppTheme.presets.map((preset) => preset.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('un identificador desconocido o nulo vuelve al tema por defecto', () {
      expect(AppTheme.normalizeThemeId(null), AppTheme.defaultThemeId);
      expect(AppTheme.normalizeThemeId('no-existe'), AppTheme.defaultThemeId);
    });

    test('los temas nuevos existen y son oscuros', () {
      for (final id in ['subaru', 'asta']) {
        final preset = AppTheme.presetFor(id);
        expect(preset.id, id);
        expect(preset.light, isFalse);
      }
    });

    test('el texto principal tiene contraste suficiente sobre el fondo', () {
      for (final preset in AppTheme.presets) {
        final ratio = _contrast(
          preset.text.computeLuminance(),
          preset.bg.computeLuminance(),
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'Contraste insuficiente en el tema ${preset.id}',
        );
      }
    });
  });
}
