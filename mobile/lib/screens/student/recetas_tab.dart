import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/receta.dart';
import 'package:yoltec_mobile/screens/student/widgets/student_widgets.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/receta_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class RecetasTab extends StatelessWidget {
  const RecetasTab({super.key});

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
                child: CircularProgressIndicator(
                    color: AppTheme.primaryColor));
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
                  child: Text('Receta ${receta.id}',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(receta.fechaFormateada,
                    style: const TextStyle(
                        color: AppTheme.gray600, fontSize: 12)),
              ],
            ),
            if (receta.indicaciones.isNotEmpty) ...[
              const SizedBox(height: 8),
              InfoRow(label: 'Indicaciones', value: receta.indicaciones),
            ],
            if (receta.medicamentos.isNotEmpty) ...[
              const Divider(height: 16),
              const Text('Medicamentos:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              ...receta.medicamentos.map((m) => Padding(
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
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
