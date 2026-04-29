import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/models/bitacora.dart';
import 'package:yoltec_mobile/models/receta.dart';
import 'package:yoltec_mobile/screens/pre_evaluacion_screen.dart';
import 'package:yoltec_mobile/services/api_service.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/bitacora_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/services/receta_service.dart';
import 'package:yoltec_mobile/services/biometric_service.dart';
import 'package:yoltec_mobile/services/theme_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

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
    final token =
        Provider.of<AuthService>(context, listen: false).token ?? '';
    await Future.wait([
      Provider.of<CitaService>(context, listen: false).cargarCitas(token),
      Provider.of<BitacoraService>(context, listen: false)
          .cargarBitacoras(token),
      Provider.of<RecetaService>(context, listen: false)
          .cargarRecetas(token),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _InicioTab(onNuevaCita: () => setState(() => _tabIndex = 1)),
      const _CitasTab(),
      const _BitacoraTab(),
      const _RecetasTab(),
      const _PerfilTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthService>(
          builder: (_, auth, __) =>
              Text('Hola, ${auth.currentUser?.nombre ?? ''}'),
        ),
        actions: [
          Consumer<ThemeService>(
            builder: (_, theme, __) => IconButton(
              icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: theme.isDark ? 'Modo claro' : 'Modo oscuro',
              onPressed: () => theme.toggle(),
            ),
          ),
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
          Consumer<CitaService>(
            builder: (_, citas, __) => Consumer<BitacoraService>(
              builder: (_, bitacora, __) => Consumer<RecetaService>(
                builder: (_, recetas, __) {
                  final offline = citas.isOffline || bitacora.isOffline || recetas.isOffline;
                  if (!offline) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    color: AppTheme.warning,
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sin conexion — mostrando datos guardados',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(child: tabs[_tabIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Citas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: 'Bitacora'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Recetas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
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
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Inicio ──────────────────────────────────────────────────────────────

class _InicioTab extends StatelessWidget {
  final VoidCallback onNuevaCita;

  const _InicioTab({required this.onNuevaCita});

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
        builder: (context, citaService, _) {
          final proxima = citaService.proximaCita;
          final programadas = citaService.citasProgramadas;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resumen
              Row(
                children: [
                  _StatCard(
                    label: 'Citas programadas',
                    value: programadas.length.toString(),
                    icon: Icons.event,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Total de citas',
                    value: citaService.citas.length.toString(),
                    icon: Icons.history,
                    color: AppTheme.info,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Proxima cita
              const Text(
                'Proxima cita',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray800,
                ),
              ),
              const SizedBox(height: 10),
              proxima == null
                  ? _buildSinCita(context)
                  : _buildProximaCitaCard(context, proxima),

              const SizedBox(height: 20),

              // Boton nueva cita
              OutlinedButton.icon(
                onPressed: onNuevaCita,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agendar nueva cita'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSinCita(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.event_available,
                size: 40, color: AppTheme.gray400),
            const SizedBox(height: 8),
            const Text(
              'Sin citas proximas',
              style: TextStyle(
                  color: AppTheme.gray600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProximaCitaCard(BuildContext context, Cita cita) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event,
                      color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cita.fechaFormateada,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.gray900,
                        ),
                      ),
                      Text(
                        cita.horaFormateada,
                        style: const TextStyle(color: AppTheme.gray600),
                      ),
                    ],
                  ),
                ),
                _EstatusChip(estatus: cita.estatus),
              ],
            ),
            if (cita.motivo.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                cita.motivo,
                style: const TextStyle(
                    color: AppTheme.gray700, fontSize: 14),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PreEvaluacionScreen(citaId: cita.id),
                    ),
                  );
                },
                icon: const Icon(Icons.psychology, size: 18),
                label: const Text('Pre-evaluacion IA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Citas ───────────────────────────────────────────────────────────────

class _CitasTab extends StatelessWidget {
  const _CitasTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
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
                child: Text('No tienes citas registradas.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: service.citas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _CitaCard(cita: service.citas[i]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormNuevaCita(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Cita',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _mostrarFormNuevaCita(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _NuevaCitaForm(),
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  const _CitaCard({required this.cita});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _colorEstatus(cita.estatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.event,
                  color: _colorEstatus(cita.estatus), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        cita.fechaFormateada,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray900),
                      ),
                      const SizedBox(width: 8),
                      Text('- ${cita.horaFormateada}',
                          style: const TextStyle(color: AppTheme.gray600)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cita.motivo.isNotEmpty ? cita.motivo : 'Sin motivo',
                    style: const TextStyle(
                        color: AppTheme.gray600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _EstatusChip(estatus: cita.estatus),
                if (cita.isProgramada) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _cancelar(context, cita),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                          color: AppTheme.error, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorEstatus(String estatus) {
    switch (estatus) {
      case 'programada':
        return AppTheme.primaryColor;
      case 'atendida':
        return AppTheme.success;
      case 'cancelada':
        return AppTheme.error;
      default:
        return AppTheme.gray500;
    }
  }

  void _cancelar(BuildContext context, Cita cita) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cita'),
        content:
            const Text('?Seguro que deseas cancelar esta cita?'),
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
}

// ─── Formulario Nueva Cita ────────────────────────────────────────────────────

class _NuevaCitaForm extends StatefulWidget {
  const _NuevaCitaForm();

  @override
  State<_NuevaCitaForm> createState() => _NuevaCitaFormState();
}

class _NuevaCitaFormState extends State<_NuevaCitaForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fechaSeleccionada;
  String? _horaSeleccionada;
  final _motivoCtrl = TextEditingController();
  bool _guardando = false;

  // Slots de 08:00 a 17:00 cada 15 min
  static final List<String> _horasDisponibles = () {
    final lista = <String>[];
    for (int h = 8; h < 17; h++) {
      for (int m = 0; m < 60; m += 15) {
        lista.add(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return lista;
  }();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  String _formatFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _formatFechaDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha')),
      );
      return;
    }
    if (_horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una hora')),
      );
      return;
    }

    setState(() => _guardando = true);

    final token =
        Provider.of<AuthService>(context, listen: false).token ?? '';
    final cita = await Provider.of<CitaService>(context, listen: false)
        .crearCita(
      token,
      fechaCita: _formatFecha(_fechaSeleccionada!),
      horaCita: _horaSeleccionada!,
      motivo: _motivoCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (cita != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita agendada correctamente'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } else {
      final err = Provider.of<CitaService>(context, listen: false).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Error al agendar la cita'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Nueva Cita',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Calendario de disponibilidad
              _CalendarioDisponibilidad(
                selectedDate: _fechaSeleccionada,
                onDateSelected: (d) => setState(() => _fechaSeleccionada = d),
              ),
              if (_fechaSeleccionada != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Fecha: ${_formatFechaDisplay(_fechaSeleccionada!)}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

            // Selector de hora
            DropdownButtonFormField<String>(
              initialValue: _horaSeleccionada,
              hint: const Text('Seleccionar hora'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.access_time_outlined),
                labelText: 'Hora',
              ),
              items: _horasDisponibles
                  .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                  .toList(),
              onChanged: (v) => setState(() => _horaSeleccionada = v),
            ),
            const SizedBox(height: 14),

            // Motivo
            TextFormField(
              controller: _motivoCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notes_outlined),
                labelText: 'Motivo de consulta',
                hintText: 'Describe brevemente tu motivo...',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Ingresa el motivo de la cita';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Agendar Cita'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
  }
}

// ─── Tab Bitacora ─────────────────────────────────────────────────────────────

class _BitacoraTab extends StatelessWidget {
  const _BitacoraTab();

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
                Center(
                    child: Text('No tienes registros en tu bitacora.')),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: service.bitacoras.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _BitacoraCard(bitacora: service.bitacoras[i]),
          );
        },
      ),
    );
  }
}

class _BitacoraCard extends StatelessWidget {
  final Bitacora bitacora;
  const _BitacoraCard({required this.bitacora});

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
                const Icon(Icons.medical_services,
                    color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  bitacora.fechaFormateada,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                const Spacer(),
                Text(
                  'Dr. ${bitacora.nombreDoctor}',
                  style: const TextStyle(
                      color: AppTheme.gray600, fontSize: 12),
                ),
              ],
            ),
            if (bitacora.diagnostico != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                  label: 'Diagnostico', value: bitacora.diagnostico!),
            ],
            if (bitacora.tratamiento != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                  label: 'Tratamiento', value: bitacora.tratamiento!),
            ],
            if (bitacora.observaciones != null) ...[
              const SizedBox(height: 4),
              _InfoRow(
                  label: 'Observaciones',
                  value: bitacora.observaciones!),
            ],
            // Signos vitales
            if (bitacora.peso != null ||
                bitacora.presionArterial != null ||
                bitacora.temperatura != null) ...[
              const Divider(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (bitacora.peso != null)
                    _VitalChip(
                        label: 'Peso', value: '${bitacora.peso} kg'),
                  if (bitacora.presionArterial != null)
                    _VitalChip(
                        label: 'P.A.',
                        value: bitacora.presionArterial!),
                  if (bitacora.temperatura != null)
                    _VitalChip(
                        label: 'Temp.',
                        value: '${bitacora.temperatura}deg.C'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Tab Recetas ──────────────────────────────────────────────────────────────

class _RecetasTab extends StatelessWidget {
  const _RecetasTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        final token =
            Provider.of<AuthService>(context, listen: false).token ?? '';
        await Provider.of<RecetaService>(context, listen: false)
            .cargarRecetas(token);
      },
      child: Consumer<RecetaService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (service.recetas.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No tienes recetas registradas.')),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: service.recetas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _RecetaCard(receta: service.recetas[i]),
          );
        },
      ),
    );
  }
}

