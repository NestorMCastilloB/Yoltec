import 'package:flutter/material.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const MiniStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final textMuted = isDark ? AppTheme.textMutedDark : AppTheme.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: textMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: textMain,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickAccess extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color bgDark;
  final Color iconColor;
  final VoidCallback onTap;

  const QuickAccess({
    super.key,
    required this.icon,
    required this.label,
    required this.bg,
    required this.bgDark,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? bgDark : bg;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 30),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textMain,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
