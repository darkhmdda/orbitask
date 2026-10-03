import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/local_database.dart';
import '../../services/auth_service.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.database,
    required this.signedInChild,
  });

  final AuthService authService;
  final LocalDatabase database;
  final Widget signedInChild;

  @override
  Widget build(BuildContext context) {
    final stream = authService.authStateChanges;
    if (stream == null) return signedInChild;

    return StreamBuilder<AuthState>(
      stream: stream,
      builder: (context, snapshot) {
        final user = authService.currentUser;
        if (user != null) {
          final boundAccountId = database.getSetting('cloud_account_id');

          if (boundAccountId == null || boundAccountId.isEmpty) {
            database.setSetting('cloud_account_id', user.id);
            return signedInChild;
          }

          if (boundAccountId == user.id) {
            return signedInChild;
          }

          return _AccountMismatchScreen(
            authService: authService,
            email: user.email,
          );
        }

        return AuthScreen(authService: authService);
      },
    );
  }
}


class _AccountMismatchScreen extends StatelessWidget {
  const _AccountMismatchScreen({
    required this.authService,
    required this.email,
  });

  final AuthService authService;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Este espacio local pertenece a otra cuenta',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        email == null
                            ? 'Orbitask bloqueó el acceso para evitar mezclar datos locales entre cuentas.'
                            : 'La cuenta $email no coincide con la cuenta vinculada a este espacio local. Orbitask bloqueó el acceso para evitar mezclar datos.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () async {
                          await authService.signOut();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
