import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yoltec_mobile/screens/student/nueva_cita/slots_horarios.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class ConfirmacionSheet extends StatefulWidget {
  final String fecha;
  final String hora;
  final Future<String?> Function(String motivo) onConfirmar;

  const ConfirmacionSheet({
    super.key,
    required this.fecha,
    required this.hora,
    required this.onConfirmar,
  });

  @override
  State<ConfirmacionSheet> createState() => _ConfirmacionSheetState();
}

class _ConfirmacionSheetState extends State<ConfirmacionSheet> {
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
    final error = await widget.onConfirmar(motivo);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) {
      setState(() => _errorMotivo = error);
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
    final fin = hh * 60 + mm + kStepMinutos;
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
