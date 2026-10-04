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
      bg: Color(0xFF07111C),
      surface: Color(0xFF0B1B2B),
      surface2: Color(0xFF102A40),
      hover: Color(0xFF183A55),
      border: Color(0xFF2D5D7A),
      text: Color(0xFFF0FAFF),
      muted: Color(0xFFA7C7D8),
      accent: Color(0xFF4DCBFF),
      accent2: Color(0xFF657DFF),
      chipBg: Color(0xFF102A40),
      chipText: Color(0xFFE2F7FF),
      chipSelectedBg: Color(0xFF4DCBFF),
      chipSelectedText: Color(0xFF04121C),
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
      light: true,
      bg: Color(0xFFF1F5FF),
      surface: Color(0xFFFBFCFF),
      surface2: Color(0xFFE3ECFF),
      hover: Color(0xFFD6E2FA),
      border: Color(0xFF9DB6DE),
      text: Color(0xFF32415F),
      muted: Color(0xFF667896),
      accent: Color(0xFF6E9FE6),
      accent2: Color(0xFFB09DDE),
      chipBg: Color(0xFFE3ECFF),
      chipText: Color(0xFF405374),
      chipSelectedBg: Color(0xFF6E9FE6),
      chipSelectedText: Color(0xFFFFFFFF),
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
      id: 'luffy',
      name: 'Luffy',
      icon: '☀️',
      light: false,
      bg: Color(0xFF140A08),
      surface: Color(0xFF21100D),
      surface2: Color(0xFF321914),
      hover: Color(0xFF42231B),
      border: Color(0xFF6B3C2A),
      text: Color(0xFFFFF4DE),
      muted: Color(0xFFD2B99B),
      accent: Color(0xFFE84A3A),
      accent2: Color(0xFFF2C14E),
      chipBg: Color(0xFF321914),
      chipText: Color(0xFFFFE8CC),
      chipSelectedBg: Color(0xFFE84A3A),
      chipSelectedText: Color(0xFFFFFFFF),
    ),
    OrbitaskThemePreset(
      id: 'senku',
      name: 'Senku',
      icon: '🧪',
      light: true,
      bg: Color(0xFFF0F1E5),
      surface: Color(0xFFFAFAF2),
      surface2: Color(0xFFE4E8D1),
      hover: Color(0xFFD7DEBE),
      border: Color(0xFF98A96A),
      text: Color(0xFF263126),
      muted: Color(0xFF63705A),
      accent: Color(0xFF7DA63A),
      accent2: Color(0xFFC6D84A),
      chipBg: Color(0xFFE4E8D1),
      chipText: Color(0xFF35412E),
      chipSelectedBg: Color(0xFF7DA63A),
      chipSelectedText: Color(0xFFFFFFFF),
    ),
    OrbitaskThemePreset(
      id: 'marin',
      name: 'Marin Kitagawa',
      icon: '💖',
      light: true,
      bg: Color(0xFFFFF4F8),
      surface: Color(0xFFFFFBFD),
      surface2: Color(0xFFFCE5EF),
      hover: Color(0xFFF8D3E2),
      border: Color(0xFFE5A5BF),
      text: Color(0xFF543342),
      muted: Color(0xFF886A77),
      accent: Color(0xFFE66A9A),
      accent2: Color(0xFFF0B84B),
      chipBg: Color(0xFFFCE5EF),
      chipText: Color(0xFF633646),
      chipSelectedBg: Color(0xFFE66A9A),
      chipSelectedText: Color(0xFFFFFFFF),
    ),
    OrbitaskThemePreset(
      id: 'gojo',
      name: 'Satoru Gojo',
      icon: '🔵',
      light: false,
      bg: Color(0xFF020308),
      surface: Color(0xFF070A12),
      surface2: Color(0xFF0D1220),
      hover: Color(0xFF151D30),
      border: Color(0xFF263A60),
      text: Color(0xFFF5F8FF),
      muted: Color(0xFF94A3BD),
      accent: Color(0xFF2D7CFF),
      accent2: Color(0xFFA35CFF),
      chipBg: Color(0xFF0D1220),
      chipText: Color(0xFFE8EFFF),
      chipSelectedBg: Color(0xFF2D7CFF),
      chipSelectedText: Color(0xFFFFFFFF),
    ),
    OrbitaskThemePreset(
      id: 'deku',
      name: 'Deku',
      icon: '⚡',
      light: false,
      bg: Color(0xFF06110E),
      surface: Color(0xFF0B1B16),
      surface2: Color(0xFF123026),
      hover: Color(0xFF194132),
      border: Color(0xFF2E6651),
      text: Color(0xFFF0FFF8),
      muted: Color(0xFFA8C9BB),
      accent: Color(0xFF39C99A),
      accent2: Color(0xFF7FE8C8),
      chipBg: Color(0xFF123026),
      chipText: Color(0xFFDDF9EF),
      chipSelectedBg: Color(0xFF39C99A),
      chipSelectedText: Color(0xFF03110D),
    ),
    OrbitaskThemePreset(
      id: 'eren',
      name: 'Eren',
      icon: '🪽',
      light: false,
      bg: Color(0xFF0D0E0B),
      surface: Color(0xFF151710),
      surface2: Color(0xFF202419),
      hover: Color(0xFF2A3020),
      border: Color(0xFF4E5A3A),
      text: Color(0xFFF1F0E6),
      muted: Color(0xFFB5B4A3),
      accent: Color(0xFF71844A),
      accent2: Color(0xFFC4A76A),
      chipBg: Color(0xFF202419),
      chipText: Color(0xFFE9E7D6),
      chipSelectedBg: Color(0xFF71844A),
      chipSelectedText: Color(0xFFF8F8F2),
    ),
    OrbitaskThemePreset(
      id: 'zoro',
      name: 'Zoro',
      icon: '🟢',
      light: false,
      bg: Color(0xFF0B0D08),
      surface: Color(0xFF14170F),
      surface2: Color(0xFF202617),
      hover: Color(0xFF2C3420),
      border: Color(0xFF59683C),
      text: Color(0xFFF0EEDF),
      muted: Color(0xFFB2B09E),
      accent: Color(0xFF728A3A),
      accent2: Color(0xFFC0A24E),
      chipBg: Color(0xFF202617),
      chipText: Color(0xFFE8E4D1),
      chipSelectedBg: Color(0xFF728A3A),
      chipSelectedText: Color(0xFFFFFFFF),
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
