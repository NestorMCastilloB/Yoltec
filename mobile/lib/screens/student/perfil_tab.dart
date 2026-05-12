import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/services/api_service.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class PerfilTab extends StatefulWidget {
  const PerfilTab({super.key});

  @override
  State<PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<PerfilTab> {
  bool _cargando = true;
  String? _error;

  String _nombre = '';
  String _apellido = '';
  String _email = '';
  String _numeroControl = '';
  String _telefono = '';
  String? _fotoPerfil;
  String _tipoSangre = '';
  String _alergias = '';
  String _enfermedadesCronicas = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarPerfil());
  }

  Future<void> _cargarPerfil() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final token = Provider.of<AuthService>(context, listen: false).token ?? '';
      final data = await ApiService.get('/perfil-medico', token: token);
      final perfil = data['data'] ?? data;
      if (mounted) {
        setState(() {
          _nombre = (perfil['nombre'] ?? '').toString();
          _apellido = (perfil['apellido'] ?? '').toString();
          _email = (perfil['email'] ?? '').toString();
          _numeroControl = (perfil['numero_control'] ?? '').toString();
          _telefono = (perfil['telefono'] ?? '').toString();
          _fotoPerfil = perfil['foto_perfil']?.toString();
          _tipoSangre = (perfil['tipo_sangre'] ?? '').toString();
          _alergias = (perfil['alergias'] ?? '').toString();
          _enfermedadesCronicas = (perfil['enfermedades_cronicas'] ?? '').toString();
          _cargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _cargando = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Error al cargar perfil'; _cargando = false; });
    }
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (picked == null || !mounted) return;
    try {
      final token = Provider.of<AuthService>(context, listen: false).token ?? '';
      final result = await ApiService.postMultipart('/perfil/foto', File(picked.path), 'foto', token: token);
      final nuevaFoto = (result['data'] ?? result)['foto_perfil']?.toString();
      if (mounted) {
        setState(() => _fotoPerfil = nuevaFoto);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada'), backgroundColor: AppTheme.primaryColor),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
      );
    }
  }

  String get _iniciales {
    final n = _nombre.trim();
    final a = _apellido.trim();
    if (n.isEmpty && a.isEmpty) return '?';
    return '${n.isNotEmpty ? n[0].toUpperCase() : ''}${a.isNotEmpty ? a[0].toUpperCase() : ''}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    if (_error != null) return _buildError();

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _cargarPerfil,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAvatar(),
          const SizedBox(height: 10),
          Center(child: Text('$_nombre $_apellido'.trim(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gray900))),
          if (_email.isNotEmpty) Center(child: Text(_email,
            style: const TextStyle(color: AppTheme.gray600, fontSize: 13))),
          const SizedBox(height: 20),
          _SeccionCard(titulo: 'Datos Personales', icono: Icons.badge_outlined, children: [
            _CampoInfo(label: 'Numero de control', valor: _numeroControl),
            _CampoInfo(label: 'Nombre', valor: '$_nombre $_apellido'.trim()),
            _CampoInfo(label: 'Email', valor: _email),
            if (_telefono.isNotEmpty) _CampoInfo(label: 'Telefono', valor: _telefono),
          ]),
          const SizedBox(height: 14),
          _SeccionCard(
            titulo: 'Información Médica',
            icono: Icons.medical_information_outlined,
            accion: TextButton.icon(
              onPressed: () => _mostrarEditarInfoMedica(),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
            children: [
              _CampoInfo(label: 'Tipo de sangre', valor: _tipoSangre.isEmpty ? 'No registrado' : _tipoSangre),
              _CampoInfo(label: 'Alergias', valor: _alergias.isEmpty ? 'Ninguna' : _alergias),
              _CampoInfo(label: 'Enfermedades cronicas', valor: _enfermedadesCronicas.isEmpty ? 'Ninguna' : _enfermedadesCronicas),
            ],
          ),
          const SizedBox(height: 14),
          _SeccionCard(titulo: 'Seguridad', icono: Icons.lock_outline, children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showDialog(context: context, builder: (_) => const _CambiarPasswordDialog()),
                icon: const Icon(Icons.key_outlined, size: 18),
                label: const Text('Cambiar contraseña'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: Stack(children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: AppTheme.primarySurface,
          backgroundImage: (_fotoPerfil != null && _fotoPerfil!.isNotEmpty) ? NetworkImage(_fotoPerfil!) : null,
          child: (_fotoPerfil == null || _fotoPerfil!.isEmpty)
            ? Text(_iniciales, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))
            : null,
        ),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: _cambiarFoto,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.gray700)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _cargarPerfil, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reintentar')),
      ]),
    ));
  }

  void _mostrarEditarInfoMedica() {
    showDialog(
      context: context,
      builder: (_) => _EditarInfoMedicaDialog(
        tipoSangre: _tipoSangre, alergias: _alergias, enfermedadesCronicas: _enfermedadesCronicas,
        onGuardado: (ts, al, ec) => setState(() { _tipoSangre = ts; _alergias = al; _enfermedadesCronicas = ec; }),
      ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;
  final Widget? accion;

  const _SeccionCard({required this.titulo, required this.icono, required this.children, this.accion});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icono, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.gray800)),
            if (accion != null) ...[const Spacer(), accion!],
          ]),
          const Divider(height: 20),
          ...children,
        ]),
      ),
    );
  }
}

