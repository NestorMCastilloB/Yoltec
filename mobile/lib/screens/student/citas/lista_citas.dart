import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yoltec_mobile/models/cita.dart';
import 'package:yoltec_mobile/screens/student/citas/cita_card.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class ListaCitas extends StatelessWidget {
  final List<Cita> citas;
  final String vacioMensaje;
  final Future<void> Function() onRefresh;
  final bool agruparPorMes;

  const ListaCitas({
    super.key,
    required this.citas,
    required this.vacioMensaje,
    required this.onRefresh,
    this.agruparPorMes = false,
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
          : agruparPorMes
              ? _ListaAgrupada(citas: citas)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: citas.length,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(bottom: i < citas.length - 1 ? 12 : 0),
                    child: CitaCard(cita: citas[i]),
                  ),
                ),
    );
  }
}

// Renderiza la lista intercalando headers de mes con cards de cita.
// Asume que `citas` ya viene ordenada por fecha descendente.
class _ListaAgrupada extends StatelessWidget {
  final List<Cita> citas;
  const _ListaAgrupada({required this.citas});

  @override
  Widget build(BuildContext context) {
    final items = _construirItems(citas);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is String) {
          return _HeaderMes(titulo: item, esPrimero: i == 0);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CitaCard(cita: item as Cita),
        );
      },
    );
  }

  static List<Object> _construirItems(List<Cita> citas) {
    final items = <Object>[];
    String? mesActual;
    for (final cita in citas) {
      final mes = _claveMes(cita.fechaCita);
      if (mes != mesActual) {
        items.add(_etiquetaMes(cita.fechaCita));
        mesActual = mes;
      }
      items.add(cita);
    }
    return items;
  }

  static String _claveMes(String fechaIso) {
    final partes = fechaIso.split('-');
    if (partes.length < 2) return fechaIso;
    return '${partes[0]}-${partes[1]}';
  }

  static String _etiquetaMes(String fechaIso) {
    final partes = fechaIso.split('-');
    if (partes.length != 3) return fechaIso;
    try {
      final fecha = DateTime(int.parse(partes[0]), int.parse(partes[1]), 1);
      final txt = DateFormat('MMMM yyyy', 'es_MX').format(fecha);
      return txt[0].toUpperCase() + txt.substring(1);
    } catch (_) {
      return fechaIso;
    }
  }
}

class _HeaderMes extends StatelessWidget {
  final String titulo;
  final bool esPrimero;
  const _HeaderMes({required this.titulo, required this.esPrimero});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;
    return Padding(
      padding: EdgeInsets.only(top: esPrimero ? 8 : 16, bottom: 8),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 0.6,
        ),
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
