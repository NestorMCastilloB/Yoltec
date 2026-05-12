import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/bitacora.dart';
import 'package:yoltec_mobile/screens/student/widgets/student_widgets.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/bitacora_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class BitacoraTab extends StatelessWidget {
  const BitacoraTab({super.key});

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
                child: CircularProgressIndicator(
                    color: AppTheme.primaryColor));
          }
          if (service.bitacoras.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No tienes registros en tu bitacora.')),
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
                      fontWeight: FontWeight.w600, color: AppTheme.gray900),
                ),
                const Spacer(),
                Text('Dr. ${bitacora.nombreDoctor}',
                    style: const TextStyle(
                        color: AppTheme.gray600, fontSize: 12)),
              ],
            ),
            if (bitacora.diagnostico != null) ...[
              const SizedBox(height: 8),
              InfoRow(label: 'Diagnostico', value: bitacora.diagnostico!),
            ],
            if (bitacora.tratamiento != null) ...[
              const SizedBox(height: 4),
              InfoRow(label: 'Tratamiento', value: bitacora.tratamiento!),
            ],
            if (bitacora.observaciones != null) ...[
              const SizedBox(height: 4),
              InfoRow(
                  label: 'Observaciones', value: bitacora.observaciones!),
            ],
            if (bitacora.peso != null ||
                bitacora.presionArterial != null ||
                bitacora.temperatura != null) ...[
              const Divider(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (bitacora.peso != null)
                    VitalChip(
                        label: 'Peso', value: '${bitacora.peso} kg'),
                  if (bitacora.presionArterial != null)
                    VitalChip(
                        label: 'P.A.', value: bitacora.presionArterial!),
                  if (bitacora.temperatura != null)
                    VitalChip(
                        label: 'Temp.',
                        value: '${bitacora.temperatura}°C'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