class _RecetaCard extends StatelessWidget {
  final Receta receta;
  const _RecetaCard({required this.receta});

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
                const Icon(Icons.receipt_long,
                    color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Receta ${receta.id}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  receta.fechaFormateada,
                  style: const TextStyle(
                      color: AppTheme.gray600, fontSize: 12),
                ),
              ],
            ),
            if (receta.indicaciones.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                  label: 'Indicaciones',
                  value: receta.indicaciones),
            ],
            if (receta.medicamentos.isNotEmpty) ...[
              const Divider(height: 16),
              const Text(
                'Medicamentos:',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ...receta.medicamentos.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.medication_outlined,
                          size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${m.nombre}'
                          '${m.dosis.isNotEmpty ? ' - ${m.dosis}' : ''}'
                          '${m.frecuencia.isNotEmpty ? '\n${m.frecuencia}' : ''}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Widgets comunes ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                    color: AppTheme.gray600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstatusChip extends StatelessWidget {
  final String estatus;
  const _EstatusChip({required this.estatus});

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
      case 'no_asistio':
        color = AppTheme.warning;
        texto = 'No asistio';
        break;
      default:
        color = AppTheme.gray500;
        texto = estatus;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppTheme.gray700),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppTheme.gray800),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  const _VitalChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── Tab Perfil ───────────────────────────────────────────────────────────────

