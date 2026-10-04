import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(
    this._client, {
    this.emailRedirectTo,
  });

  final SupabaseClient? _client;
  final String? emailRedirectTo;

  bool get isConfigured => _client != null;

  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final client = _requireClient();
    final name = displayName?.trim();

    return client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: emailRedirectTo,
      data: name == null || name.isEmpty
          ? null
          : <String, dynamic>{'display_name': name},
    );
  }

  Future<void> sendPasswordReset(String email) async {
    final client = _requireClient();
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: emailRedirectTo,
    );
  }

  Future<UserResponse> updatePassword(String password) async {
    final client = _requireClient();
    return client.auth.updateUser(
      UserAttributes(password: password),
    );
  }

  Future<UserResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final client = _requireClient();
    final email = client.auth.currentUser?.email;

    if (email == null || email.isEmpty) {
      throw StateError(
        'La sesión actual no tiene un correo disponible para verificar la cuenta.',
      );
    }

    await client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    return client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase no está configurado para esta ejecución de Orbitask.',
      );
    }
    return client;
  }
}
