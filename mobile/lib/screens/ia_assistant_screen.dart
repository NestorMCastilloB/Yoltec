import 'package:flutter/material.dart';
import 'package:yoltec_mobile/ia/sistema_experto.dart';

class IAAssistantScreen extends StatefulWidget {
  const IAAssistantScreen({super.key});

  @override
  State<IAAssistantScreen> createState() => _IAAssistantScreenState();
}

class _IAAssistantScreenState extends State<IAAssistantScreen> {
  final SistemaExpertoMedico _sistemaExperto = SistemaExpertoMedico();
  List<String> _sintomasSeleccionados = [];
  final Map<String, dynamic> _datosAdicionales = {};
  List<ResultadoDiagnostico> _resultados = [];
  bool _analizando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Asistente Médico IA'),
      ),
      body: Column(
        children: [
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este asistente es solo orientativo. No reemplaza la consulta médica.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selección de síntomas
          Expanded(
            flex: 2,
            child: _buildSintomasSection(),
          ),

          // Botón de análisis
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sintomasSeleccionados.isEmpty || _analizando
                    ? null
                    : _analizarSintomas,
                icon: _analizando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.healing),
                label: Text(_analizando ? 'Analizando...' : 'Analizar Síntomas'),
              ),
            ),
          ),

          // Resultados
          Expanded(
            flex: 3,
            child: _resultados.isEmpty
                ? _buildEmptyState()
                : _buildResultados(),
          ),
        ],
      ),
    );
  }

  Widget _buildSintomasSection() {
    final sintomasPorCategoria = _sistemaExperto.getSintomasPorCategoria();

    return DefaultTabController(
      length: sintomasPorCategoria.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: sintomasPorCategoria.keys
                .map((categoria) => Tab(text: categoria))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              children: sintomasPorCategoria.entries.map((entry) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((sintoma) {
                      final isSelected =
                          _sintomasSeleccionados.contains(sintoma.id);
                      return FilterChip(
                        label: Text(sintoma.nombre),
                        subtitle: Text(
                          sintoma.descripcion,
                          style: const TextStyle(fontSize: 10),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _sintomasSeleccionados.add(sintoma.id);
                            } else {
                              _sintomasSeleccionados.remove(sintoma.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona tus síntomas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'El asistente analizará tus síntomas\ny te dará orientación médica.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.analytics, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Resultados del Análisis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _resultados.length,
            itemBuilder: (context, index) {
              final resultado = _resultados[index];
              return _buildResultadoCard(resultado, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultadoCard(ResultadoDiagnostico resultado, int index) {
    final color = _getColorForUrgency(resultado.diagnostico.nivelUrgencia);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          resultado.diagnostico.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: resultado.probabilidad,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 4),
            Text(
              'Probabilidad: ${(resultado.probabilidad * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descripción:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(resultado.diagnostico.descripcion),
                const SizedBox(height: 16),
                
                Text(
                  'Síntomas detectados:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: resultado.sintomasDetectados.map((sintoma) {
                    final sintomaData = _sistemaExperto.getSintomasDisponibles()
                        .firstWhere((s) => s.id == sintoma);
                    return Chip(
                      label: Text(
                        sintomaData.nombre,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: color.withOpacity(0.1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Recomendaciones:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                ...resultado.recomendaciones.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForUrgency(String nivelUrgencia) {
    switch (nivelUrgencia) {
      case 'emergencia':
        return Colors.red;
      case 'alta':
        return Colors.orange;
      case 'media':
        return Colors.yellow[700]!;
      case 'baja':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Future<void> _analizarSintomas() async {
    setState(() {
      _analizando = true;
    });

    // Simular procesamiento
    await Future.delayed(const Duration(seconds: 1));

    final resultados = _sistemaExperto.analizarSintomas(
      _sintomasSeleccionados,
      datosAdicionales: _datosAdicionales,
    );

    setState(() {
      _resultados = resultados;
      _analizando = false;
    });
  }
}
