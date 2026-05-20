import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/screens/student/nueva_cita_form.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class CitasTab extends StatelessWidget {
  const CitasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgDark : AppTheme.bg;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bg,
        body: Consumer<CitaService>(
          builder: (context, service, _) {
            if (service.isLoading && service.citas.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              );
            }

            final proximas = service.citas
                .where((c) => c.isProgramada)
                .toList()
              ..sort((a, b) =>
                  '${a.fechaCita} ${a.horaCita}'.compareTo('${b.fechaCita} ${b.horaCita}'));
            final pasadas = service.citas.where((c) => c.isAtendida).toList()
              ..sort((a, b) =>
                  '${b.fechaCita} ${b.horaCita}'.compareTo('${a.fechaCita} ${a.horaCita}'));
            final canceladas = service.citas
                .where((c) => c.isCancelada || c.isNoAsistio)
                .toList()
              ..sort((a, b) =>
                  '${b.fechaCita} ${b.horaCita}'.compareTo('${a.fechaCita} ${a.horaCita}'));

            return Column(
              children: [
                _BarraTabs(proximasCount: proximas.length),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ListaCitas(
                        citas: proximas,
                        vacioMensaje: 'No tienes citas próximas',
                        onRefresh: () => _recargar(context),
                      ),
                      _ListaCitas(
                        citas: pasadas,
                        vacioMensaje: 'Aún no tienes citas atendidas',
                        onRefresh: () => _recargar(context),
                      ),
                      _ListaCitas(
                        citas: canceladas,
                        vacioMensaje: 'No tienes citas canceladas',
                        onRefresh: () => _recargar(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _mostrarFormNuevaCita(context),
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nueva cita',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Future<void> _recargar(BuildContext context) async {
    final token = Provider.of<AuthService>(context, listen: false).token ?? '';
    await Provider.of<CitaService>(context, listen: false).cargarCitas(token);
  }

  void _mostrarFormNuevaCita(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NuevaCitaForm()),
    );
  }
}

class _BarraTabs extends StatelessWidget {
  final int proximasCount;
  const _BarraTabs({required this.proximasCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final border = isDark ? AppTheme.borderDark : AppTheme.border;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: TabBar(
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: textMuted,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 2,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Próximas'),
                if (proximasCount > 0) ...[
                  const SizedBox(width: 6),
                  _Badge(count: proximasCount),
                ],
              ],
            ),
          ),
          const Tab(text: 'Pasadas'),
          const Tab(text: 'Canceladas'),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(999),
      ),
      constraints: const BoxConstraints(minWidth: 20),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ListaCitas extends StatelessWidget {
  final List<Cita> citas;
  final String vacioMensaje;
  final Future<void> Function() onRefresh;

  const _ListaCitas({
    required this.citas,
    required this.vacioMensaje,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: onRefresh,
      child: citas.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(child: _Vacio(mensaje: vacioMensaje)),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: citas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _CitaCard(cita: citas[i]),
            ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final String mensaje;
  const _Vacio({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_busy, size: 48, color: textMuted),
        const SizedBox(height: 10),
        Text(
          mensaje,
          style: TextStyle(color: textMuted, fontSize: 14),
        ),
      ],
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  const _CitaCard({required this.cita});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;
    final textSubtle = isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle;
    final divider = isDark ? AppTheme.borderDark : AppTheme.borderSoft;

    final esFuturo = cita.isProgramada;
    final esAtendida = cita.isAtendida;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _fechaTitulo(cita.fechaCita),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _BadgeEstatus(estatus: cita.estatus),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${cita.horaFormateada} hrs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: esFuturo ? AppTheme.primaryColor : textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (cita.motivo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                cita.motivo,
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
            ),
          if (esAtendida)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Diagnóstico: ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                    TextSpan(
                      text: 'Disponible en consulta',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (esFuturo) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: divider),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _confirmarCancelar(context, cita),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                ),
                child: const Text(
                  'Cancelar cita',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fechaTitulo(String fechaIso) {
    final partes = fechaIso.split('-');
    if (partes.length != 3) return fechaIso;
    try {
      final fecha = DateTime(
        int.parse(partes[0]),
        int.parse(partes[1]),
        int.parse(partes[2]),
      );
      final formato =
          DateFormat('EEEE, d \'de\' MMMM', 'es_MX').format(fecha);
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
        content: const Text('¿Seguro que deseas cancelar esta cita?'),
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
                  SnackBar(content: Text(ok ? 'Cita cancelada' : 'No se pudo cancelar')),
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

class _BadgeEstatus extends StatelessWidget {
  final String estatus;
  const _BadgeEstatus({required this.estatus});

  @override
  Widget build(BuildContext context) {
    final spec = _spec(estatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        spec.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: spec.fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _BadgeSpec _spec(String estatus) {
    switch (estatus) {
      case 'programada':
        return const _BadgeSpec(
          label: 'CONFIRMADA',
          bg: AppTheme.primarySurface,
          fg: AppTheme.primaryColor,
        );
      case 'atendida':
        return const _BadgeSpec(
          label: 'ATENDIDA',
          bg: AppTheme.primarySurface,
          fg: AppTheme.primaryColor,
        );
      case 'cancelada':
        return const _BadgeSpec(
          label: 'CANCELADA',
          bg: Color(0xFFF3F4F6),
          fg: AppTheme.textMuted,
        );
      case 'no_asistio':
        return const _BadgeSpec(
          label: 'NO ASISTIÓ',
          bg: AppTheme.errorSurface,
          fg: AppTheme.error,
        );
      default:
        return const _BadgeSpec(
          label: 'PENDIENTE',
          bg: AppTheme.warningSurface,
          fg: AppTheme.warning,
        );
    }
  }
}

class _BadgeSpec {
  final String label;
  final Color bg;
  final Color fg;
  const _BadgeSpec({required this.label, required this.bg, required this.fg});
}
