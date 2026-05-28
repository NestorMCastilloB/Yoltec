import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/screens/student/citas/citas_tab.dart';
import 'package:yoltec_mobile/screens/student/inicio_tab.dart';
import 'package:yoltec_mobile/screens/student/perfil/perfil_tab.dart';
import 'package:yoltec_mobile/screens/student/recetas_tab.dart';
import 'package:yoltec_mobile/screens/student/widgets/student_widgets.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/services/receta_service.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  Future<void> _cargarDatos() async {
    final token = Provider.of<AuthService>(context, listen: false).token ?? '';
    await Future.wait([
      Provider.of<CitaService>(context, listen: false).cargarCitas(token),
      Provider.of<RecetaService>(context, listen: false).cargarRecetas(token),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      InicioTab(
        onNuevaCita: () => setState(() => _tabIndex = 1),
        onIrRecetas: () => setState(() => _tabIndex = 2),
        onIrPerfil: () => setState(() => _tabIndex = 3),
      ),
      const CitasTab(),
      const RecetasTab(),
      const PerfilTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthService>(
          builder: (_, auth, __) =>
              Text('Hola, ${auth.currentUser?.nombre ?? ''}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmarLogout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner offline
          Consumer2<CitaService, RecetaService>(
            builder: (_, citas, recetas, __) {
              final offline = citas.isOffline || recetas.isOffline;
              return offline ? const OfflineBanner() : const SizedBox.shrink();
            },
          ),
          Expanded(child: tabs[_tabIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Recetas'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar tu sesion?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthService>(context, listen: false).logout();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
