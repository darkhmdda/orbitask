import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.signedInChild,
  });

  final AuthService authService;
  final Widget signedInChild;

  @override
  Widget build(BuildContext context) {
    final stream = authService.authStateChanges;
    if (stream == null) return signedInChild;

    return StreamBuilder<AuthState>(
      stream: stream,
      builder: (context, snapshot) {
        if (authService.currentUser != null) {
          return signedInChild;
        }

        return AuthScreen(authService: authService);
      },
    );
  }
}
