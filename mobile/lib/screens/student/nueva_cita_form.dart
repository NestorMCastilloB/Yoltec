import 'package:flutter/material.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

// Stub temporal — la implementación real (calendario + slots) llega en Bloque 4 Fase 5.
class NuevaCitaForm extends StatelessWidget {
  const NuevaCitaForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.gray400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Icon(Icons.event_available, size: 48, color: AppTheme.primaryColor),
          const SizedBox(height: 12),
          const Text(
            'Agendar cita',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta función estará disponible pronto. Por ahora puedes agendar desde la versión web.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gray600, fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    );
  }
}
