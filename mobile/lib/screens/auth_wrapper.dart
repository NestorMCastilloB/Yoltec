import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/screens/home_screen.dart';
import 'package:yoltec_mobile/screens/login_screen.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

/// Raíz reactiva de la app: escucha cambios en AuthService y muestra
/// la pantalla correspondiente sin necesidad de navegación explícita.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }
        return authService.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
