import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/models/bitacora.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/bitacora_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDatos());
  }

  Future<void> _cargarDatos() async {
    final token =
        Provider.of<AuthService>(context, listen: false).token ?? '';
    await Future.wait([
      Provider.of<CitaService>(context, listen: false).cargarCitas(token),
      Provider.of<BitacoraService>(context, listen: false)
          .cargarBitacoras(token),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _DoctorInicioTab(),
      const _DoctorCitasTab(),
      const _DoctorBitacorasTab(),
      const _DoctorPreEvaluacionesTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthService>(
          builder: (_, auth, __) => Text(
              'Dr. ${auth.currentUser?.apellido ?? ''}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
            onPressed: () => _confirmarLogout(context),
          ),
        ],
      ),
      body: tabs[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Citas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder_open_outlined),
              activeIcon: Icon(Icons.folder_open),
              label: 'Bitacoras'),
          BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'Pre-eval.'),
        ],
      ),
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content:
            const Text('?Seguro que deseas cerrar tu sesion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthService>(context, listen: false).logout();
            },
            child: const Text('Cerrar sesion'),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Inicio Doctor ────────────────────────────────────────────────────────

class _DoctorInicioTab extends StatelessWidget {
  const _DoctorInicioTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CitaService>(
      builder: (context, service, _) {
        final hoy = DateTime.now();
        final hoyCitas = service.citas.where((c) {
          return c.fechaCita ==
              '${hoy.year}-'
              '${hoy.month.toString().padLeft(2, '0')}-'
              '${hoy.day.toString().padLeft(2, '0')}';
        }).toList();
        final atendidas =
            service.citas.where((c) => c.isAtendida).length;
        final pendientes =
            service.citas.where((c) => c.isProgramada).length;

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            final token = Provider.of<AuthService>(context,
                    listen: false)
                .token ??
                '';
            await service.cargarCitas(token);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats
              Row(
                children: [
                  _DoctorStatCard(
                    label: 'Citas hoy',
                    value: hoyCitas.length.toString(),
                    icon: Icons.today,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  _DoctorStatCard(
                    label: 'Atendidos',
                    value: atendidas.toString(),
                    icon: Icons.check_circle_outline,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 10),
                  _DoctorStatCard(
                    label: 'Pendientes',
                    value: pendientes.toString(),
                    icon: Icons.pending_outlined,
                    color: AppTheme.warning,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (hoyCitas.isNotEmpty) ...[
                const Text(
                  'Citas de hoy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray800,
                  ),
                ),
                const SizedBox(height: 10),
                ...hoyCitas
                    .map((c) => _DoctorCitaCard(cita: c)),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: const [
                        Icon(Icons.event_available,
                            size: 40, color: AppTheme.gray400),
                        SizedBox(height: 8),
                        Text(
                          'No hay citas programadas para hoy',
                          style: TextStyle(color: AppTheme.gray600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Tab Citas Doctor ─────────────────────────────────────────────────────────

class _DoctorCitasTab extends StatelessWidget {
  const _DoctorCitasTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        final token =
            Provider.of<AuthService>(context, listen: false).token ?? '';
        await Provider.of<CitaService>(context, listen: false)
            .cargarCitas(token);
      },
      child: Consumer<CitaService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (service.citas.isEmpty) {
            return const Center(
              child: Text('No hay citas registradas.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: service.citas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) =>
                _DoctorCitaCard(cita: service.citas[i]),
          );
        },
      ),
    );
  }
}

class _DoctorCitaCard extends StatelessWidget {
  final Cita cita;
  const _DoctorCitaCard({required this.cita});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cita.nombreAlumno.isEmpty
                            ? 'Paciente desconocido'
                            : cita.nombreAlumno,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cita.fechaFormateada}  ${cita.horaFormateada}',
                        style: const TextStyle(
                            color: AppTheme.gray600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _EstatusChipDoctor(estatus: cita.estatus),
              ],
            ),
            if (cita.motivo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                cita.motivo,
                style: const TextStyle(
                    color: AppTheme.gray600, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (cita.isProgramada) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelar(context, cita),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _marcarAtendida(context, cita),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Atendida'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _cancelar(BuildContext context, Cita cita) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: Text(
            'Cancelar cita de ${cita.nombreAlumno}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final token = Provider.of<AuthService>(context,
                      listen: false)
                  .token ??
                  '';
              await Provider.of<CitaService>(context, listen: false)
                  .cancelarCita(token, cita.id);
            },
            child: const Text('Si, cancelar'),
          ),
        ],
      ),
    );
  }

