import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/screens/pre_evaluacion_screen.dart';
import 'package:yoltec_mobile/screens/student/inicio/card_proxima_cita.dart';
import 'package:yoltec_mobile/screens/student/inicio/inicio_widgets.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class InicioTab extends StatelessWidget {
  final VoidCallback onNuevaCita;
  final VoidCallback onIrRecetas;
  final VoidCallback onIrPerfil;

  const InicioTab({
    super.key,
    required this.onNuevaCita,
    required this.onIrRecetas,
    required this.onIrPerfil,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgDark : AppTheme.bg;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return Container(
      color: bg,
      child: RefreshIndicator(
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
            final atendidas =
                citaService.citas.where((c) => c.isAtendida).toList();
            final mesActual = DateTime.now().month;
            final yearActual = DateTime.now().year;
            final citasMes = citaService.citas.where((c) {
              final partes = c.fechaCita.split('-');
              if (partes.length != 3) return false;
              return int.tryParse(partes[1]) == mesActual &&
                  int.tryParse(partes[0]) == yearActual;
            }).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _SubTituloFecha(textMuted: textMuted),
                const SizedBox(height: 16),
                proxima == null
                    ? const CardSinCita()
                    : CardProximaCita(cita: proxima),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: MiniStat(
                        label: 'Citas este mes',
                        value: '$citasMes',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MiniStat(
                        label: 'Última visita',
                        value: _ultimaVisitaTexto(atendidas),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SeccionTitulo(text: 'ACCESO RÁPIDO', color: textMuted),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    QuickAccess(
                      icon: Icons.calendar_today_outlined,
                      label: 'Agendar cita',
                      bg: const Color(0xFFF0FAF4),
                      bgDark: AppTheme.primaryColor.withValues(alpha: 0.12),
                      iconColor: AppTheme.primaryColor,
                      onTap: onNuevaCita,
                    ),
                    QuickAccess(
                      icon: Icons.psychology_outlined,
                      label: 'Pre-evaluación IA',
                      bg: const Color(0xFFF0F4FF),
                      bgDark: AppTheme.iaColor.withValues(alpha: 0.12),
                      iconColor: const Color(0xFF3850C2),
                      onTap: () => _abrirIa(context, proxima),
                    ),
                    QuickAccess(
                      icon: Icons.medication_outlined,
                      label: 'Mis recetas',
                      bg: const Color(0xFFFFFBF0),
                      bgDark: AppTheme.warning.withValues(alpha: 0.14),
                      iconColor: const Color(0xFFA86F00),
                      onTap: onIrRecetas,
                    ),
                    QuickAccess(
                      icon: Icons.person_outline,
                      label: 'Mi perfil',
                      bg: const Color(0xFFF3F3F4),
                      bgDark: Colors.white.withValues(alpha: 0.06),
                      iconColor: const Color(0xFF3B4252),
                      onTap: onIrPerfil,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _ultimaVisitaTexto(List<Cita> atendidas) {
    if (atendidas.isEmpty) return '—';
    atendidas.sort((a, b) => b.fechaCita.compareTo(a.fechaCita));
    final partes = atendidas.first.fechaCita.split('-');
    if (partes.length != 3) return '—';
    final dia = int.tryParse(partes[2]) ?? 1;
    final mes = int.tryParse(partes[1]) ?? 1;
    final meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '$dia ${meses[mes - 1]}';
  }

  void _abrirIa(BuildContext context, Cita? proxima) {
    if (proxima == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agenda una cita para iniciar tu pre-evaluación.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreEvaluacionScreen(citaId: proxima.id),
      ),
    );
  }
}

class _SubTituloFecha extends StatelessWidget {
  final Color textMuted;
  const _SubTituloFecha({required this.textMuted});

  @override
  Widget build(BuildContext context) {
    final hoy = DateFormat('EEEE, d \'de\' MMMM y', 'es_MX').format(DateTime.now());
    final capitalizado = hoy[0].toUpperCase() + hoy.substring(1);
    return Text(
      capitalizado,
      style: TextStyle(
        fontSize: 13,
        color: textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String text;
  final Color color;

  const _SeccionTitulo({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.6,
      ),
    );
  }
}
