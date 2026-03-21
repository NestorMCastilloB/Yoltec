import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controladores estudiante
  final _numeroControlCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();

  // Controladores doctor
  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureNip = true;
  bool _obscurePassword = true;

  final _formAlumnoKey = GlobalKey<FormState>();
  final _formDoctorKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _errorMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _numeroControlCtrl.dispose();
    _nipCtrl.dispose();
    _usuarioCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final esAlumno = _tabController.index == 0;
    final formKey = esAlumno ? _formAlumnoKey : _formDoctorKey;

    if (!formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.login(
      esAlumno ? _numeroControlCtrl.text.trim() : _usuarioCtrl.text.trim(),
      esAlumno ? _nipCtrl.text : _passwordCtrl.text,
      esAlumno ? 'alumno' : 'doctor',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (!result['success']) {
        _errorMessage = result['message'] as String?;
      }
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bienvenido a Yoltec'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
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
              padding: const EdgeInsets.symmetric(
                  vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                decoration: const BoxDecoration(
                  color: AppTheme.gray50,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    // Tabs
                    Container(
                      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      decoration: BoxDecoration(
                        color: AppTheme.gray200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.gray600,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Estudiante'),
                          Tab(text: 'Doctor'),
                        ],
                      ),
                    ),

                    // Formularios
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
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEF9A9A),
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

                            // Contenido de tabs
                            SizedBox(
                              height: 280,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildAlumnoForm(),
                                  _buildDoctorForm(),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Boton
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
                                    : const Text('Iniciar Sesion'),
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

  Widget _buildDoctorForm() {
    return Form(
      key: _formDoctorKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usuarioCtrl,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Usuario',
              hintText: 'Nombre de usuario',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Ingresa tu usuario';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contrasena',
              hintText: 'Tu contrasena',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Ingresa tu contrasena';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
