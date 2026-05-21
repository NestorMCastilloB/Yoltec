#!/usr/bin/env python3
"""
Pre-evaluación médica de Yoltec (modo CLI stdin/stdout).
Usa modelo HistGradientBoosting entrenado con dataset sintético expandido.
"""

import sys
import json
import os
import pickle
import numpy as np

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

FEATURE_NAMES = [
    'fiebre', 'fiebre_alta', 'tos', 'tos_seca', 'dolor_garganta',
    'congestion_nasal', 'estornudos', 'dificultad_respirar',
    'dolor_cabeza', 'mareos', 'confusion', 'sensibilidad_luz',
    'rigidez_cuello', 'perdida_balance', 'hormigueo', 'desmayo',
    'dolor_cuerpo', 'dolor_articulaciones', 'dolor_espalda',
    'dolor_pecho', 'debilidad_muscular',
    'nauseas', 'vomito', 'diarrea', 'dolor_abdominal',
    'perdida_apetito', 'ardor_estomago', 'estrenimiento',
    'dolor_orinar', 'frecuencia_orinar', 'sangre_orina', 'orina_turbia',
    'dolor_menstrual', 'sangrado_anormal',
    'erupcion_piel', 'picazon', 'hinchazon', 'enrojecimiento',
    'ojos_rojos', 'lagrimeo', 'vision_borrosa', 'dolor_oido', 'secrecion_oido',
    'cansancio', 'sudoracion', 'escalofrios', 'perdida_olfato',
    'palpitaciones', 'sequedad_boca', 'deshidratacion',
    'ansiedad', 'insomnio', 'irritabilidad', 'tristeza_persistente',
    'sangrado_severo', 'golpe_reciente', 'quemadura',
]

FEATURE_LABELS = {
    'fiebre': 'Fiebre', 'fiebre_alta': 'Fiebre alta',
    'tos': 'Tos', 'tos_seca': 'Tos seca',
    'dolor_garganta': 'Dolor de garganta', 'congestion_nasal': 'Congestión nasal',
    'estornudos': 'Estornudos frecuentes', 'dificultad_respirar': 'Dificultad para respirar',
    'dolor_cabeza': 'Dolor de cabeza', 'mareos': 'Mareos',
    'confusion': 'Confusión o desorientación', 'sensibilidad_luz': 'Sensibilidad a la luz',
    'rigidez_cuello': 'Rigidez de cuello', 'perdida_balance': 'Pérdida de equilibrio',
    'hormigueo': 'Hormigueo en extremidades', 'desmayo': 'Desmayo o pérdida de conciencia',
    'dolor_cuerpo': 'Dolor en el cuerpo', 'dolor_articulaciones': 'Dolor en articulaciones',
    'dolor_espalda': 'Dolor de espalda', 'dolor_pecho': 'Dolor en el pecho',
    'debilidad_muscular': 'Debilidad muscular',
    'nauseas': 'Náuseas', 'vomito': 'Vómito', 'diarrea': 'Diarrea',
    'dolor_abdominal': 'Dolor abdominal', 'perdida_apetito': 'Pérdida de apetito',
    'ardor_estomago': 'Ardor estomacal / acidez', 'estrenimiento': 'Estreñimiento',
    'dolor_orinar': 'Dolor al orinar', 'frecuencia_orinar': 'Frecuencia urinaria aumentada',
    'sangre_orina': 'Sangre en la orina', 'orina_turbia': 'Orina turbia',
    'dolor_menstrual': 'Dolor menstrual', 'sangrado_anormal': 'Sangrado anormal',
    'erupcion_piel': 'Erupción en la piel', 'picazon': 'Picazón',
    'hinchazon': 'Hinchazón', 'enrojecimiento': 'Enrojecimiento de piel',
    'ojos_rojos': 'Ojos rojos', 'lagrimeo': 'Lagrimeo excesivo',
    'vision_borrosa': 'Visión borrosa', 'dolor_oido': 'Dolor de oído',
    'secrecion_oido': 'Secreción de oído',
    'cansancio': 'Cansancio / fatiga', 'sudoracion': 'Sudoración excesiva',
    'escalofrios': 'Escalofríos', 'perdida_olfato': 'Pérdida del olfato o gusto',
    'palpitaciones': 'Palpitaciones', 'sequedad_boca': 'Sequedad de boca',
    'deshidratacion': 'Deshidratación',
    'ansiedad': 'Ansiedad', 'insomnio': 'Insomnio',
    'irritabilidad': 'Irritabilidad', 'tristeza_persistente': 'Tristeza persistente',
    'sangrado_severo': 'Sangrado severo', 'golpe_reciente': 'Golpe o trauma reciente',
    'quemadura': 'Quemadura',
}

