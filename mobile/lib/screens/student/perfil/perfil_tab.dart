import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/screens/student/perfil/cabecera_perfil.dart';
import 'package:yoltec_mobile/screens/student/perfil/dialogs_perfil.dart';
import 'package:yoltec_mobile/screens/student/perfil/secciones_perfil.dart';
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
      // Backend devuelve { "perfil": {...} } — sin esta lectura la foto y demas campos vuelven nulos al recargar
      final perfil = data['perfil'] ?? data['data'] ?? data;
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
          _error = 'No pudimos cargar tu perfil. Verifica tu conexion.';
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
    final file = File(picked.path);
    // Backend valida max:2048; cortamos antes para dar feedback amigable y no gastar red.
    final sizeBytes = await file.length();
    if (!mounted) return;
    if (sizeBytes > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La foto supera 2 MB. Elige otra o reduce la calidad.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    try {
      final token =
          Provider.of<AuthService>(context, listen: false).token ?? '';
      final result = await ApiService.postMultipart(
        '/perfil/foto',
        file,
        'foto',
        token: token,
      );
      final payload = (result['data'] ?? result) as Map<String, dynamic>;
      final nuevaFoto = (payload['foto_url'] ?? payload['foto_perfil'])?.toString();
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

  void _mostrarEditarInfoMedica() {
    showDialog(
      context: context,
      builder: (_) => EditarInfoMedicaDialog(
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
            CabeceraPerfil(
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
            const SeccionTitulo('Datos físicos'),
            Tarjeta(filas: [
              FilaPerfil(
                label: 'Tipo de sangre',
                valor: _tipoSangre.isEmpty ? 'No registrado' : _tipoSangre,
              ),
              if (_peso.isNotEmpty)
                FilaPerfil(label: 'Peso', valor: '$_peso kg'),
              if (_estatura.isNotEmpty)
                FilaPerfil(label: 'Estatura', valor: '$_estatura cm'),
            ]),
            const SizedBox(height: 12),
            const SeccionTitulo('Información médica'),
            Tarjeta(filas: [
              FilaPerfil(
                label: 'Alergias',
                valor: _alergias.isEmpty ? 'Ninguna conocida' : _alergias,
              ),
              FilaPerfil(
                label: 'Enfermedades crónicas',
                valor: _enfermedadesCronicas.isEmpty
                    ? 'Ninguna'
                    : _enfermedadesCronicas,
              ),
            ]),
            if (_contactoNombre.isNotEmpty || _contactoTelefono.isNotEmpty) ...[
              const SizedBox(height: 12),
              const SeccionTitulo('Contacto de emergencia'),
              Tarjeta(filas: [
                if (_contactoNombre.isNotEmpty)
                  FilaPerfil(label: 'Nombre', valor: _contactoNombre),
                if (_contactoTelefono.isNotEmpty)
                  FilaPerfil(label: 'Teléfono', valor: _contactoTelefono),
              ]),
            ],
            const SizedBox(height: 12),
            const SeccionTitulo('Cuenta'),
            Tarjeta(filas: [
              if (_email.isNotEmpty)
                FilaPerfil(label: 'Email', valor: _email),
              if (_telefono.isNotEmpty)
                FilaPerfil(label: 'Teléfono', valor: _telefono),
            ]),
            const SizedBox(height: 12),
            const SeccionTitulo('Preferencias'),
            const ToggleTema(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const CambiarPasswordDialog(),
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
}
