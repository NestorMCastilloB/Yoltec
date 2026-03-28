import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/models/bitacora.dart';
import 'package:yoltec_mobile/screens/pre_evaluacion_screen.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/bitacora_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/services/receta_service.dart';
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

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: hoy.add(const Duration(days: 1)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 60)),
      locale: const Locale('es', 'MX'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

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
            const SizedBox(height: 16),

            // Selector de fecha
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.gray300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _fechaSeleccionada == null
                          ? 'Seleccionar fecha'
                          : _formatFechaDisplay(_fechaSeleccionada!),
                      style: TextStyle(
                        color: _fechaSeleccionada == null
                            ? AppTheme.gray400
                            : AppTheme.gray900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
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
  final Map<String, dynamic> receta;
  const _RecetaCard({required this.receta});

  @override
  Widget build(BuildContext context) {
    final medicamentos =
        receta['medicamentos'] as List<dynamic>? ?? [];
    final fechaCreacion =
        receta['fecha_receta'] as String? ?? receta['created_at'] as String? ?? '';

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
                    'Receta ${receta['id'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _formatFecha(fechaCreacion),
                  style: const TextStyle(
                      color: AppTheme.gray600, fontSize: 12),
                ),
              ],
            ),
            if (receta['diagnostico'] != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                  label: 'Diagnostico',
                  value: receta['diagnostico'].toString()),
            ],
            if (medicamentos.isNotEmpty) ...[
              const Divider(height: 16),
              const Text(
                'Medicamentos:',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ...medicamentos.map((m) {
                if (m is Map) {
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
                            '${m['nombre'] ?? m['medicamento'] ?? 'Medicamento'}'
                            '${m['dosis'] != null ? ' - ${m['dosis']}' : ''}'
                            '${m['indicaciones'] != null ? '\n${m['indicaciones']}' : ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Text(m.toString(),
                    style: const TextStyle(fontSize: 13));
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFecha(String fecha) {
    if (fecha.length >= 10) {
      final parts = fecha.substring(0, 10).split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }
    return fecha;
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
