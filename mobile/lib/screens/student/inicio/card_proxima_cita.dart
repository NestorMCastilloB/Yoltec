import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/screens/pre_evaluacion_screen.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class CardProximaCita extends StatelessWidget {
  final Cita cita;
  const CardProximaCita({super.key, required this.cita});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;
    final divider = isDark ? AppTheme.borderDark : AppTheme.borderSoft;

    final fechaTitulo = _fechaCard(cita.fechaCita);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppTheme.primaryColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'CONFIRMADA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              fechaTitulo,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
            Text(
              '${cita.horaFormateada} hrs',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
                letterSpacing: -0.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (cita.motivo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  cita.motivo,
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: divider),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreEvaluacionScreen(citaId: cita.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.psychology_outlined, size: 18),
                    label: const Text('Pre-evaluación IA'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _confirmarCancelar(context, cita),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fechaCard(String fechaIso) {
    final partes = fechaIso.split('-');
    if (partes.length != 3) return fechaIso;
    try {
      final fecha = DateTime(
        int.parse(partes[0]),
        int.parse(partes[1]),
        int.parse(partes[2]),
      );
      final formato = DateFormat('EEEE, d \'de\' MMMM', 'es_MX').format(fecha);
      return formato[0].toUpperCase() + formato.substring(1);
    } catch (_) {
      return fechaIso;
    }
  }

  void _confirmarCancelar(BuildContext context, Cita cita) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Estás seguro de cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final token =
                  Provider.of<AuthService>(context, listen: false).token ?? '';
              final ok = await Provider.of<CitaService>(context, listen: false)
                  .cancelarCita(token, cita.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Cita cancelada' : 'No se pudo cancelar'),
                  ),
                );
              }
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }
}

class CardSinCita extends StatelessWidget {
  const CardSinCita({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 40, color: textMuted),
            const SizedBox(height: 8),
            Text(
              'Sin citas próximas',
              style: TextStyle(
                color: textMain,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Agenda una desde el botón de abajo',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
