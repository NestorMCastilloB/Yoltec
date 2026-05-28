import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class CabeceraPerfil extends StatelessWidget {
  final String iniciales;
  final String nombre;
  final String numeroControl;
  final String carrera;
  final String? fotoUrl;
  final VoidCallback onCambiarFoto;

  const CabeceraPerfil({
    super.key,
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
                child: _construirFoto(),
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

  // Backend devuelve base64 (no URL) en foto_perfil — decide por prefijo
  Widget _construirFoto() {
    final raw = fotoUrl ?? '';
    if (raw.isEmpty) return _avatarTexto();
    if (raw.startsWith('http')) {
      return Image.network(
        raw,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarTexto(),
      );
    }
    try {
      final b64 = raw.contains(',') ? raw.split(',').last : raw;
      return Image.memory(
        base64Decode(b64),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _avatarTexto(),
      );
    } catch (_) {
      return _avatarTexto();
    }
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
