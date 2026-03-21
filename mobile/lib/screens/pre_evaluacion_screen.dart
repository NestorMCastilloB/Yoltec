import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoltec_mobile/services/auth_service.dart';
import 'package:yoltec_mobile/services/pre_evaluacion_service.dart';
import 'package:yoltec_mobile/utils/app_theme.dart';

class PreEvaluacionScreen extends StatefulWidget {
  final int citaId;

  const PreEvaluacionScreen({super.key, required this.citaId});

  @override
  State<PreEvaluacionScreen> createState() => _PreEvaluacionScreenState();
}

class _PreEvaluacionScreenState extends State<PreEvaluacionScreen> {
  int _currentIndex = 0;
  final Map<String, dynamic> _respuestas = {};
  bool _enviando = false;
  Map<String, dynamic>? _resultado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarPreguntas());
  }

  Future<void> _cargarPreguntas() async {
    final token =
        Provider.of<AuthService>(context, listen: false).token ?? '';
    await Provider.of<PreEvaluacionService>(context, listen: false)
        .cargarPreguntas(token);
  }

  void _responder(String preguntaId, dynamic respuesta) {
    setState(() {
      _respuestas[preguntaId] = respuesta;
    });
  }

  void _siguiente(List<Map<String, dynamic>> preguntas) {
    if (_currentIndex < preguntas.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _enviar(preguntas);
    }
  }

  void _anterior() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _enviar(List<Map<String, dynamic>> preguntas) async {
    setState(() => _enviando = true);

    final service =
        Provider.of<PreEvaluacionService>(context, listen: false);
    final token =
        Provider.of<AuthService>(context, listen: false).token ?? '';

    final resultado = await service.enviarRespuestas(
      token,
      widget.citaId,
      _respuestas,
    );

    if (!mounted) return;
    setState(() {
      _enviando = false;
      _resultado = resultado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-evaluacion'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<PreEvaluacionService>(
        builder: (context, service, _) {
          if (service.isLoading || _enviando) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text('Procesando...'),
                ],
              ),
            );
          }

          if (service.error != null) {
            return _buildError(service.error!);
          }

          if (_resultado != null) {
            return _buildResultado(_resultado!);
          }

          if (service.preguntas.isEmpty) {
            return const Center(
              child: Text('No hay preguntas disponibles.'),
            );
          }

          return _buildPregunta(service.preguntas);
        },
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.error, size: 60),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargarPreguntas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPregunta(List<Map<String, dynamic>> preguntas) {
    final pregunta = preguntas[_currentIndex];
    final preguntaId = pregunta['id'].toString();
    final texto = pregunta['texto'] as String? ?? '';
    final opciones = pregunta['opciones'] as List<dynamic>? ?? [];
    final respuestaActual = _respuestas[preguntaId];
    final progreso = (_currentIndex + 1) / preguntas.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progreso
            Row(
              children: [
                Text(
                  'Pregunta ${_currentIndex + 1} de ${preguntas.length}',
                  style: const TextStyle(
                    color: AppTheme.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progreso * 100).round()}%',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progreso,
              backgroundColor: AppTheme.gray200,
              valueColor:
                  const AlwaysStoppedAnimation(AppTheme.primaryColor),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 28),

            // Icono de salud
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.healing,
                  color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(height: 16),

            // Texto de pregunta
            Text(
              texto,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 24),

            // Opciones
            Expanded(
              child: ListView.separated(
                itemCount: opciones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final opcion = opciones[i].toString();
                  final seleccionada = respuestaActual == opcion;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _responder(preguntaId, opcion),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: seleccionada
                              ? AppTheme.primarySurface
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: seleccionada
                                ? AppTheme.primaryColor
                                : AppTheme.gray300,
                            width: seleccionada ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: seleccionada
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                border: Border.all(
                                  color: seleccionada
                                      ? AppTheme.primaryColor
                                      : AppTheme.gray400,
                                  width: 2,
                                ),
                              ),
                              child: seleccionada
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opcion,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: seleccionada
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: seleccionada
                                      ? AppTheme.primaryColor
                                      : AppTheme.gray800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Botones de navegacion
            Row(
              children: [
                if (_currentIndex > 0)
                  OutlinedButton.icon(
                    onPressed: _anterior,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Anterior'),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: respuestaActual == null
                      ? null
                      : () => _siguiente(preguntas),
                  icon: Icon(
                    _currentIndex == preguntas.length - 1
                        ? Icons.send
                        : Icons.arrow_forward,
                    size: 18,
                  ),
                  label: Text(
                    _currentIndex == preguntas.length - 1
                        ? 'Enviar'
                        : 'Siguiente',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultado(Map<String, dynamic> resultado) {
    final diagnostico =
        resultado['diagnostico_principal'] as String? ?? 'Sin diagnostico';
    final confianza = resultado['confianza'];
    final posibles =
        resultado['posibles_enfermedades'] as List<dynamic>? ?? [];
    final recomendaciones =
        resultado['recomendaciones'] as String? ??
            resultado['mensaje'] as String? ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de exito
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.primaryColor,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pre-evaluacion completada',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'El medico revisara tu evaluacion antes de la consulta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.gray600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Diagnostico principal
            _buildResultCard(
              icon: Icons.medical_information_outlined,
              title: 'Diagnostico preliminar',
              content: diagnostico,
              color: AppTheme.primaryColor,
            ),

            if (confianza != null) ...[
              const SizedBox(height: 16),
              _buildConfianzaCard(confianza),
            ],

            if (posibles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.list_alt,
                              color: AppTheme.info, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Posibles enfermedades',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.gray800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...posibles.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 6,
                                    color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(e.toString(),
                                        style: const TextStyle(
                                            fontSize: 14))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],

            if (recomendaciones.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildResultCard(
                icon: Icons.tips_and_updates_outlined,
                title: 'Recomendaciones',
                content: recomendaciones,
                color: AppTheme.warning,
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Volver al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.gray700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfianzaCard(dynamic confianza) {
    double valor;
    if (confianza is double) {
      valor = confianza;
    } else if (confianza is int) {
      valor = confianza.toDouble();
    } else {
      valor = double.tryParse(confianza.toString()) ?? 0.0;
    }
    // Normalizar si viene como porcentaje mayor a 1
    if (valor > 1) valor = valor / 100;

    final porcentaje = (valor * 100).round();
    final color = valor >= 0.7
        ? AppTheme.success
        : valor >= 0.4
            ? AppTheme.warning
            : AppTheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: color, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Nivel de confianza',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '$porcentaje%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: valor,
              backgroundColor: AppTheme.gray200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
