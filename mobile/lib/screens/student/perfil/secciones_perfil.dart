import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/services/theme_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class SeccionTitulo extends StatelessWidget {
  final String texto;
  const SeccionTitulo(this.texto, {super.key});

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

class Tarjeta extends StatelessWidget {
  final List<FilaPerfil> filas;
  const Tarjeta({super.key, required this.filas});

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

class FilaPerfil extends StatelessWidget {
  final String label;
  final String valor;
  const FilaPerfil({super.key, required this.label, required this.valor});

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

class ToggleTema extends StatelessWidget {
  const ToggleTema({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final subtle = isDark ? AppTheme.textSubtleDark : AppTheme.textSubtle;

    return Consumer<ThemeService>(
      builder: (_, theme, __) => Container(
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
        child: SwitchListTile(
          value: theme.isDark,
          onChanged: (_) => theme.toggle(),
          activeThumbColor: AppTheme.primaryColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Icon(
            theme.isDark ? Icons.dark_mode : Icons.light_mode,
            color: AppTheme.primaryColor,
          ),
          title: Text(
            'Modo oscuro',
            style: TextStyle(
              fontSize: 15,
              color: textMain,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            theme.isDark ? 'Activado' : 'Desactivado',
            style: TextStyle(fontSize: 12, color: subtle),
          ),
        ),
      ),
    );
  }
}
