import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/services/api_service.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class EditarInfoMedicaDialog extends StatefulWidget {
  final String tipoSangre;
  final String alergias;
  final String enfermedadesCronicas;
  final void Function(String, String, String) onGuardado;

  const EditarInfoMedicaDialog({
    super.key,
    required this.tipoSangre,
    required this.alergias,
    required this.enfermedadesCronicas,
    required this.onGuardado,
  });

  @override
  State<EditarInfoMedicaDialog> createState() =>
      _EditarInfoMedicaDialogState();
}

class _EditarInfoMedicaDialogState extends State<EditarInfoMedicaDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _tipoSangre;
  late final TextEditingController _alergiasCtrl;
  late final TextEditingController _enfermedadesCtrl;
  bool _guardando = false;

  static const _tiposSangre = [
    '', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _tipoSangre = widget.tipoSangre;
    _alergiasCtrl = TextEditingController(text: widget.alergias);
    _enfermedadesCtrl =
        TextEditingController(text: widget.enfermedadesCronicas);
  }

  @override
  void dispose() {
    _alergiasCtrl.dispose();
    _enfermedadesCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      await ApiService.put(
        '/perfil-medico',
        {
          'tipo_sangre': _tipoSangre,
          'alergias': _alergiasCtrl.text.trim(),
          'enfermedades_cronicas': _enfermedadesCtrl.text.trim(),
        },
        token: token,
      );
      if (!mounted) return;
      widget.onGuardado(
        _tipoSangre,
        _alergiasCtrl.text.trim(),
        _enfermedadesCtrl.text.trim(),
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información médica actualizada'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Información médica',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue:
                    _tiposSangre.contains(_tipoSangre) ? _tipoSangre : '',
                decoration: const InputDecoration(
                  labelText: 'Tipo de sangre',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
                items: _tiposSangre
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.isEmpty ? 'No especificado' : t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoSangre = v ?? ''),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _alergiasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alergias',
                  hintText: 'Ej: Penicilina, polvo...',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _enfermedadesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Enfermedades crónicas',
                  hintText: 'Ej: Diabetes, hipertensión...',
                  prefixIcon: Icon(Icons.monitor_heart_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class CambiarPasswordDialog extends StatefulWidget {
  const CambiarPasswordDialog({super.key});
  @override
  State<CambiarPasswordDialog> createState() => _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState extends State<CambiarPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevoCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _guardando = false;
  bool _verActual = false;
  bool _verNuevo = false;
  bool _verConfirm = false;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevoCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      await ApiService.post(
        '/perfil/cambiar-password',
        {
          'password_actual': _actualCtrl.text,
          'password_nuevo': _nuevoCtrl.text,
          'password_nuevo_confirmation': _confirmCtrl.text,
        },
        token: token,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _passField(
    TextEditingController ctrl,
    String label,
    bool ver,
    VoidCallback toggle,
  ) {
    return TextFormField(
      controller: ctrl,
      obscureText: !ver,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(ver
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: toggle,
        ),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Campo requerido' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passField(_actualCtrl, 'Contraseña actual', _verActual,
                  () => setState(() => _verActual = !_verActual)),
              const SizedBox(height: 14),
              _passField(_nuevoCtrl, 'Nueva contraseña', _verNuevo,
                  () => setState(() => _verNuevo = !_verNuevo)),
              const SizedBox(height: 14),
              _passField(_confirmCtrl, 'Confirmar contraseña', _verConfirm,
                  () => setState(() => _verConfirm = !_verConfirm)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
