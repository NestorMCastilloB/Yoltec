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
  final List<Map<String, dynamic>> _mensajes = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isChatLoading = false;
  bool _chatFinished = false;
  Map<String, dynamic>? _resultado;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarChat());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _iniciarChat() async {
    final token =
        Provider.of<AuthService>(context, listen: false).token ?? '';
    final service =
        Provider.of<PreEvaluacionService>(context, listen: false);

    // Si ya existe pre-evaluación, mostrar resultado
    final existente =
        await service.buscarPreEvaluacionDeCita(token, widget.citaId);
    if (existente != null && mounted) {
      setState(() => _resultado = existente);
      return;
    }

    // Mensaje inicial del asistente
    if (mounted) {
      setState(() {
        _mensajes.add({
          'role': 'assistant',
          'content':
              '¡Hola! Soy tu asistente médico de pre-evaluación. ¿Cuál es tu principal molestia o síntoma hoy?'
        });
      });
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _inputController.text.trim();
    if (texto.isEmpty || _isChatLoading) return;

    _inputController.clear();
    setState(() {
      _mensajes.add({'role': 'user', 'content': texto});
      _isChatLoading = true;
      _errorMsg = null;
    });
    _scrollToBottom();

    final token =
        Provider.of<AuthService>(context, listen: false).token ?? '';
    final service =
        Provider.of<PreEvaluacionService>(context, listen: false);

    try {
      final response = await service.enviarMensajeChat(
        token,
        widget.citaId,
        _mensajes,
      );

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _isChatLoading = false;
          _errorMsg = 'Sin respuesta del servidor.';
        });
        return;
      }

      setState(() {
        _isChatLoading = false;
        _mensajes
            .add({'role': 'assistant', 'content': response['message'] ?? ''});

        if (response['finished'] == true && response['diagnostico'] != null) {
          _chatFinished = true;
          _resultado = response['diagnostico'] as Map<String, dynamic>;
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChatLoading = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-evaluación IA'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _resultado != null ? _buildResultado(_resultado!) : _buildChat(),
    );
  }

  // ─── Chat ──────────────────────────────────────────────────────────────────

  Widget _buildChat() {
    return Column(
      children: [
        // Lista de mensajes
        Expanded(
          child: _mensajes.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _mensajes.length + (_isChatLoading ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_isChatLoading && i == _mensajes.length) {
                      return _buildTypingIndicator();
                    }
                    final msg = _mensajes[i];
                    return _buildBubble(
                      msg['content'] as String,
                      msg['role'] == 'user',
                    );
                  },
                ),
        ),

        // Error
        if (_errorMsg != null)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '⚠️ $_errorMsg',
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13),
            ),
          ),

        // Input
        _buildInputArea(),
      ],
    );
  }

  Widget _buildBubble(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const Text('🤖', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.gray900,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 6),
            const Text('👤', style: TextStyle(fontSize: 20)),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 4,
                    offset: const Offset(0, 1))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _TypingDot(delay: Duration(milliseconds: i * 200)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                enabled: !_isChatLoading,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _enviarMensaje(),
                decoration: InputDecoration(
                  hintText: 'Escribe tu respuesta...',
                  hintStyle: TextStyle(color: AppTheme.gray400),
                  filled: true,
                  fillColor: AppTheme.gray100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isChatLoading
                ? const SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                        child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primaryColor),
                    )),
                  )
                : Material(
                    color: AppTheme.primaryColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _enviarMensaje,
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ─── Resultado ─────────────────────────────────────────────────────────────

  Widget _buildResultado(Map<String, dynamic> resultado) {
    final ia = resultado['resultado_ia'] as Map<String, dynamic>?;
    final diagnostico = (ia?['diagnostico_principal'] as String?) ??
        resultado['diagnostico_principal'] as String? ??
        resultado['diagnostico_sugerido'] as String? ??
        'Sin diagnóstico';

    dynamic rawConfianza = ia?['confianza'] ?? resultado['confianza'];
    double confianza = 0.0;
    if (rawConfianza is double) {
      confianza = rawConfianza;
    } else if (rawConfianza is int) {
      confianza = rawConfianza.toDouble();
    } else {
      confianza = double.tryParse(rawConfianza?.toString() ?? '') ?? 0.0;
    }
    if (confianza > 1) confianza = confianza / 100;

    final posibles =
        (ia?['posibles_enfermedades'] ?? resultado['posibles_enfermedades'])
                as List<dynamic>? ??
            [];
    final recomendacion = (ia?['recomendacion'] as String?) ??
        resultado['recomendacion'] as String? ??
        resultado['recomendaciones'] as String? ??
        '';

    final porcentaje = (confianza * 100).round();
    final color = confianza >= 0.7
        ? AppTheme.success
        : confianza >= 0.4
            ? AppTheme.warning
            : AppTheme.error;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppTheme.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: AppTheme.primaryColor, size: 60),
                  ),
                  const SizedBox(height: 12),
                  const Text('Pre-evaluación completada',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray900)),
                  const SizedBox(height: 6),
                  const Text(
                    'El médico revisará tu evaluación antes de la consulta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.gray600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Diagnóstico
            _resultCard(
              icon: Icons.medical_information_outlined,
              title: 'Diagnóstico preliminar',
              content: diagnostico,
              color: AppTheme.primaryColor,
            ),

            const SizedBox(height: 12),

            // Confianza
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.analytics_outlined, color: color, size: 20),
                      const SizedBox(width: 8),
                      const Text('Nivel de confianza',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('$porcentaje%',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ]),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: confianza,
                      backgroundColor: AppTheme.gray200,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),

            if (posibles.length > 1) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: const [
                        Icon(Icons.list_alt,
                            color: AppTheme.info, size: 20),
                        SizedBox(width: 8),
                        Text('Otras posibilidades',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 10),
                      ...posibles.skip(1).take(3).map((e) {
                        final map = e as Map<String, dynamic>;
                        final c = double.tryParse(
                                map['confianza']?.toString() ?? '') ??
                            0.0;
                        final pct = (c > 1 ? c : c * 100).round();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                              '• ${map['enfermedad']} ($pct%)',
                              style: const TextStyle(fontSize: 14)),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],

            if (recomendacion.isNotEmpty) ...[
              const SizedBox(height: 12),
              _resultCard(
                icon: Icons.tips_and_updates_outlined,
                title: 'Recomendación',
                content: recomendacion,
                color: AppTheme.warning,
              ),
            ],

            const SizedBox(height: 24),
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

  Widget _resultCard({
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
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray800)),
            ]),
            const SizedBox(height: 10),
            Text(content,
                style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.gray700,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}

/// Punto animado para indicador de escritura
class _TypingDot extends StatefulWidget {
  final Duration delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1300), vsync: this)
      ..repeat();
    _anim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.4), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppTheme.gray400.withOpacity(_anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
