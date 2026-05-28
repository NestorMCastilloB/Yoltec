import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

enum _EstadoDia { disponible, poco, lleno, pasado }

class CalendarioMes extends StatelessWidget {
  final int year;
  final int month;
  final String? fechaSel;
  final Map<String, int> librePorFecha;
  final ValueChanged<String> onSelect;

  const CalendarioMes({
    super.key,
    required this.year,
    required this.month,
    required this.fechaSel,
    required this.librePorFecha,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const cabeceras = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final cells = <Widget>[];
    for (final h in cabeceras) {
      cells.add(_HeaderCelda(label: h));
    }

    final diasMes = DateTime(year, month + 1, 0).day;
    final dowPrimero = DateTime(year, month, 1).weekday;
    for (var i = 1; i < dowPrimero; i++) {
      cells.add(const SizedBox());
    }

    final hoy = DateTime.now();
    final hoyStr = DateFormat('yyyy-MM-dd').format(hoy);

    for (var d = 1; d <= diasMes; d++) {
      final fecha = DateTime(year, month, d);
      final fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
      final dow = fecha.weekday;
      if (dow == 7) {
        cells.add(const SizedBox());
        continue;
      }
      final esPasado = fechaStr.compareTo(hoyStr) < 0;
      final libres = librePorFecha[fechaStr] ?? 0;
      _EstadoDia estado;
      if (esPasado) {
        estado = _EstadoDia.pasado;
      } else if (libres == 0) {
        estado = _EstadoDia.lleno;
      } else if (libres < 12) {
        estado = _EstadoDia.poco;
      } else {
        estado = _EstadoDia.disponible;
      }
      cells.add(
        _CeldaDia(
          dia: d,
          estado: estado,
          libres: libres,
          seleccionada: fechaStr == fechaSel,
          onTap: estado == _EstadoDia.pasado || estado == _EstadoDia.lleno
              ? null
              : () => onSelect(fechaStr),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 0.85,
      children: cells,
    );
  }
}

class _HeaderCelda extends StatelessWidget {
  final String label;
  const _HeaderCelda({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle,
        ),
      ),
    );
  }
}

class _CeldaDia extends StatelessWidget {
  final int dia;
  final _EstadoDia estado;
  final int libres;
  final bool seleccionada;
  final VoidCallback? onTap;

  const _CeldaDia({
    required this.dia,
    required this.estado,
    required this.libres,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg = Colors.transparent;
    Color colorNum =
        isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    Color colorDs = AppTheme.textSubtle;
    String? sub;

    switch (estado) {
      case _EstadoDia.pasado:
        colorNum = isDark ? AppTheme.textSubtleDark : const Color(0xFFD1D5DB);
        break;
      case _EstadoDia.lleno:
        bg = AppTheme.errorSurface;
        colorNum = AppTheme.error;
        colorDs = AppTheme.error;
        sub = 'Sin disp';
        break;
      case _EstadoDia.poco:
        colorDs = AppTheme.warning;
        sub = '$libres disp';
        break;
      case _EstadoDia.disponible:
        colorDs = AppTheme.primaryColor;
        sub = '$libres disp';
        break;
    }

    if (seleccionada) {
      bg = AppTheme.primaryColor;
      colorNum = Colors.white;
      colorDs = Colors.white.withValues(alpha: 0.85);
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      seleccionada ? FontWeight.w700 : FontWeight.w600,
                  color: colorNum,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: colorDs,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LeyendaCalendario extends StatelessWidget {
  const LeyendaCalendario({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;
    final subtle = isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: AppTheme.primaryColor, label: 'Disponible', muted: muted),
        Text(' · ', style: TextStyle(color: subtle, fontSize: 11)),
        _LegendItem(color: AppTheme.warning, label: 'Poca', muted: muted),
        Text(' · ', style: TextStyle(color: subtle, fontSize: 11)),
        _LegendItem(color: AppTheme.error, label: 'Lleno', muted: muted),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color muted;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