class _PerfilTab extends StatefulWidget {
  const _PerfilTab();

  @override
  State<_PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<_PerfilTab> {
  bool _cargando = true;
  String? _error;

  // Datos personales
  String _nombre = '';
  String _apellido = '';
  String _email = '';
  String _numeroControl = '';
  String _telefono = '';
  String? _fotoPerfil;

  // Info médica
  String _tipoSangre = '';
  String _alergias = '';
  String _enfermedadesCronicas = '';

  // Biometría
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _cargarPerfil();
      await _cargarEstadoBiometrico();
    });
  }

  Future<void> _cargarEstadoBiometrico() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometrico(bool valor) async {
    if (valor) {
      // Al activar, pedir autenticación primero para confirmar
      final autenticado = await BiometricService.authenticate();
      if (!autenticado || !mounted) return;
    }
    await BiometricService.setEnabled(valor);
    if (mounted) setState(() => _biometricEnabled = valor);
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      final data = await ApiService.get('/perfil-medico', token: token);
      final perfil = data['data'] ?? data;
      if (mounted) {
        setState(() {
          _nombre = (perfil['nombre'] ?? '').toString();
          _apellido = (perfil['apellido'] ?? '').toString();
          _email = (perfil['email'] ?? '').toString();
          _numeroControl =
              (perfil['numero_control'] ?? '').toString();
          _telefono = (perfil['telefono'] ?? '').toString();
          _fotoPerfil = perfil['foto_perfil']?.toString();
          _tipoSangre = (perfil['tipo_sangre'] ?? '').toString();
          _alergias = (perfil['alergias'] ?? '').toString();
          _enfermedadesCronicas =
              (perfil['enfermedades_cronicas'] ?? '').toString();
          _cargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() {
        _error = e.message;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Error al cargar perfil';
        _cargando = false;
      });
    }
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null) return;

    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      final result = await ApiService.postMultipart(
        '/perfil/foto',
        File(picked.path),
        'foto',
        token: token,
      );
      final nuevaFoto =
          (result['data'] ?? result)['foto_perfil']?.toString();
      if (mounted) {
        setState(() => _fotoPerfil = nuevaFoto);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto actualizada'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _mostrarEditarInfoMedica() {
    showDialog(
      context: context,
      builder: (ctx) => _EditarInfoMedicaDialog(
        tipoSangre: _tipoSangre,
        alergias: _alergias,
        enfermedadesCronicas: _enfermedadesCronicas,
        onGuardado: (ts, al, ec) {
          setState(() {
            _tipoSangre = ts;
            _alergias = al;
            _enfermedadesCronicas = ec;
          });
        },
      ),
    );
  }

  void _mostrarCambiarPassword() {
    showDialog(
      context: context,
      builder: (ctx) => const _CambiarPasswordDialog(),
    );
  }

  String get _iniciales {
    final n = _nombre.trim();
    final a = _apellido.trim();
    if (n.isEmpty && a.isEmpty) return '?';
    final pi = n.isNotEmpty ? n[0].toUpperCase() : '';
    final si = a.isNotEmpty ? a[0].toUpperCase() : '';
    return '$pi$si';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.gray700)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarPerfil,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _cargarPerfil,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar ──────────────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppTheme.primarySurface,
                  backgroundImage: (_fotoPerfil != null &&
                          _fotoPerfil!.isNotEmpty)
                      ? NetworkImage(_fotoPerfil!)
                      : null,
                  child: (_fotoPerfil == null || _fotoPerfil!.isEmpty)
                      ? Text(
                          _iniciales,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _cambiarFoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              '$_nombre $_apellido'.trim(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
          ),
          if (_email.isNotEmpty)
            Center(
              child: Text(
                _email,
                style: const TextStyle(
                    color: AppTheme.gray600, fontSize: 13),
              ),
            ),
          const SizedBox(height: 20),

          // ── Datos personales ─────────────────────────────────────────
          _SeccionCard(
            titulo: 'Datos Personales',
            icono: Icons.badge_outlined,
            children: [
              _CampoInfo(
                  label: 'Numero de control', valor: _numeroControl),
              _CampoInfo(label: 'Nombre', valor: '$_nombre $_apellido'.trim()),
              _CampoInfo(label: 'Email', valor: _email),
              if (_telefono.isNotEmpty)
                _CampoInfo(label: 'Telefono', valor: _telefono),
            ],
          ),
          const SizedBox(height: 14),

          // ── Informacion medica ───────────────────────────────────────
          _SeccionCard(
            titulo: 'Información Médica',
            icono: Icons.medical_information_outlined,
            accion: TextButton.icon(
              onPressed: _mostrarEditarInfoMedica,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar',
                  style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
              ),
            ),
            children: [
              _CampoInfo(
                label: 'Tipo de sangre',
                valor: _tipoSangre.isEmpty ? 'No registrado' : _tipoSangre,
              ),
              _CampoInfo(
                label: 'Alergias',
                valor: _alergias.isEmpty ? 'Ninguna' : _alergias,
              ),
              _CampoInfo(
                label: 'Enfermedades cronicas',
                valor: _enfermedadesCronicas.isEmpty
                    ? 'Ninguna'
                    : _enfermedadesCronicas,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Seguridad ────────────────────────────────────────────────
          _SeccionCard(
            titulo: 'Seguridad',
            icono: Icons.lock_outline,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _mostrarCambiarPassword,
                  icon: const Icon(Icons.key_outlined, size: 18),
                  label: const Text('Cambiar contraseña'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  value: _biometricEnabled,
                  onChanged: _toggleBiometrico,
                  title: const Text(
                    'Acceso con huella dactilar',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    _biometricEnabled
                        ? 'Activo — se pedira huella al abrir la app'
                        : 'Inactivo',
                    style: const TextStyle(fontSize: 12),
                  ),
                  secondary: const Icon(Icons.fingerprint,
                      color: AppTheme.primaryColor),
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Diálogo: Editar info médica ──────────────────────────────────────────────

class _EditarInfoMedicaDialog extends StatefulWidget {
  final String tipoSangre;
  final String alergias;
  final String enfermedadesCronicas;
  final void Function(String, String, String) onGuardado;

  const _EditarInfoMedicaDialog({
    required this.tipoSangre,
    required this.alergias,
    required this.enfermedadesCronicas,
    required this.onGuardado,
  });

  @override
  State<_EditarInfoMedicaDialog> createState() =>
      _EditarInfoMedicaDialogState();
}

class _EditarInfoMedicaDialogState
    extends State<_EditarInfoMedicaDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _tipoSangre;
  late final TextEditingController _alergiasCtrl;
  late final TextEditingController _enfermedadesCtrl;
  bool _guardando = false;

  static const List<String> _tiposSangre = [
    '', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    _tipoSangre = widget.tipoSangre;
    _alergiasCtrl = TextEditingController(text: widget.alergias);
    _enfermedadesCtrl =
        TextEditingController(text: widget.enfermedadesCronicas);
  }

  @override
  void dispose() {
    _alergiasCtrl.dispose();
    _enfermedadesCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      await ApiService.put(
        '/perfil-medico',
        {
          'tipo_sangre': _tipoSangre,
          'alergias': _alergiasCtrl.text.trim(),
          'enfermedades_cronicas': _enfermedadesCtrl.text.trim(),
        },
        token: token,
      );
      if (!mounted) return;
      widget.onGuardado(
        _tipoSangre,
        _alergiasCtrl.text.trim(),
        _enfermedadesCtrl.text.trim(),
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información médica actualizada'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.medical_information_outlined,
              color: AppTheme.primaryColor, size: 22),
          SizedBox(width: 8),
          Text('Info. Medica',
              style: TextStyle(fontSize: 17)),
        ],
      ),
      contentPadding:
          const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tipo de sangre
              DropdownButtonFormField<String>(
                value: _tiposSangre.contains(_tipoSangre)
                    ? _tipoSangre
                    : '',
                decoration: const InputDecoration(
                  labelText: 'Tipo de sangre',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
                items: _tiposSangre
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.isEmpty ? 'No especificado' : t),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _tipoSangre = v ?? ''),
              ),
              const SizedBox(height: 14),
              // Alergias
              TextFormField(
                controller: _alergiasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alergias',
                  hintText: 'Ej: Penicilina, polvo...',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
              const SizedBox(height: 14),
              // Enfermedades crónicas
              TextFormField(
                controller: _enfermedadesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Enfermedades cronicas',
                  hintText: 'Ej: Diabetes, hipertension...',
                  prefixIcon: Icon(Icons.monitor_heart_outlined),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

// ─── Diálogo: Cambiar contraseña ──────────────────────────────────────────────

class _CambiarPasswordDialog extends StatefulWidget {
  const _CambiarPasswordDialog();

  @override
  State<_CambiarPasswordDialog> createState() =>
      _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState
    extends State<_CambiarPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevoCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _guardando = false;
  bool _verActual = false;
  bool _verNuevo = false;
  bool _verConfirm = false;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevoCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      await ApiService.post(
        '/perfil/cambiar-password',
        {
          'password_actual': _actualCtrl.text,
          'password_nuevo': _nuevoCtrl.text,
          'password_nuevo_confirmation': _confirmCtrl.text,
        },
        token: token,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_outline,
              color: AppTheme.primaryColor, size: 22),
          SizedBox(width: 8),
          Text('Cambiar contraseña',
              style: TextStyle(fontSize: 17)),
        ],
      ),
      contentPadding:
          const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contraseña actual
              TextFormField(
                controller: _actualCtrl,
                obscureText: !_verActual,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  prefixIcon:
                      const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_verActual
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _verActual = !_verActual),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Ingresa tu contraseña actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Nueva contraseña
              TextFormField(
                controller: _nuevoCtrl,
                obscureText: !_verNuevo,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon:
                      const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_verNuevo
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _verNuevo = !_verNuevo),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Minimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Confirmar nueva contraseña
              TextFormField(
                controller: _confirmCtrl,
                obscureText: !_verConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_verConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _verConfirm = !_verConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != _nuevoCtrl.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

// ─── Widgets auxiliares para Perfil ──────────────────────────────────────────

class _SeccionCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;
  final Widget? accion;

  const _SeccionCard({
    required this.titulo,
    required this.icono,
    required this.children,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
                if (accion != null) ...[
                  const Spacer(),
                  accion!,
                ],
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CampoInfo extends StatelessWidget {
  final String label;
  final String valor;

  const _CampoInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valor.isEmpty ? '—' : valor,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calendario de Disponibilidad ────────────────────────────────────────────

class _CalendarioDisponibilidad extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarioDisponibilidad({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<_CalendarioDisponibilidad> createState() =>
      _CalendarioDisponibilidadState();
}

class _CalendarioDisponibilidadState
    extends State<_CalendarioDisponibilidad> {
  late DateTime _mes;
  Map<String, List<String>> _slotsTomados = {};
  Map<String, Map<String, dynamic>> _diasEspeciales = {};
  bool _cargando = false;

  // 8:00 a 16:45 cada 15 min = 36 slots totales
  static const int _totalSlots = 36;

  static const List<String> _nombresMes = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _mes = DateTime(hoy.year, hoy.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarDisponibilidad());
  }

  Future<void> _cargarDisponibilidad() async {
    setState(() => _cargando = true);
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      final data = await Provider.of<CitaService>(context, listen: false)
          .obtenerDisponibilidad(token, _mes.month, _mes.year);

      final days = data['days'] as List<dynamic>? ?? [];
      final slots = <String, List<String>>{};
      final especiales = <String, Map<String, dynamic>>{};

      for (final day in days) {
        final d = day as Map<String, dynamic>;
        final date = d['date'] as String;
        slots[date] = List<String>.from(d['taken_slots'] as List? ?? []);
        if (d['special'] != null) {
          especiales[date] = d['special'] as Map<String, dynamic>;
        }
      }

      if (mounted) {
        setState(() {
          _slotsTomados = slots;
          _diasEspeciales = especiales;
        });
      }
    } catch (_) {
      // Sin disponibilidad: todo verde por defecto
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _cambiarMes(int delta) {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + delta, 1);
      _slotsTomados = {};
      _diasEspeciales = {};
    });
    _cargarDisponibilidad();
  }

  String _dateKey(int year, int month, int day) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  bool _esSeleccionable(DateTime date) {
    final hoy = DateTime.now();
    final today = DateTime(hoy.year, hoy.month, hoy.day);
    final d = DateTime(date.year, date.month, date.day);

    if (date.month != _mes.month) return false;
    if (d.isBefore(today)) return false;
    if (date.weekday == 7) return false; // domingo

    final key = _dateKey(date.year, date.month, date.day);
    final especial = _diasEspeciales[key];
    if (especial != null && especial['status'] == 'full') return false;

    final tomados = _slotsTomados[key]?.length ?? 0;
    return tomados < _totalSlots;
  }

  Color _colorDia(DateTime date) {
    final hoy = DateTime.now();
    final today = DateTime(hoy.year, hoy.month, hoy.day);
    final d = DateTime(date.year, date.month, date.day);

    if (date.month != _mes.month || d.isBefore(today) || date.weekday == 7) {
      return AppTheme.gray300;
    }

    final key = _dateKey(date.year, date.month, date.day);

    if (_diasEspeciales.containsKey(key)) return AppTheme.error;

    final tomados = _slotsTomados[key]?.length ?? 0;
    if (tomados == 0) return AppTheme.primaryColor;
    if (tomados >= _totalSlots) return AppTheme.error;
    return AppTheme.warning;
  }

  @override
  Widget build(BuildContext context) {
    final diasEnMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    // Primer día de la semana: 1=Lun...7=Dom. Para Dom-Sáb: offset = weekday % 7
    final primerDiaSemana = DateTime(_mes.year, _mes.month, 1).weekday % 7;
    final totalCeldas = primerDiaSemana + diasEnMes;
    final filas = (totalCeldas / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navegación mes
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: () => _cambiarMes(-1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Expanded(
              child: Text(
                '${_nombresMes[_mes.month - 1]} ${_mes.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.gray900),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: () => _cambiarMes(1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Cabecera días
        Row(
          children: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']
              .map((d) => Expanded(
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.gray500,
                            fontWeight: FontWeight.w600)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Grid de días
        if (_cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primaryColor)),
            ),
          )
        else
          ...List.generate(filas, (fila) {
            return Row(
              children: List.generate(7, (col) {
                final idx = fila * 7 + col;
                final diaNum = idx - primerDiaSemana + 1;

                if (diaNum < 1 || diaNum > diasEnMes) {
                  return const Expanded(child: SizedBox(height: 40));
                }

                final date = DateTime(_mes.year, _mes.month, diaNum);
                final seleccionable = _esSeleccionable(date);
                final color = _colorDia(date);
                final isSelected = widget.selectedDate != null &&
                    widget.selectedDate!.year == date.year &&
                    widget.selectedDate!.month == date.month &&
                    widget.selectedDate!.day == date.day;

                return Expanded(
                  child: GestureDetector(
                    onTap: seleccionable
                        ? () => widget.onDateSelected(date)
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: color.withValues(
                              alpha: isSelected ? 1.0 : 0.5),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$diaNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : seleccionable
                                    ? color
                                    : AppTheme.gray400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        const SizedBox(height: 8),
        // Leyenda
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LeyendaItem(color: AppTheme.primaryColor, label: 'Disponible'),
            SizedBox(width: 12),
            _LeyendaItem(color: AppTheme.warning, label: 'Pocos slots'),
            SizedBox(width: 12),
            _LeyendaItem(color: AppTheme.error, label: 'Lleno'),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LeyendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppTheme.gray600)),
      ],
    );
  }
}
