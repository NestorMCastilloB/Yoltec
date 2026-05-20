import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/screens/pre_evaluacion_screen.dart';
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
                    ? const _CardSinCita()
                    : _CardProximaCita(cita: proxima),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Citas este mes',
                        value: '$citasMes',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStat(
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
                    _QuickAccess(
                      icon: Icons.calendar_today_outlined,
                      label: 'Agendar cita',
                      bg: const Color(0xFFF0FAF4),
                      bgDark: AppTheme.primaryColor.withValues(alpha: 0.12),
                      iconColor: AppTheme.primaryColor,
                      onTap: onNuevaCita,
                    ),
                    _QuickAccess(
                      icon: Icons.psychology_outlined,
                      label: 'Pre-evaluación IA',
                      bg: const Color(0xFFF0F4FF),
                      bgDark: AppTheme.iaColor.withValues(alpha: 0.12),
                      iconColor: const Color(0xFF3850C2),
                      onTap: () => _abrirIa(context, proxima),
                    ),
                    _QuickAccess(
                      icon: Icons.medication_outlined,
                      label: 'Mis recetas',
                      bg: const Color(0xFFFFFBF0),
                      bgDark: AppTheme.warning.withValues(alpha: 0.14),
                      iconColor: const Color(0xFFA86F00),
                      onTap: onIrRecetas,
                    ),
                    _QuickAccess(
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

class _CardProximaCita extends StatelessWidget {
  final Cita cita;
  const _CardProximaCita({required this.cita});

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
                          builder: (_) =>
                              PreEvaluacionScreen(citaId: cita.id),
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

class _CardSinCita extends StatelessWidget {
  const _CardSinCita();

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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: textMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: textMain,
              height: 1,
            ),
          ),
        ],
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

class _QuickAccess extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color bgDark;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickAccess({
    required this.icon,
    required this.label,
    required this.bg,
    required this.bgDark,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? bgDark : bg;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 30),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textMain,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
