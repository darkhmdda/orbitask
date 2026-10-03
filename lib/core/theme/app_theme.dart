import 'package:flutter/material.dart';

class OrbitaskThemePreset {
  const OrbitaskThemePreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.light,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.hover,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accent2,
    required this.chipBg,
    required this.chipText,
    required this.chipSelectedBg,
    required this.chipSelectedText,
  });

  final String id;
  final String name;
  final String icon;
  final bool light;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color hover;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accent2;
  final Color chipBg;
  final Color chipText;
  final Color chipSelectedBg;
  final Color chipSelectedText;

  Brightness get brightness => light ? Brightness.light : Brightness.dark;
}

class AppTheme {
  AppTheme._();

  static const String defaultThemeId = 'emilia';

  static const List<OrbitaskThemePreset> presets = [
    OrbitaskThemePreset(
      id: 'rimuru',
      name: 'Rimuru',
      icon: '💧',
      light: false,
      bg: Color(0xFF06131D),
      surface: Color(0xFF0A1D2A),
      surface2: Color(0xFF10293A),
      hover: Color(0xFF15364A),
      border: Color(0xFF28536B),
      text: Color(0xFFEDF9FF),
      muted: Color(0xFF9BB8C8),
      accent: Color(0xFF45BDF2),
      accent2: Color(0xFF8CDDFF),
      chipBg: Color(0xFF10293A),
      chipText: Color(0xFFDFF6FF),
      chipSelectedBg: Color(0xFF45BDF2),
      chipSelectedText: Color(0xFF04131C),
    ),
    OrbitaskThemePreset(
      id: 'emilia',
      name: 'Emilia',
      icon: '💜',
      light: true,
      bg: Color(0xFFE2E3EB),
      surface: Color(0xFFECECF3),
      surface2: Color(0xFFD2CCDF),
      hover: Color(0xFFC7BDD8),
      border: Color(0xFF8F7AAA),
      text: Color(0xFF513A66),
      muted: Color(0xFF776584),
      accent: Color(0xFF76519F),
      accent2: Color(0xFF9470BB),
      chipBg: Color(0xFFCEC5DC),
      chipText: Color(0xFF49365B),
      chipSelectedBg: Color(0xFF76519F),
      chipSelectedText: Color(0xFFFFFFFF),
    ),
    OrbitaskThemePreset(
      id: 'itsuki',
      name: 'Itsuki',
      icon: '🌺',
      light: false,
      bg: Color(0xFF14090B),
      surface: Color(0xFF1D0E11),
      surface2: Color(0xFF2A1519),
      hover: Color(0xFF32181D),
      border: Color(0xFF64343C),
      text: Color(0xFFFFF0ED),
      muted: Color(0xFFD5AAA5),
      accent: Color(0xFFE45F68),
      accent2: Color(0xFFFF8A7A),
      chipBg: Color(0xFF2A1519),
      chipText: Color(0xFFFFD9D4),
      chipSelectedBg: Color(0xFFE45F68),
      chipSelectedText: Color(0xFF210709),
    ),
    OrbitaskThemePreset(
      id: 'rem',
      name: 'Rem',
      icon: '❄️',
      light: false,
      bg: Color(0xFF07101A),
      surface: Color(0xFF0C1825),
      surface2: Color(0xFF132437),
      hover: Color(0xFF172B42),
      border: Color(0xFF31516F),
      text: Color(0xFFEDF7FF),
      muted: Color(0xFFA6BED1),
      accent: Color(0xFF72B9ED),
      accent2: Color(0xFF9DDCFF),
      chipBg: Color(0xFF132437),
      chipText: Color(0xFFD9F1FF),
      chipSelectedBg: Color(0xFF72B9ED),
      chipSelectedText: Color(0xFF04111C),
    ),
    OrbitaskThemePreset(
      id: 'veldora',
      name: 'Veldora',
      icon: '🟣',
      light: false,
      bg: Color(0xFF090711),
      surface: Color(0xFF110C1C),
      surface2: Color(0xFF1D1430),
      hover: Color(0xFF281A3E),
      border: Color(0xFF53377C),
      text: Color(0xFFF5EFFF),
      muted: Color(0xFFB9A8D0),
      accent: Color(0xFF8D5CE6),
      accent2: Color(0xFFB78CFF),
      chipBg: Color(0xFF1D1430),
      chipText: Color(0xFFEADFFF),
      chipSelectedBg: Color(0xFF8D5CE6),
      chipSelectedText: Color(0xFF10071C),
    ),
    OrbitaskThemePreset(
      id: 'zoro',
      name: 'Zoro',
      icon: '🟢',
      light: false,
      bg: Color(0xFF07100B),
      surface: Color(0xFF0D1811),
      surface2: Color(0xFF14241A),
      hover: Color(0xFF192D20),
      border: Color(0xFF31583D),
      text: Color(0xFFEDF5EF),
      muted: Color(0xFFA5B9AA),
      accent: Color(0xFF4FAE5A),
      accent2: Color(0xFF82D173),
      chipBg: Color(0xFF14241A),
      chipText: Color(0xFFDFF2E2),
      chipSelectedBg: Color(0xFF4FAE5A),
      chipSelectedText: Color(0xFF041008),
    ),
  ];

