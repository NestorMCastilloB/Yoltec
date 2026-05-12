import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/screens/student/nueva_cita_form.dart';
import 'package:yoltec_mobile/screens/student/widgets/student_widgets.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class CitasTab extends StatelessWidget {
  const CitasTab({super.key});

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
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryColor));
            }
            if (service.citas.isEmpty) {
              return const Center(
                  child: Text('No tienes citas registradas.'));
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
        label:
            const Text('Nueva Cita', style: TextStyle(color: Colors.white)),
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
      builder: (_) => const NuevaCitaForm(),
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  const _CitaCard({required this.cita});

  @override
  Widget build(BuildContext context) {
    final color = _colorEstatus(cita.estatus);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.event, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(cita.fechaFormateada,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.gray900)),
                      const SizedBox(width: 8),
                      Text('- ${cita.horaFormateada}',
                          style:
                              const TextStyle(color: AppTheme.gray600)),
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
                EstatusChip(estatus: cita.estatus),
                if (cita.isProgramada) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _cancelar(context, cita),
                    child: const Text('Cancelar',
                        style: TextStyle(
                            color: AppTheme.error, fontSize: 12)),
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
        content: const Text('¿Seguro que deseas cancelar esta cita?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final token =
                  Provider.of<AuthService>(context, listen: false).token ??
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
