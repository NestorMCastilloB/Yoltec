#!/usr/bin/env python3
"""
Microservicio FastAPI para la IA de Yoltec.
Corre en el contenedor 'ia' y es llamado por el backend Laravel via HTTP.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pickle
import json
import numpy as np
import os

app = FastAPI(title="Yoltec IA", version="1.0.0")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ─── Cargar modelo al arrancar (no por cada request) ───────────────────────
model = None
le = None
feature_names = []


def load_model():
    global model, le, feature_names
    model_path = os.path.join(BASE_DIR, 'model.pkl')
    le_path = os.path.join(BASE_DIR, 'label_encoder.pkl')
    feat_path = os.path.join(BASE_DIR, 'feature_names.json')

    if not os.path.exists(model_path) or not os.path.exists(le_path):
        raise RuntimeError("model.pkl o label_encoder.pkl no encontrados. Ejecuta train_model.py primero.")

    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    with open(le_path, 'rb') as f:
        le = pickle.load(f)
    if os.path.exists(feat_path):
        with open(feat_path) as f:
            feature_names = json.load(f)

    print(f"Modelo cargado. Enfermedades: {list(le.classes_)}")


@app.on_event("startup")
def startup():
    load_model()


# ─── Constantes ────────────────────────────────────────────────────────────
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


# ─── Helpers ───────────────────────────────────────────────────────────────
def respuesta_a_binario(respuesta: str) -> int:
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


def respuesta_a_severidad(respuesta: str) -> str:
    r = str(respuesta).lower()
    if any(x in r for x in ['severo', 'intenso', 'alta', 'alto']):
        return 'severo'
    if any(x in r for x in ['moderado', 'frecuente']):
        return 'moderado'
    if any(x in r for x in ['leve', 'sí', 'si']):
        return 'leve'
    return ''


def generar_recomendacion(diagnostico: str, confianza: float) -> str:
    if confianza >= 0.75:
        return f"Los síntomas sugieren con alta probabilidad {diagnostico}. Se recomienda atención médica prioritaria."
    elif confianza >= 0.50:
        return f"Los síntomas son compatibles con {diagnostico}. Se recomienda consulta médica para confirmar."
    elif confianza >= 0.30:
        return f"Los síntomas podrían estar relacionados con {diagnostico}. Consulta al médico si persisten."
    return "Los síntomas no son concluyentes. Se recomienda consulta médica para evaluación."


# ─── Schemas ───────────────────────────────────────────────────────────────
class PredictRequest(BaseModel):
    respuestas: dict


# ─── Endpoints ─────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": model is not None}


@app.post("/predict")
def predict(req: PredictRequest):
    if model is None:
        raise HTTPException(status_code=503, detail="Modelo no disponible")

    respuestas = req.respuestas
    X = np.array([respuesta_a_binario(respuestas.get(f, 'No')) for f in feature_names]).reshape(1, -1)

    probs = model.predict_proba(X)[0]
    top_indices = np.argsort(probs)[::-1][:3]

    posibles = [
        {'enfermedad': le.classes_[i], 'confianza': min(round(float(probs[i]), 3), 0.95)}
        for i in top_indices if probs[i] > 0.05
    ]

    sintomas_detectados = []
    for feat, label in FEATURE_LABELS.items():
        if respuesta_a_binario(respuestas.get(feat, 'No')) == 1:
            sev = respuesta_a_severidad(respuestas.get(feat, ''))
            sintomas_detectados.append(f"{label} ({sev})" if sev else label)

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
    return {
        'success': True,
        'diagnostico_principal': principal['enfermedad'],
        'confianza': principal['confianza'],
        'sintomas_detectados': sintomas_detectados,
        'posibles_enfermedades': posibles,
        'recomendacion': generar_recomendacion(principal['enfermedad'], principal['confianza']),
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
