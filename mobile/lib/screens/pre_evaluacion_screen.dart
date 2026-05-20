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
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = false;
  Map<String, dynamic>? _resultado;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarChat());
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _iniciarChat() async {
    final token =
        Provider.of<AuthService>(context, listen: false).token ?? '';
    final service =
        Provider.of<PreEvaluacionService>(context, listen: false);

    final existente =
        await service.buscarPreEvaluacionDeCita(token, widget.citaId);
    if (existente != null && mounted) {
      setState(() => _resultado = existente);
      return;
    }

    if (mounted) {
      setState(() {
        _mensajes.add({
          'role': 'assistant',
          'content':
              'Hola, soy tu asistente médico. ¿Qué síntomas presentas hoy?'
        });
      });
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _inputCtrl.text.trim();
    if (texto.isEmpty || _isLoading) return;

    _inputCtrl.clear();
    setState(() {
      _mensajes.add({'role': 'user', 'content': texto});
      _isLoading = true;
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
          _isLoading = false;
          _errorMsg = 'Sin respuesta del servidor.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _mensajes.add(
            {'role': 'assistant', 'content': response['message'] ?? ''});
        if (response['finished'] == true && response['diagnostico'] != null) {
          _resultado = response['diagnostico'] as Map<String, dynamic>;
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.bgDark : AppTheme.bg;

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pre-evaluación IA',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2),
              Text(
                'No reemplaza una consulta médica',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _resultado != null ? _buildResultado(_resultado!) : _buildChat(),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: _mensajes.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryColor),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  itemCount: _mensajes.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_isLoading && i == _mensajes.length) {
                      return const _TypingBubble();
                    }
                    final msg = _mensajes[i];
                    return _Bubble(
                      content: msg['content'] as String,
                      isUser: msg['role'] == 'user',
                    );
                  },
                ),
        ),
        if (_errorMsg != null)
          Container(
            width: double.infinity,
            color: AppTheme.errorSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _errorMsg!,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
        _InputArea(
          controller: _inputCtrl,
          enabled: !_isLoading,
          onEnviar: _enviarMensaje,
        ),
      ],
    );
  }

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

    final lista = <Map<String, dynamic>>[
      {'enfermedad': diagnostico, 'confianza': confianza},
      ...posibles.skip(1).take(3).map((e) {
        final map = e as Map<String, dynamic>;
        var c = double.tryParse(map['confianza']?.toString() ?? '') ?? 0.0;
        if (c > 1) c = c / 100;
        return {'enfermedad': map['enfermedad'] ?? '', 'confianza': c};
      }),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ResultCard(diagnosticos: lista),
            if (recomendacion.isNotEmpty) ...[
              const SizedBox(height: 12),
              _RecomendacionCard(texto: recomendacion),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Volver al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const _Bubble({required this.content, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiBg = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final aiBorder = isDark ? AppTheme.borderDark : AppTheme.border;
    final aiText = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final meBg = isDark
        ? AppTheme.primaryColor.withValues(alpha: 0.18)
        : AppTheme.primarySurface;
    final meText = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.75 : 0.78),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _AvatarIA(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? meBg : aiBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: aiBorder, width: 1),
                    boxShadow: isUser
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? meText : aiText,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarIA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppTheme.iaSurface,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        size: 16,
        color: AppTheme.iaColor,
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiBg = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final aiBorder = isDark ? AppTheme.borderDark : AppTheme.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _AvatarIA(),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: aiBg,
                border: Border.all(color: aiBorder, width: 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => _Dot(delay: Duration(milliseconds: i * 200)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Duration delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat();
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
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: AppTheme.textSubtle.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onEnviar;

  const _InputArea({
    required this.controller,
    required this.enabled,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final border = isDark ? AppTheme.borderDark : AppTheme.border;
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : AppTheme.borderSoft;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onEnviar(),
                decoration: InputDecoration(
                  hintText: 'Escribe tus síntomas...',
                  filled: true,
                  fillColor: fill,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: AppTheme.primaryColor,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enabled ? onEnviar : null,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: enabled
                      ? const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18)
                      : const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final List<Map<String, dynamic>> diagnosticos;
  const _ResultCard({required this.diagnosticos});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surface;
    final textMain = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary;
    final divider = isDark ? AppTheme.borderDark : AppTheme.borderSoft;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: AppTheme.primaryColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Posibles diagnósticos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: textMain,
            ),
          ),
          const SizedBox(height: 12),
          ...diagnosticos.map((d) {
            final nombre = d['enfermedad']?.toString() ?? '';
            final conf = (d['confianza'] as double?) ?? 0.0;
            final pct = (conf * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: TextStyle(fontSize: 13, color: textMain),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: conf,
                      backgroundColor: AppTheme.primarySurface,
                      valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Divider(height: 1, color: divider),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.warningSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Solo orientativo · El doctor confirmará el diagnóstico',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecomendacionCard extends StatelessWidget {
  final String texto;
  const _RecomendacionCard({required this.texto});

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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: AppTheme.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Recomendación',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
