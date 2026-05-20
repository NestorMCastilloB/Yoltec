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
  String _carrera = '';
  String _tipoSangre = '';
  String _peso = '';
  String _estatura = '';
  String _alergias = '';
  String _enfermedadesCronicas = '';
  String _contactoNombre = '';
  String _contactoTelefono = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarPerfil());
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
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
          _carrera = (perfil['carrera'] ?? '').toString();
          _tipoSangre = (perfil['tipo_sangre'] ?? '').toString();
          _peso = (perfil['peso'] ?? '').toString();
          _estatura = (perfil['estatura'] ?? '').toString();
          _alergias = (perfil['alergias'] ?? '').toString();
          _enfermedadesCronicas =
              (perfil['enfermedades_cronicas'] ?? '').toString();
          _contactoNombre =
              (perfil['contacto_emergencia_nombre'] ?? '').toString();
          _contactoTelefono =
              (perfil['contacto_emergencia_telefono'] ?? '').toString();
          _cargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar perfil';
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cambiarFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      final result = await ApiService.postMultipart(
        '/perfil/foto',
        File(picked.path),
        'foto',
        token: token,
      );
      final nuevaFoto =
          (result['data'] ?? result)['foto_perfil']?.toString();
      if (mounted) {
        setState(() => _fotoPerfil = nuevaFoto);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto actualizada'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
        );
      }
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
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_error != null) return _buildError();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgDark : AppTheme.bg;

    return Container(
      color: bg,
      child: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _cargarPerfil,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Cabecera(
              iniciales: _iniciales,
              nombre: '$_nombre $_apellido'.trim(),
              numeroControl: _numeroControl,
              carrera: _carrera,
              fotoUrl: _fotoPerfil,
              onCambiarFoto: _cambiarFoto,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _mostrarEditarInfoMedica,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text(
                    'Editar',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    minimumSize: const Size(0, 28),
                  ),
                ),
              ),
            ),
            const _SeccionTitulo('Datos físicos'),
            _Tarjeta(filas: [
              _Fila(label: 'Tipo de sangre',
                  valor: _tipoSangre.isEmpty ? 'No registrado' : _tipoSangre),
              if (_peso.isNotEmpty)
                _Fila(label: 'Peso', valor: '$_peso kg'),
              if (_estatura.isNotEmpty)
                _Fila(label: 'Estatura', valor: '$_estatura cm'),
            ]),
            const SizedBox(height: 12),
            const _SeccionTitulo('Información médica'),
            _Tarjeta(filas: [
              _Fila(
                label: 'Alergias',
                valor: _alergias.isEmpty ? 'Ninguna conocida' : _alergias,
              ),
              _Fila(
                label: 'Enfermedades crónicas',
                valor: _enfermedadesCronicas.isEmpty
                    ? 'Ninguna'
                    : _enfermedadesCronicas,
              ),
            ]),
            if (_contactoNombre.isNotEmpty || _contactoTelefono.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SeccionTitulo('Contacto de emergencia'),
              _Tarjeta(filas: [
                if (_contactoNombre.isNotEmpty)
                  _Fila(label: 'Nombre', valor: _contactoNombre),
                if (_contactoTelefono.isNotEmpty)
                  _Fila(label: 'Teléfono', valor: _contactoTelefono),
              ]),
            ],
            const SizedBox(height: 12),
            const _SeccionTitulo('Cuenta'),
            _Tarjeta(filas: [
              if (_email.isNotEmpty)
                _Fila(label: 'Email', valor: _email),
              if (_telefono.isNotEmpty)
                _Fila(label: 'Teléfono', valor: _telefono),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const _CambiarPasswordDialog(),
                ),
                icon: const Icon(Icons.key_outlined, size: 18),
                label: const Text('Cambiar contraseña'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarPerfil,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarEditarInfoMedica() {
    showDialog(
      context: context,
      builder: (_) => _EditarInfoMedicaDialog(
        tipoSangre: _tipoSangre,
        alergias: _alergias,
        enfermedadesCronicas: _enfermedadesCronicas,
        onGuardado: (ts, al, ec) => setState(() {
          _tipoSangre = ts;
          _alergias = al;
          _enfermedadesCronicas = ec;
        }),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  final String iniciales;
  final String nombre;
  final String numeroControl;
  final String carrera;
  final String? fotoUrl;
  final VoidCallback onCambiarFoto;

  const _Cabecera({
    required this.iniciales,
    required this.nombre,
    required this.numeroControl,
    required this.carrera,
    required this.fotoUrl,
    required this.onCambiarFoto,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (numeroControl.isNotEmpty) numeroControl,
      if (carrera.isNotEmpty) carrera,
    ].join(' · ');

    return Container(
      width: double.infinity,
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: (fotoUrl != null && fotoUrl!.isNotEmpty)
                    ? Image.network(
                        fotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarTexto(),
                      )
                    : _avatarTexto(),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onCambiarFoto,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nombre.isEmpty ? 'Sin nombre' : nombre,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              meta,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PuntoActivo(),
                SizedBox(width: 5),
                Text(
                  'Activo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarTexto() {
    return Center(
      child: Text(
        iniciales,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PuntoActivo extends StatelessWidget {
  const _PuntoActivo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF86EFAC),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String texto;
  const _SeccionTitulo(this.texto);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtle = isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 8),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: subtle,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final List<_Fila> filas;
  const _Tarjeta({required this.filas});

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final divider = isDark ? AppTheme.borderDark : AppTheme.borderSoft;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < filas.length; i++) ...[
            filas[i],
            if (i < filas.length - 1)
              Divider(height: 1, color: divider, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String label;
  final String valor;
  const _Fila({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final subtle = isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: subtle,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 15,
              color: textMain,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditarInfoMedicaDialog extends StatefulWidget {
  final String tipoSangre;
  final String alergias;
  final String enfermedadesCronicas;
  final void Function(String, String, String) onGuardado;

  const _EditarInfoMedicaDialog({
    required this.tipoSangre,
    required this.alergias,
    required this.enfermedadesCronicas,
    required this.onGuardado,
  });

  @override
  State<_EditarInfoMedicaDialog> createState() =>
      _EditarInfoMedicaDialogState();
}

class _EditarInfoMedicaDialogState extends State<_EditarInfoMedicaDialog> {
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
