import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/screens/home_screen.dart';
import 'package:yoltec_mobile/screens/login_screen.dart';
import 'package:yoltec_mobile/screens/splash_screen.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/bitacora_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/services/ia_priority_service.dart';
import 'package:yoltec_mobile/services/notification_service.dart';
import 'package:yoltec_mobile/services/pre_evaluacion_service.dart';
import 'package:yoltec_mobile/services/receta_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  runApp(const YoltecApp());
}

class YoltecApp extends StatelessWidget {
  const YoltecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CitaService()),
        ChangeNotifierProvider(create: (_) => BitacoraService()),
        ChangeNotifierProvider(create: (_) => RecetaService()),
        ChangeNotifierProvider(create: (_) => PreEvaluacionService()),
        ChangeNotifierProvider(create: (_) => IAPriorityService()),
      ],
      child: MaterialApp(
        title: 'Yoltec - Consultorio Medico',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        locale: const Locale('es', 'MX'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'MX'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Cargando...',
                    style: TextStyle(color: AppTheme.gray600),
                  ),
                ],
              ),
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
