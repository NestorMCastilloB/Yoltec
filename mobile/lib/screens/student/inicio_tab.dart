import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/screens/pre_evaluacion_screen.dart';
import 'package:yoltec_mobile/screens/student/widgets/student_widgets.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class InicioTab extends StatelessWidget {
  final VoidCallback onNuevaCita;

  const InicioTab({super.key, required this.onNuevaCita});

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
              Row(
                children: [
                  StatCard(
                    label: 'Citas programadas',
                    value: programadas.length.toString(),
                    icon: Icons.event,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  StatCard(
                    label: 'Total de citas',
                    value: citaService.citas.length.toString(),
                    icon: Icons.history,
                    color: AppTheme.info,
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                  ? _buildSinCita()
                  : _buildProximaCitaCard(context, proxima),
              const SizedBox(height: 20),
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

  Widget _buildSinCita() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 40, color: AppTheme.gray400),
            SizedBox(height: 8),
            Text(
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
                      Text(cita.horaFormateada,
                          style: const TextStyle(color: AppTheme.gray600)),
                    ],
                  ),
                ),
                EstatusChip(estatus: cita.estatus),
              ],
            ),
            if (cita.motivo.isNotEmpty) ...[
              const Divider(height: 20),
              Text(cita.motivo,
                  style:
                      const TextStyle(color: AppTheme.gray700, fontSize: 14)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PreEvaluacionScreen(citaId: cita.id),
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