  void _marcarAtendida(BuildContext context, Cita cita) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Funcion de marcar atendida disponible desde la agenda web.'),
      ),
    );
  }
}

// ─── Tab Bitacoras Doctor ─────────────────────────────────────────────────────

class _DoctorBitacorasTab extends StatelessWidget {
  const _DoctorBitacorasTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        final token =
            Provider.of<AuthService>(context, listen: false).token ?? '';
        await Provider.of<BitacoraService>(context, listen: false)
            .cargarBitacoras(token);
      },
      child: Consumer<BitacoraService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (service.bitacoras.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No hay bitacoras registradas.')),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: service.bitacoras.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final b = service.bitacoras[i];
              return _DoctorBitacoraCard(bitacora: b);
            },
          );
        },
      ),
    );
  }
}

class _DoctorBitacoraCard extends StatelessWidget {
  final Bitacora bitacora;
  const _DoctorBitacoraCard({required this.bitacora});

  @override
  Widget build(BuildContext context) {
    final alumno = bitacora.alumno;
    final nombreAlumno = alumno != null
        ? '${alumno['nombre'] ?? ''} ${alumno['apellido'] ?? ''}'.trim()
        : 'Sin paciente';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline,
                    color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nombreAlumno,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
                Text(
                  bitacora.fechaFormateada,
                  style: const TextStyle(
                      color: AppTheme.gray500, fontSize: 12),
                ),
              ],
            ),
            if (bitacora.diagnostico != null) ...[
              const SizedBox(height: 6),
              Text(
                bitacora.diagnostico!,
                style:
                    const TextStyle(color: AppTheme.gray700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tab Pre-evaluaciones Doctor ──────────────────────────────────────────────

class _DoctorPreEvaluacionesTab extends StatelessWidget {
  const _DoctorPreEvaluacionesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<CitaService>(
      builder: (context, service, _) {
        final citasConPreeval = service.citas
            .where((c) => c.isProgramada)
            .toList();

        if (citasConPreeval.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 80),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.psychology,
                        size: 48, color: AppTheme.gray400),
                    SizedBox(height: 12),
                    Text(
                      'No hay pre-evaluaciones pendientes.',
                      style: TextStyle(color: AppTheme.gray600),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: citasConPreeval.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final cita = citasConPreeval[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primarySurface,
                  child: Icon(Icons.psychology,
                      color: AppTheme.primaryColor, size: 20),
                ),
                title: Text(
                  cita.nombreAlumno.isEmpty
                      ? 'Cita #${cita.id}'
                      : cita.nombreAlumno,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${cita.fechaFormateada} - ${cita.horaFormateada}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pendiente',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Widgets comunes ──────────────────────────────────────────────────────────

class _DoctorStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DoctorStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                    color: AppTheme.gray500, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstatusChipDoctor extends StatelessWidget {
  final String estatus;
  const _EstatusChipDoctor({required this.estatus});

  @override
  Widget build(BuildContext context) {
    Color color;
    String texto;
    switch (estatus) {
      case 'programada':
        color = AppTheme.primaryColor;
        texto = 'Programada';
        break;
      case 'atendida':
        color = AppTheme.success;
        texto = 'Atendida';
        break;
      case 'cancelada':
        color = AppTheme.error;
        texto = 'Cancelada';
        break;
      default:
        color = AppTheme.gray500;
        texto = estatus;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