  static OrbitaskThemePreset presetFor(String? id) {
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return presets.firstWhere((preset) => preset.id == defaultThemeId);
  }

  static String normalizeThemeId(String? id) => presetFor(id).id;

  static ThemeData forPreset(String? id) {
    final preset = presetFor(id);

    final scheme = ColorScheme.fromSeed(
      seedColor: preset.accent,
      brightness: preset.brightness,
    ).copyWith(
      primary: preset.accent,
      onPrimary: preset.chipSelectedText,
      primaryContainer: preset.surface2,
      onPrimaryContainer: preset.text,
      secondary: preset.accent2,
      onSecondary: preset.chipSelectedText,
      secondaryContainer: preset.hover,
      onSecondaryContainer: preset.text,
      surface: preset.surface,
      onSurface: preset.text,
      surfaceContainerLowest: preset.bg,
      surfaceContainerLow: preset.surface,
      surfaceContainer: preset.surface2,
      surfaceContainerHigh: preset.hover,
      surfaceContainerHighest: preset.chipBg,
      onSurfaceVariant: preset.muted,
      outline: preset.border,
      outlineVariant: preset.border.withValues(alpha: 0.65),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: preset.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: preset.bg,
      dividerColor: preset.border.withValues(alpha: 0.6),
      iconTheme: IconThemeData(color: preset.muted),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: preset.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: preset.border.withValues(alpha: 0.22),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: preset.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: preset.surface2,
        prefixIconColor: preset.muted,
        suffixIconColor: preset.muted,
        hintStyle: TextStyle(color: preset.muted),
        labelStyle: TextStyle(color: preset.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: preset.border.withValues(alpha: 0.28),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: preset.accent, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: preset.muted,
        textColor: preset.text,
        selectedColor: preset.accent,
        selectedTileColor: preset.hover,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: preset.surface,
        indicatorColor: preset.hover,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? preset.accent
                : preset.muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? preset.accent
                : preset.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: preset.chipBg,
        selectedColor: preset.chipSelectedBg,
        disabledColor: preset.chipBg.withValues(alpha: 0.5),
        side: BorderSide(
          color: preset.border.withValues(alpha: 0.35),
        ),
        labelStyle: TextStyle(color: preset.chipText),
        secondaryLabelStyle: TextStyle(color: preset.chipSelectedText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: preset.accent,
        foregroundColor: preset.chipSelectedText,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: preset.accent,
          foregroundColor: preset.chipSelectedText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: preset.accent,
          side: BorderSide(color: preset.border),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return preset.accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(preset.chipSelectedText),
        side: BorderSide(color: preset.muted, width: 1.6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: preset.accent,
        linearTrackColor: preset.surface2,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: preset.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: preset.surface2,
        contentTextStyle: TextStyle(color: preset.text),
        actionTextColor: preset.accent2,
      ),
    );
  }
}
