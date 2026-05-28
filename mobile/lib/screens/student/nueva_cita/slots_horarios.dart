import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

// Horario operativo del consultorio: 08:00 a 16:45 cada 15 min (36 slots).
const int kHoraInicio = 8;
const int kHoraFin = 17;
const int kStepMinutos = 15;

class CabeceraSlots extends StatelessWidget {
  final String fecha;
  const CabeceraSlots({super.key, required this.fecha});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final partes = fecha.split('-');
    final dt = DateTime(
      int.parse(partes[0]),
      int.parse(partes[1]),
      int.parse(partes[2]),
    );
    final etiqueta = DateFormat('EEEE, d \'de\' MMMM', 'es_MX').format(dt);
    final capital = etiqueta[0].toUpperCase() + etiqueta.substring(1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Horarios disponibles',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
          ),
        ),
        Flexible(
          child: Text(
            capital,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class GridSlots extends StatelessWidget {
  final List<String> slots;
  final String? slotSel;
  final ValueChanged<String> onSelect;

  const GridSlots({
    super.key,
    required this.slots,
    required this.slotSel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            'Sin horarios disponibles este día',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: slots
          .map(
            (h) => _SlotChip(
              hora: h,
              seleccionado: slotSel == h,
              onTap: () => onSelect(h),
            ),
          )
          .toList(),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String hora;
  final bool seleccionado;
  final VoidCallback onTap;

  const _SlotChip({
    required this.hora,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppTheme.borderDark : AppTheme.border;
    final colorHora = seleccionado
        ? Colors.white
        : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary);
    final colorFin = seleccionado
        ? Colors.white.withValues(alpha: 0.8)
        : (isDark ? AppTheme.textMutedDark : AppTheme.textMuted);

    final partes = hora.split(':');
    final hh = int.parse(partes[0]);
    final mm = int.parse(partes[1]);
    final totalMin = hh * 60 + mm + kStepMinutos;
    final horaFin =
        '${(totalMin ~/ 60).toString().padLeft(2, '0')}:${(totalMin % 60).toString().padLeft(2, '0')}';

    return Material(
      color: seleccionado ? AppTheme.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: seleccionado ? AppTheme.primaryColor : border,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hora,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorHora,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '– $horaFin',
                style: TextStyle(
                  fontSize: 12,
                  color: colorFin,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
