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
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return _PasswordRecoveryScreen(authService: authService);
        }

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


class _PasswordRecoveryScreen extends StatefulWidget {
  const _PasswordRecoveryScreen({
    required this.authService,
  });

  final AuthService authService;

  @override
  State<_PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<_PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await widget.authService.updatePassword(_passwordController.text);
      if (!mounted) return;

      setState(() {
        _message =
            'Contraseña actualizada. Inicia sesión nuevamente con tu nueva contraseña.';
      });

      await widget.authService.signOut();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = 'No se pudo actualizar la contraseña: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.lock_reset_rounded, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Crea una nueva contraseña',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'El enlace de recuperación fue aceptado por Orbitask.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').length < 6) {
                              return 'Usa al menos 6 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _savePassword(),
                          decoration: const InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: Icon(Icons.lock_reset_rounded),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden.';
                            }
                            return null;
                          },
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _message!,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _loading ? null : _savePassword,
                          icon: _loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.password_rounded),
                          label: Text(
                            _loading
                                ? 'Actualizando…'
                                : 'Guardar nueva contraseña',
                          ),
                        ),
                      ],
                    ),
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
