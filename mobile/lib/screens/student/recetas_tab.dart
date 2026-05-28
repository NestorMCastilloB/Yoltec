import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/models/receta.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/receta_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class RecetasTab extends StatefulWidget {
  const RecetasTab({super.key});

  @override
  State<RecetasTab> createState() => _RecetasTabState();
}

class _RecetasTabState extends State<RecetasTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _coincide(Receta receta) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    if (receta.indicaciones.toLowerCase().contains(q)) return true;
    if ((receta.doctorNombre ?? '').toLowerCase().contains(q)) return true;
    for (final m in receta.medicamentos) {
      if (m.nombre.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgDark : AppTheme.bg;

    return Container(
      color: bg,
      child: Column(
        children: [
          _BarraBusqueda(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async {
                final token = Provider.of<AuthService>(context, listen: false)
                        .token ??
                    '';
                await Provider.of<RecetaService>(context, listen: false)
                    .cargarRecetas(token);
              },
              child: Consumer<RecetaService>(
                builder: (context, service, _) {
                  if (service.isLoading && service.recetas.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor),
                    );
                  }
                  final filtradas =
                      service.recetas.where(_coincide).toList();
                  if (filtradas.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 60),
                        Center(
                          child: _Vacio(
                            mensaje: service.recetas.isEmpty
                                ? 'No tienes recetas registradas'
                                : 'Sin resultados',
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtradas.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(bottom: i < filtradas.length - 1 ? 12 : 0),
                      child: _RecetaCard(receta: filtradas[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraBusqueda extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _BarraBusqueda({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF3F4F6);
    final subtle = isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle;

    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar receta o medicamento...',
          hintStyle: TextStyle(color: subtle, fontSize: 13.5),
          prefixIcon: Icon(Icons.search, color: subtle, size: 18),
          filled: true,
          fillColor: fill,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final String mensaje;
  const _Vacio({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.medication_outlined, size: 44, color: muted),
        const SizedBox(height: 10),
        Text(
          mensaje,
          style: TextStyle(color: muted, fontSize: 14),
        ),
      ],
    );
  }
}

class _RecetaCard extends StatelessWidget {
  final Receta receta;
  const _RecetaCard({required this.receta});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;
    final textSubtle = isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle;
    final divider = isDark ? AppTheme.borderDark : AppTheme.borderSoft;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChipFecha(fecha: receta.fechaEmision),
              if ((receta.doctorNombre ?? '').isNotEmpty)
                Flexible(
                  child: Text(
                    receta.doctorNombre!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: divider),
          const SizedBox(height: 12),
          if (receta.medicamentos.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in receta.medicamentos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MedRow(med: m, textMain: textMain, textMuted: textMuted),
                  ),
              ],
            ),
          if (receta.indicaciones.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              receta.indicaciones,
              style: TextStyle(
                fontSize: 12,
                color: textSubtle,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: divider),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _mostrarDetalle(context, receta),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: const Size(0, 28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver detalle completo',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, Receta receta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleSheet(receta: receta),
    );
  }
}

class _ChipFecha extends StatelessWidget {
  final String fecha;
  const _ChipFecha({required this.fecha});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF3F4F6);
    final color = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _formatear(fecha),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  String _formatear(String fechaIso) {
    final partes = fechaIso.split('-');
    if (partes.length != 3) return fechaIso;
    try {
      final fecha = DateTime(
        int.parse(partes[0]),
        int.parse(partes[1]),
        int.parse(partes[2]),
      );
      final texto = DateFormat('d MMM y', 'es_MX').format(fecha).toUpperCase();
      return texto.replaceAll('.', '');
    } catch (_) {
      return fechaIso;
    }
  }
}

class _MedRow extends StatelessWidget {
  final Medicamento med;
  final Color textMain;
  final Color textMuted;
  const _MedRow({
    required this.med,
    required this.textMain,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final extras = <String>[];
    if (med.dosis.isNotEmpty) extras.add(med.dosis);
    if (med.frecuencia.isNotEmpty) extras.add(med.frecuencia);
    final dosisTexto = extras.join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.medication_outlined,
              size: 16, color: textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: med.nombre,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: textMain,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                if (dosisTexto.isNotEmpty)
                  TextSpan(
                    text: ' — $dosisTexto',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetalleSheet extends StatelessWidget {
  final Receta receta;
  const _DetalleSheet({required this.receta});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Text(
                    'Receta #${receta.id}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Emitida el ${receta.fechaFormateada}'
                    '${(receta.doctorNombre ?? '').isNotEmpty ? ' · ${receta.doctorNombre}' : ''}',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Medicamentos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final m in receta.medicamentos) ...[
                    _MedDetalle(med: m, textMain: textMain, textMuted: textMuted),
                    const SizedBox(height: 8),
                  ],
                  if (receta.indicaciones.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Indicaciones',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      receta.indicaciones,
                      style: TextStyle(
                        fontSize: 14,
                        color: textMain,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedDetalle extends StatelessWidget {
  final Medicamento med;
  final Color textMain;
  final Color textMuted;
  const _MedDetalle({
    required this.med,
    required this.textMain,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            med.nombre,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textMain,
            ),
          ),
          if (med.dosis.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Dosis: ${med.dosis}',
                  style: TextStyle(fontSize: 13, color: textMuted)),
            ),
          if (med.frecuencia.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Frecuencia: ${med.frecuencia}',
                  style: TextStyle(fontSize: 13, color: textMuted)),
            ),
          if (med.duracion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Duración: ${med.duracion}',
                  style: TextStyle(fontSize: 13, color: textMuted)),
            ),
        ],
      ),
    );
  }
}
