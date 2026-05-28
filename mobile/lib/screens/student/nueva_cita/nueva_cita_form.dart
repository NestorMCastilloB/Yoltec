import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/screens/student/nueva_cita/calendario_mes.dart';
import 'package:yoltec_mobile/screens/student/nueva_cita/confirmacion_sheet.dart';
import 'package:yoltec_mobile/screens/student/nueva_cita/slots_horarios.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/cita_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

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
      _errorCarga = 'No pudimos cargar los horarios. Verifica tu conexion.';
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<String> get _allSlots {
    final slots = <String>[];
    for (var h = kHoraInicio; h < kHoraFin; h++) {
      for (var m = 0; m < 60; m += kStepMinutos) {
        if (h == kHoraFin - 1 && m > 45) break;
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
      builder: (_) => ConfirmacionSheet(
        fecha: _fechaSel!,
        hora: _horaSel!,
        onConfirmar: _confirmarCita,
      ),
    );
  }

  Future<String?> _confirmarCita(String motivo) async {
    final token = Provider.of<AuthService>(context, listen: false).token ?? '';
    final servicio = Provider.of<CitaService>(context, listen: false);
    final cita = await servicio.crearCita(
      token,
      fechaCita: _fechaSel!,
      horaCita: _horaSel!,
      motivo: motivo,
    );
    if (cita == null) {
      return servicio.error ?? 'No se pudo agendar la cita. Intentalo de nuevo.';
    }
    await servicio.cargarCitas(token);
    if (mounted) Navigator.of(context).pop(true);
    return null;
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
              CalendarioMes(
                year: _year,
                month: _month,
                fechaSel: _fechaSel,
                librePorFecha: _calcularLibresPorFecha(),
                onSelect: _seleccionarDia,
              ),
            const SizedBox(height: 12),
            const LeyendaCalendario(),
            if (_fechaSel != null) ...[
              const SizedBox(height: 28),
              CabeceraSlots(fecha: _fechaSel!),
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
              GridSlots(
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
