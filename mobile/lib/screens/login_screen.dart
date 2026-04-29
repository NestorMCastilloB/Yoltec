import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores estudiante
  final _numeroControlCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureNip = true;

  final _formAlumnoKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (!_formAlumnoKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.login(
      _numeroControlCtrl.text.trim(),
      _nipCtrl.text,
      'alumno',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (!result['success']) {
        _errorMessage = result['message'] as String?;
      }
    });

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bienvenido a Yoltec'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _numeroControlCtrl.dispose();
    _nipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height < 700 ? 16 : 32,
                  horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      size: MediaQuery.of(context).size.height < 700 ? 36 : 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Yoltec',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consultorio Medico',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            // Tarjeta de formulario
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Formulario
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Error
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: AppTheme.error, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: AppTheme.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            _buildAlumnoForm(),

                            const SizedBox(height: 20),

                            // Botón principal
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Iniciar Sesión'),
                              ),
                            ),

                            const SizedBox(height: 20),
                            Text(
                              'Solo personal autorizado del Instituto Tecnologico',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.gray500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlumnoForm() {
    return Form(
      key: _formAlumnoKey,
      child: Column(
        children: [
          TextFormField(
            controller: _numeroControlCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Numero de Control',
              hintText: 'Ej. 22690495',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Ingresa tu numero de control';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nipCtrl,
            obscureText: _obscureNip,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'NIP',
              hintText: 'Tu NIP de acceso',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNip
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureNip = !_obscureNip),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Ingresa tu NIP';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

}
