#!/usr/bin/env python3
"""
Servicio de IA para pre-evaluación médica de Yoltec.
Usa modelo Gradient Boosting entrenado con dataset real + datos sintéticos.
Lee JSON de stdin, escribe JSON a stdout.
"""

import sys
import json
import os
import pickle
import numpy as np

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

FEATURE_NAMES = [
    'fiebre', 'tos', 'tos_seca', 'dolor_garganta', 'congestion_nasal',
    'estornudos', 'dolor_cabeza', 'dolor_cuerpo', 'cansancio', 'nauseas',
    'vomito', 'diarrea', 'dolor_abdominal', 'perdida_apetito', 'perdida_olfato',
    'erupcion_piel', 'picazon', 'ojos_rojos', 'lagrimeo', 'dolor_orinar',
    'frecuencia_orinar', 'mareos', 'palpitaciones', 'sensibilidad_luz',
    'dolor_articulaciones', 'sudoracion', 'escalofrios', 'dolor_espalda',
    'dificultad_respirar', 'fiebre_alta', 'sangre_orina', 'orina_turbia',
    'confusion', 'rigidez_cuello',
]

FEATURE_LABELS = {
    'fiebre': 'Fiebre', 'tos': 'Tos', 'tos_seca': 'Tos seca',
    'dolor_garganta': 'Dolor de garganta', 'congestion_nasal': 'Congestión nasal',
    'estornudos': 'Estornudos frecuentes', 'dolor_cabeza': 'Dolor de cabeza',
    'dolor_cuerpo': 'Dolor en el cuerpo', 'cansancio': 'Cansancio / fatiga',
    'nauseas': 'Náuseas', 'vomito': 'Vómito', 'diarrea': 'Diarrea',
    'dolor_abdominal': 'Dolor abdominal', 'perdida_apetito': 'Pérdida de apetito',
    'perdida_olfato': 'Pérdida del olfato o gusto', 'erupcion_piel': 'Erupción en la piel',
    'picazon': 'Picazón', 'ojos_rojos': 'Ojos rojos', 'lagrimeo': 'Lagrimeo excesivo',
    'dolor_orinar': 'Dolor al orinar', 'frecuencia_orinar': 'Frecuencia urinaria aumentada',
    'mareos': 'Mareos', 'palpitaciones': 'Palpitaciones', 'sensibilidad_luz': 'Sensibilidad a la luz',
    'dolor_articulaciones': 'Dolor en articulaciones', 'sudoracion': 'Sudoración excesiva',
    'escalofrios': 'Escalofríos', 'dolor_espalda': 'Dolor de espalda',
    'dificultad_respirar': 'Dificultad para respirar', 'fiebre_alta': 'Fiebre alta',
    'sangre_orina': 'Sangre en la orina', 'orina_turbia': 'Orina turbia',
    'confusion': 'Confusión o desorientación', 'rigidez_cuello': 'Rigidez de cuello',
}

PALABRAS_POSITIVAS = ['sí', 'si', 'leve', 'moderado', 'severo', 'alta', 'intenso', 'frecuente', 'yes']
PALABRAS_NEGATIVAS = ['no', 'ninguno', 'ninguna', 'ausente', 'nada']


def _load_model():
    model_path = os.path.join(BASE_DIR, 'model.pkl')
    le_path = os.path.join(BASE_DIR, 'label_encoder.pkl')
    feat_path = os.path.join(BASE_DIR, 'feature_names.json')
    if not all(os.path.exists(p) for p in [model_path, le_path]):
        return None, None, None
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    with open(le_path, 'rb') as f:
        le = pickle.load(f)
    feature_names = FEATURE_NAMES
    if os.path.exists(feat_path):
        with open(feat_path) as f:
            feature_names = json.load(f)
    return model, le, feature_names


def respuesta_a_binario(respuesta):
    if not respuesta:
        return 0
    r = str(respuesta).lower().strip()
    for neg in PALABRAS_NEGATIVAS:
        if r.startswith(neg):
            return 0
    for pos in PALABRAS_POSITIVAS:
        if pos in r:
            return 1
    return 0


def respuesta_a_severidad(respuesta):
    if not respuesta:
        return ''
    r = str(respuesta).lower()
    if 'severo' in r or 'intenso' in r or 'alta' in r or 'alto' in r:
        return 'severo'
    if 'moderado' in r or 'frecuente' in r:
        return 'moderado'
    if 'leve' in r or 'sí' in r or 'si' in r:
        return 'leve'
    return ''


def construir_vector(respuestas, feature_names):
    return np.array([respuesta_a_binario(respuestas.get(f, 'No')) for f in feature_names]).reshape(1, -1)


def obtener_sintomas_detectados(respuestas):
    detectados = []
    for feat, label in FEATURE_LABELS.items():
        respuesta = respuestas.get(feat, 'No')
        if respuesta_a_binario(respuesta) == 1:
            sev = respuesta_a_severidad(respuesta)
            detectados.append(f"{label} ({sev})" if sev else label)
    return detectados


def generar_recomendacion(diagnostico, confianza):
    if confianza >= 0.75:
        return f"Los síntomas sugieren con alta probabilidad {diagnostico}. Se recomienda atención médica prioritaria. Este análisis es solo orientativo."
    elif confianza >= 0.50:
        return f"Los síntomas son compatibles con {diagnostico}. Se recomienda consulta médica para confirmar el diagnóstico."
    elif confianza >= 0.30:
        return f"Los síntomas podrían estar relacionados con {diagnostico}. Monitorea la evolución y consulta al médico si persisten."
    else:
        return "Los síntomas no son concluyentes. Se recomienda consulta médica para evaluación más detallada."


def predecir(respuestas):
    model, le, feature_names = _load_model()
    if model is None:
        return {'success': False, 'error': 'Modelo no encontrado. Ejecuta train_model.py primero.'}

    X = construir_vector(respuestas, feature_names)
    probs = model.predict_proba(X)[0]
    top_indices = np.argsort(probs)[::-1][:3]

    posibles = [
        {'enfermedad': le.classes_[i], 'confianza': min(round(float(probs[i]), 3), 0.95)}
        for i in top_indices if probs[i] > 0.05
    ]

    if not posibles:
        return {
            'success': True,
            'diagnostico_principal': 'Sin diagnóstico claro',
            'confianza': 0.0,
            'sintomas_detectados': obtener_sintomas_detectados(respuestas),
            'posibles_enfermedades': [],
            'recomendacion': 'Los síntomas no son concluyentes. Se recomienda consulta médica.',
        }

    principal = posibles[0]
    return {
        'success': True,
        'diagnostico_principal': principal['enfermedad'],
        'confianza': principal['confianza'],
        'sintomas_detectados': obtener_sintomas_detectados(respuestas),
        'posibles_enfermedades': posibles,
        'recomendacion': generar_recomendacion(principal['enfermedad'], principal['confianza']),
    }


def main():
    try:
        data = json.loads(sys.stdin.read().strip())
        respuestas = data.get('respuestas', {})
        if not respuestas:
            print(json.dumps({'error': 'No se proporcionaron respuestas', 'success': False}))
            sys.exit(1)
        print(json.dumps(predecir(respuestas), ensure_ascii=False))
    except json.JSONDecodeError as e:
        print(json.dumps({'error': f'JSON inválido: {str(e)}', 'success': False}))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({'error': f'Error: {str(e)}', 'success': False}))
        sys.exit(1)


if __name__ == '__main__':
    main()