class _CampoInfo extends StatelessWidget {
  final String label;
  final String valor;

  const _CampoInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray500, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(fontSize: 14, color: AppTheme.gray800)),
      ]),
    );
  }
}

class _EditarInfoMedicaDialog extends StatefulWidget {
  final String tipoSangre;
  final String alergias;
  final String enfermedadesCronicas;
  final void Function(String, String, String) onGuardado;

  const _EditarInfoMedicaDialog({required this.tipoSangre, required this.alergias, required this.enfermedadesCronicas, required this.onGuardado});

  @override
  State<_EditarInfoMedicaDialog> createState() => _EditarInfoMedicaDialogState();
}

class _EditarInfoMedicaDialogState extends State<_EditarInfoMedicaDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _tipoSangre;
  late final TextEditingController _alergiasCtrl;
  late final TextEditingController _enfermedadesCtrl;
  bool _guardando = false;

  static const _tiposSangre = ['', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _tipoSangre = widget.tipoSangre;
    _alergiasCtrl = TextEditingController(text: widget.alergias);
    _enfermedadesCtrl = TextEditingController(text: widget.enfermedadesCronicas);
  }

  @override
  void dispose() { _alergiasCtrl.dispose(); _enfermedadesCtrl.dispose(); super.dispose(); }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final token = Provider.of<AuthService>(context, listen: false).token ?? '';
      await ApiService.put('/perfil-medico', {'tipo_sangre': _tipoSangre, 'alergias': _alergiasCtrl.text.trim(), 'enfermedades_cronicas': _enfermedadesCtrl.text.trim()}, token: token);
      if (!mounted) return;
      widget.onGuardado(_tipoSangre, _alergiasCtrl.text.trim(), _enfermedadesCtrl.text.trim());
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Información médica actualizada'), backgroundColor: AppTheme.primaryColor));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.medical_information_outlined, color: AppTheme.primaryColor, size: 22), SizedBox(width: 8), Text('Info. Médica', style: TextStyle(fontSize: 17))]),
      content: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(
          initialValue: _tiposSangre.contains(_tipoSangre) ? _tipoSangre : '',
          decoration: const InputDecoration(labelText: 'Tipo de sangre', prefixIcon: Icon(Icons.bloodtype_outlined)),
          items: _tiposSangre.map((t) => DropdownMenuItem(value: t, child: Text(t.isEmpty ? 'No especificado' : t))).toList(),
          onChanged: (v) => setState(() => _tipoSangre = v ?? ''),
        ),
        const SizedBox(height: 14),
        TextFormField(controller: _alergiasCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Alergias', hintText: 'Ej: Penicilina, polvo...', prefixIcon: Icon(Icons.warning_amber_outlined))),
        const SizedBox(height: 14),
        TextFormField(controller: _enfermedadesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Enfermedades cronicas', hintText: 'Ej: Diabetes, hipertension...', prefixIcon: Icon(Icons.monitor_heart_outlined))),
      ]))),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardando ? null : _guardar, child: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Guardar')),
      ],
    );
  }
}

class _CambiarPasswordDialog extends StatefulWidget {
  const _CambiarPasswordDialog();
  @override
  State<_CambiarPasswordDialog> createState() => _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState extends State<_CambiarPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevoCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _guardando = false;
  bool _verActual = false;
  bool _verNuevo = false;
  bool _verConfirm = false;

  @override
  void dispose() { _actualCtrl.dispose(); _nuevoCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final token = Provider.of<AuthService>(context, listen: false).token ?? '';
      await ApiService.post('/perfil/cambiar-password', {'password_actual': _actualCtrl.text, 'password_nuevo': _nuevoCtrl.text, 'password_nuevo_confirmation': _confirmCtrl.text}, token: token);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada'), backgroundColor: AppTheme.primaryColor));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _passField(TextEditingController ctrl, String label, bool ver, VoidCallback toggle) {
    return TextFormField(
      controller: ctrl, obscureText: !ver,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(icon: Icon(ver ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: toggle)),
      validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.lock_outline, color: AppTheme.primaryColor, size: 22), SizedBox(width: 8), Text('Cambiar contraseña', style: TextStyle(fontSize: 17))]),
      content: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _passField(_actualCtrl, 'Contraseña actual', _verActual, () => setState(() => _verActual = !_verActual)),
        const SizedBox(height: 14),
        _passField(_nuevoCtrl, 'Nueva contraseña', _verNuevo, () => setState(() => _verNuevo = !_verNuevo)),
        const SizedBox(height: 14),
        _passField(_confirmCtrl, 'Confirmar contraseña', _verConfirm, () => setState(() => _verConfirm = !_verConfirm)),
      ]))),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardando ? null : _guardar, child: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Guardar')),
      ],
    );
  }
}
