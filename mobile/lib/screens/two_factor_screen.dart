import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/widgets/custom_button.dart';
import 'package:yoltec_mobile/widgets/custom_text_field.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      setState(() {
        _errorMessage = 'El código debe tener 6 dígitos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.verify2FA(_codeController.text);

    setState(() {
      _isLoading = false;
      if (!result['success']) {
        _errorMessage = result['message'];
      }
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Verificación exitosa!')),
      );
      // AuthWrapper manejará la navegación automáticamente
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.resend2FA();

    setState(() {
      _isResending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final maskedEmail = authService.maskedEmail ?? 't***@email.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Seguridad'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            authService.logout(); // Limpiar estado temporal
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono
                Icon(
                  Icons.security,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),

                // Título
                Text(
                  'Autenticación de Dos Factores',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Instrucciones
                Text(
                  'Hemos enviado un código de verificación a:\n$maskedEmail',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Mensaje de error
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Campo de código
                CustomTextField(
                  controller: _codeController,
                  label: 'Código de verificación',
                  hint: '123456',
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  prefixIcon: Icons.confirmation_num_outlined,
                ),
                const SizedBox(height: 24),

                // Botón verificar
                CustomButton(
                  text: 'Verificar Código',
                  onPressed: _verifyCode,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),

                // Botón reenviar
                TextButton(
                  onPressed: _isResending ? null : _resendCode,
                  child: _isResending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('¿No recibiste el código? Reenviar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