PALABRAS_POSITIVAS = ['sí', 'si', 'leve', 'moderado', 'severo', 'alta', 'intenso', 'frecuente', 'yes']
PALABRAS_NEGATIVAS = ['no', 'ninguno', 'ninguna', 'ausente', 'nada']

# Confianza mínima por clase: con ~50 clases, la prob top suele ser <0.4 incluso en casos claros
CONFIANZA_MIN_DIAGNOSTICO = 0.18
PROB_MIN_INCLUIR_POSIBLE = 0.04


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
    # Clases especiales que NO son enfermedad sino redirección
    if diagnostico == 'Trauma o Lesión Física':
        return ("Los síntomas sugieren una lesión física (golpe, caída, quemadura). "
                "Esto no es una enfermedad infecciosa: acude a atención médica presencial "
                "o, si es severo, a urgencias. La IA no evalúa traumatismos.")
    if diagnostico == 'Sin Patrón Claro':
        return ("Los síntomas reportados no corresponden a un cuadro clínico claro. "
                "Se recomienda consulta médica para una valoración personalizada.")
    if confianza < CONFIANZA_MIN_DIAGNOSTICO:
        return ("Los síntomas no son lo suficientemente específicos para una orientación clara. "
                "Se recomienda consulta médica para evaluación detallada.")
    if confianza >= 0.55:
        return (f"Los síntomas sugieren con alta probabilidad {diagnostico}. "
                "Se recomienda atención médica prioritaria. Este análisis es solo orientativo.")
    if confianza >= 0.35:
        return (f"Los síntomas son compatibles con {diagnostico}. "
                "Se recomienda consulta médica para confirmar el diagnóstico.")
    return (f"Los síntomas podrían estar relacionados con {diagnostico}. "
            "Monitorea la evolución y consulta al médico si persisten.")


def predecir(respuestas):
    model, le, feature_names = _load_model()
    if model is None:
        return {'success': False, 'error': 'Modelo no encontrado. Ejecuta train_model_light.py primero.'}

    X = construir_vector(respuestas, feature_names)
    probs = model.predict_proba(X)[0]
    top_indices = np.argsort(probs)[::-1][:3]

    posibles = [
        {'enfermedad': le.classes_[i], 'confianza': min(round(float(probs[i]), 3), 0.95)}
        for i in top_indices if probs[i] > PROB_MIN_INCLUIR_POSIBLE
    ]

    sintomas_detectados = obtener_sintomas_detectados(respuestas)

    if not posibles:
        return {
            'success': True,
            'diagnostico_principal': 'Sin diagnóstico claro',
            'confianza': 0.0,
            'sintomas_detectados': sintomas_detectados,
            'posibles_enfermedades': [],
            'recomendacion': 'Los síntomas no son concluyentes. Se recomienda consulta médica.',
        }

    principal = posibles[0]

    # Si la confianza es muy baja, no exponemos un nombre de enfermedad: degradamos
    if principal['confianza'] < CONFIANZA_MIN_DIAGNOSTICO and principal['enfermedad'] not in ('Trauma o Lesión Física', 'Sin Patrón Claro'):
        return {
            'success': True,
            'diagnostico_principal': 'Sin diagnóstico claro',
            'confianza': principal['confianza'],
            'sintomas_detectados': sintomas_detectados,
            'posibles_enfermedades': posibles,
            'recomendacion': generar_recomendacion('Sin diagnóstico', principal['confianza']),
        }

    return {
        'success': True,
        'diagnostico_principal': principal['enfermedad'],
        'confianza': principal['confianza'],
        'sintomas_detectados': sintomas_detectados,
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
