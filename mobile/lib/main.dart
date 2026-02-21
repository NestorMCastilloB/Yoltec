import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/screens/login_screen.dart';
import 'package:yoltec_mobile/screens/home_screen.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

void main() {
  runApp(const YoltecApp());
}

class YoltecApp extends StatelessWidget {
  const YoltecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Yoltec - Consultorio Médico',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
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
