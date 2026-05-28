import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/screens/student/citas/lista_citas.dart';
import 'package:yoltec_mobile/screens/student/nueva_cita/nueva_cita_form.dart';
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
                      ListaCitas(
                        citas: proximas,
                        vacioMensaje: 'Sin citas proximas',
                        onRefresh: () => _recargar(context),
                      ),
                      ListaCitas(
                        citas: pasadas,
                        vacioMensaje: 'Todavia sin historial',
                        onRefresh: () => _recargar(context),
                      ),
                      ListaCitas(
                        citas: canceladas,
                        vacioMensaje: 'Nada por aqui',
                        onRefresh: () => _recargar(context),
                        agruparPorMes: true,
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
