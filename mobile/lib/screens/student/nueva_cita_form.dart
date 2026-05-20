import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

// Slots fijos del consultorio: 08:00 a 16:45 cada 15 min (36 slots).
const _horaInicio = 8;
const _horaFin = 17;
const _stepMinutos = 15;

class _DayInfo {
  final Set<String> ocupados;
  final String? horaCierre;
  final bool lleno;
  const _DayInfo({
    required this.ocupados,
    required this.horaCierre,
    required this.lleno,
  });
}

class NuevaCitaForm extends StatefulWidget {
  const NuevaCitaForm({super.key});

  @override
  State<NuevaCitaForm> createState() => _NuevaCitaFormState();
}

class _NuevaCitaFormState extends State<NuevaCitaForm> {
  late int _year;
  late int _month;
  final Map<String, _DayInfo> _infoMes = {};
  String? _fechaSel;
  String? _horaSel;
  bool _cargando = false;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _year = hoy.year;
    _month = hoy.month;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _cargarDisponibilidad());
  }

  Future<void> _cargarDisponibilidad() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
      _infoMes.clear();
    });
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      final data = await Provider.of<CitaService>(context, listen: false)
          .obtenerDisponibilidad(token, _month, _year);
      final days = data['days'] as List<dynamic>? ?? [];
      for (final raw in days) {
        final map = raw as Map<String, dynamic>;
        final fecha = (map['date'] as String? ?? '').split('T').first;
        if (fecha.isEmpty) continue;
        final ocupados = (map['taken_slots'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toSet();
        final special = map['special'] as Map<String, dynamic>?;
        final lleno = special?['status'] == 'full';
        final horaCierre = special?['hora_cierre'] as String?;
        _infoMes[fecha] = _DayInfo(
          ocupados: ocupados,
          horaCierre: horaCierre,
          lleno: lleno,
        );
      }
    } catch (e) {
      _errorCarga = 'No se pudo cargar la disponibilidad';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<String> get _allSlots {
    final slots = <String>[];
    for (var h = _horaInicio; h < _horaFin; h++) {
      for (var m = 0; m < 60; m += _stepMinutos) {
        if (h == _horaFin - 1 && m > 45) break;
        slots.add(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }

  List<String> _slotsLibres(String fecha) {
    final info = _infoMes[fecha];
    if (info != null && info.lleno) return const [];

    final hoy = DateTime.now();
    final fechaHoy =
        DateFormat('yyyy-MM-dd').format(hoy);
    final ahora =
        '${hoy.hour.toString().padLeft(2, '0')}:${hoy.minute.toString().padLeft(2, '0')}';

    return _allSlots.where((h) {
      if (info != null && info.ocupados.contains(h)) return false;
      if (info?.horaCierre != null && h.compareTo(info!.horaCierre!) >= 0) {
        return false;
      }
      if (fecha == fechaHoy && h.compareTo(ahora) <= 0) return false;
      return true;
    }).toList();
  }

  void _mesAnterior() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
      _fechaSel = null;
      _horaSel = null;
    });
    _cargarDisponibilidad();
  }

  void _mesSiguiente() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
      _fechaSel = null;
      _horaSel = null;
    });
    _cargarDisponibilidad();
  }

  void _seleccionarDia(String fecha) {
    setState(() {
      _fechaSel = fecha;
      _horaSel = null;
    });
  }

  void _seleccionarHora(String hora) {
    setState(() => _horaSel = hora);
    _mostrarConfirmacion();
  }

  void _mostrarConfirmacion() {
    if (_fechaSel == null || _horaSel == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmacionSheet(
        fecha: _fechaSel!,
        hora: _horaSel!,
        onConfirmar: _confirmarCita,
      ),
    );
  }

  Future<bool> _confirmarCita(String motivo) async {
    final token = Provider.of<AuthService>(context, listen: false).token ?? '';
    final servicio = Provider.of<CitaService>(context, listen: false);
    final cita = await servicio.crearCita(
      token,
      fechaCita: _fechaSel!,
      horaCita: '$_horaSel:00',
      motivo: motivo,
    );
    if (cita == null) return false;
    await servicio.cargarCitas(token);
    if (mounted) Navigator.of(context).pop(true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgDark : AppTheme.surface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Agendar cita',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            _seccionTitulo('Selecciona un día'),
            const SizedBox(height: 12),
            _navegadorMes(),
            const SizedBox(height: 10),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryColor),
                ),
              )
            else if (_errorCarga != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(_errorCarga!,
                      style: const TextStyle(color: AppTheme.error)),
                ),
              )
            else
              _Calendario(
                year: _year,
                month: _month,
                fechaSel: _fechaSel,
                librePorFecha: _calcularLibresPorFecha(),
                onSelect: _seleccionarDia,
              ),
            const SizedBox(height: 12),
            const _LeyendaCalendario(),
            if (_fechaSel != null) ...[
              const SizedBox(height: 28),
              _CabeceraSlots(fecha: _fechaSel!),
              const SizedBox(height: 4),
              const Text(
                'Solo se muestran horarios libres',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              _GridSlots(
                slots: _slotsLibres(_fechaSel!),
                slotSel: _horaSel,
                onSelect: _seleccionarHora,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, int> _calcularLibresPorFecha() {
    final mapa = <String, int>{};
    final diasMes = DateTime(_year, _month + 1, 0).day;
    for (var d = 1; d <= diasMes; d++) {
      final fecha = DateFormat('yyyy-MM-dd')
          .format(DateTime(_year, _month, d));
      mapa[fecha] = _slotsLibres(fecha).length;
    }
    return mapa;
  }

  Widget _seccionTitulo(String texto) => Text(
        texto,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.textPrimaryDark
              : AppTheme.textPrimary,
        ),
      );

  Widget _navegadorMes() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fecha = DateTime(_year, _month);
    final etiqueta = DateFormat('MMMM y', 'es_MX').format(fecha);
    final capital = etiqueta[0].toUpperCase() + etiqueta.substring(1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 22),
          onPressed: _mesAnterior,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
          visualDensity: VisualDensity.compact,
        ),
        Text(
          capital,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 22),
          onPressed: _mesSiguiente,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _Calendario extends StatelessWidget {
  final int year;
  final int month;
  final String? fechaSel;
  final Map<String, int> librePorFecha;
  final ValueChanged<String> onSelect;

  const _Calendario({
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

enum _EstadoDia { disponible, poco, lleno, pasado }

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

class _LeyendaCalendario extends StatelessWidget {
  const _LeyendaCalendario();

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

class _CabeceraSlots extends StatelessWidget {
  final String fecha;
  const _CabeceraSlots({required this.fecha});

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

class _GridSlots extends StatelessWidget {
  final List<String> slots;
  final String? slotSel;
  final ValueChanged<String> onSelect;

  const _GridSlots({
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
    final totalMin = hh * 60 + mm + _stepMinutos;
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

class _ConfirmacionSheet extends StatefulWidget {
  final String fecha;
  final String hora;
  final Future<bool> Function(String motivo) onConfirmar;

  const _ConfirmacionSheet({
    required this.fecha,
    required this.hora,
    required this.onConfirmar,
  });

  @override
  State<_ConfirmacionSheet> createState() => _ConfirmacionSheetState();
}

class _ConfirmacionSheetState extends State<_ConfirmacionSheet> {
  final _motivoCtrl = TextEditingController();
  String? _errorMotivo;
  bool _enviando = false;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final motivo = _motivoCtrl.text.trim();
    if (motivo.isEmpty) {
      setState(() => _errorMotivo = '* El motivo es obligatorio');
      return;
    }
    setState(() {
      _enviando = true;
      _errorMotivo = null;
    });
    final ok = await widget.onConfirmar(motivo);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (!ok) {
      setState(() => _errorMotivo = 'No se pudo agendar. Intenta de nuevo.');
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita agendada exitosamente')),
      );
    }
  }

  String _resumen() {
    final partes = widget.fecha.split('-');
    final dt = DateTime(
      int.parse(partes[0]),
      int.parse(partes[1]),
      int.parse(partes[2]),
    );
    final etiqueta = DateFormat('EEEE d \'de\' MMMM', 'es_MX').format(dt);
    final capital = etiqueta[0].toUpperCase() + etiqueta.substring(1);
    final partesH = widget.hora.split(':');
    final hh = int.parse(partesH[0]);
    final mm = int.parse(partesH[1]);
    final fin = hh * 60 + mm + _stepMinutos;
    final horaFin =
        '${(fin ~/ 60).toString().padLeft(2, '0')}:${(fin % 60).toString().padLeft(2, '0')}';
    return '$capital · ${widget.hora} – $horaFin';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Confirmar cita',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _resumen(),
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: isDark ? AppTheme.borderDark : AppTheme.borderSoft,
            ),
            const SizedBox(height: 14),
            Text(
              'Motivo de la cita',
              style: TextStyle(
                fontSize: 12.5,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _motivoCtrl,
              maxLines: 3,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe brevemente el motivo...',
              ),
            ),
            if (_errorMotivo != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorMotivo!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _enviando ? null : _confirmar,
                child: _enviando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Confirmar cita'),
              ),
            ),
            TextButton(
              onPressed:
                  _enviando ? null : () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
