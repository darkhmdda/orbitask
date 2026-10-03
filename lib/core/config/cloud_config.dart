class CloudConfig {
  CloudConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const String supabaseAuthRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
  );

  static String? get authRedirectUrl {
    final value = supabaseAuthRedirectUrl.trim();
    return value.isEmpty ? null : value;
  }

  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty &&
      supabasePublishableKey.trim().isNotEmpty;
}
