#!/usr/bin/env python3
"""
Microservicio FastAPI para la IA de Yoltec.
Corre en el contenedor 'ia' y es llamado por el backend Laravel via HTTP.
"""

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator
from pydantic import Field
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import pickle
import json
import re
import logging
import numpy as np
import os
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("yoltec-ia")

limiter = Limiter(key_func=get_remote_address)
app = FastAPI(title="Yoltec IA", version="2.0.0")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:4200",
        "http://127.0.0.1:4200",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "https://frontend-nu-weld-77.vercel.app",
        "https://yoltec-backend.onrender.com",
    ],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "Accept"],
    allow_credentials=True,
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ─── Configuración Groq LLM ──────────────────────────────────────────────────
GROQ_API_KEY = os.getenv('GROQ_API_KEY', '')
GROQ_MODEL = os.getenv('GROQ_MODEL', 'llama-3.1-8b-instant')

groq_client = Groq(api_key=GROQ_API_KEY)

print(f"LLM Provider: GROQ (modelo: {GROQ_MODEL})")

SYSTEM_PROMPT = """Eres un asistente médico de pre-evaluación en una clínica universitaria en Ciudad Valles, San Luis Potosí, México (región Huasteca Potosina). Entrevistas al estudiante sobre sus síntomas antes de su consulta con el médico.

INSTRUCCIONES:
- Habla en español, de forma empática y profesional
- Haz UNA sola pregunta a la vez
- Comienza preguntando por el síntoma o malestar principal
- En las siguientes preguntas indaga: duración, intensidad, síntomas adicionales
- Después de 3 a 5 respuestas del paciente, concluye la entrevista

LISTA DE SÍNTOMAS RECONOCIDOS (usa exactamente estos identificadores en el JSON):
fiebre, tos, tos_seca, dolor_garganta, congestion_nasal, estornudos, dolor_cabeza,
dolor_cuerpo, cansancio, nauseas, vomito, diarrea, dolor_abdominal, perdida_apetito,
perdida_olfato, erupcion_piel, picazon, ojos_rojos, lagrimeo, dolor_orinar,
frecuencia_orinar, mareos, palpitaciones, sensibilidad_luz, dolor_articulaciones,
sudoracion, escalofrios, dolor_espalda, dificultad_respirar, fiebre_alta,
sangre_orina, orina_turbia, confusion, rigidez_cuello

CUÁNDO TERMINAR:
Cuando tengas suficiente información (mínimo 3 respuestas del paciente), escribe un mensaje de cierre empático y luego agrega exactamente:

DIAGNÓSTICO_FINAL:{"sintomas_identificados":["fiebre","dolor_cabeza"],"recomendacion":"Texto corto de recomendación."}

REGLAS DEL JSON:
- El marcador DIAGNÓSTICO_FINAL: debe ir pegado al { sin espacios ni saltos de línea
- El JSON debe estar en una sola línea sin saltos internos
- sintomas_identificados: SOLO usa identificadores exactos de la lista de arriba, en minúsculas con guion bajo
- recomendacion: una oración indicando si debe ir urgente o puede esperar consulta normal
- NO incluyas el marcador hasta tener al menos 3 respuestas del paciente
- NO intentes adivinar la enfermedad, el sistema médico la determinará automáticamente"""

# ─── Cargar modelo sklearn (fallback) ───────────────────────────────────────
model = None
le = None
feature_names = []


def load_model():
    global model, le, feature_names
    model_path = os.path.join(BASE_DIR, 'model.pkl')
    le_path = os.path.join(BASE_DIR, 'label_encoder.pkl')
    feat_path = os.path.join(BASE_DIR, 'feature_names.json')

    if not os.path.exists(model_path) or not os.path.exists(le_path):
        print("AVISO: model.pkl no encontrado. Ejecuta train_model.py para habilitar el endpoint /predict.")
        return

    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    with open(le_path, 'rb') as f:
        le = pickle.load(f)
    if os.path.exists(feat_path):
        with open(feat_path) as f:
            feature_names = json.load(f)

    print(f"Modelo sklearn cargado. Enfermedades: {list(le.classes_)}")


@app.on_event("startup")
def startup():
    load_model()


# ─── Constantes (sklearn) ────────────────────────────────────────────────────
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


# ─── Schemas ─────────────────────────────────────────────────────────────────
class PredictRequest(BaseModel):
    respuestas: dict = Field(..., max_length=50)


class ChatMessage(BaseModel):
    role: str = Field(..., max_length=20)
    content: str = Field(..., max_length=5000)

    @field_validator('role')
    @classmethod
    def validate_role(cls, v: str) -> str:
        if v not in ('user', 'assistant'):
            raise ValueError('role debe ser "user" o "assistant"')
        return v


class ChatRequest(BaseModel):
    messages: list[ChatMessage] = Field(..., max_length=50)


# ─── Endpoints ───────────────────────────────────────────────────────────────
@app.get("/health")
def health():
    llm_ok = False
    try:
        groq_client.models.list()
        llm_ok = True
    except Exception:
        pass

    status = "ok" if model is not None else "degraded"
    code = 200 if model is not None else 503

    from fastapi.responses import JSONResponse
    return JSONResponse(
        status_code=code,
        content={
            "status": status,
            "model_sklearn_loaded": model is not None,
            "llm_provider": "groq",
            "llm_model": GROQ_MODEL,
            "llm_available": llm_ok,
        }
    )


@app.post("/chat")
@limiter.limit("10/minute")
def chat(request: Request, req: ChatRequest):
    """
    Chat conversacional con Groq para pre-evaluación de síntomas.
    Devuelve la respuesta del asistente y, cuando hay suficiente info,
    un diagnóstico preliminar estructurado.
    """
    try:
        messages_payload = [
            {"role": m.role, "content": m.content}
            for m in req.messages
        ]

        response = groq_client.chat.completions.create(
            model=GROQ_MODEL,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                *messages_payload
            ],
            temperature=0.7,
            max_tokens=600,
        )
        assistant_message = response.choices[0].message.content

        if "DIAGNÓSTICO_FINAL:" in assistant_message:
            parts = assistant_message.split("DIAGNÓSTICO_FINAL:", 1)
            mensaje_limpio = parts[0].strip()
            json_str = parts[1].strip()

            # Limpiar markdown si el modelo lo agrega
            json_str = re.sub(r'```json\s*|\s*```', '', json_str).strip()

            # Extraer solo el primer objeto JSON
            brace_count = 0
            json_end = 0
            for i, char in enumerate(json_str):
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        json_end = i + 1
                        break

            datos_llm = {}
            try:
                datos_llm = json.loads(json_str[:json_end] if json_end > 0 else json_str)
            except json.JSONDecodeError:
                pass

            sintomas_identificados = datos_llm.get("sintomas_identificados", [])
            recomendacion_llm = datos_llm.get("recomendacion", "Se recomienda consultar al médico para confirmar.")

            # ── Clasificar con sklearn usando los síntomas que extrajo el LLM ──
            if model is not None and feature_names and sintomas_identificados:
                X = np.array([
                    1 if feat in sintomas_identificados else 0
                    for feat in feature_names
                ]).reshape(1, -1)

                probs = model.predict_proba(X)[0]
                top_indices = np.argsort(probs)[::-1][:3]

                posibles = [
                    {
                        "enfermedad": le.classes_[i],
                        "confianza": round(float(probs[i]), 3)
                    }
                    for i in top_indices if probs[i] > 0.05
                ]

                if posibles:
                    principal = posibles[0]
                    diagnostico = {
                        "diagnostico_principal": principal["enfermedad"],
                        "confianza": principal["confianza"],
                        "sintomas_detectados": sintomas_identificados,
                        "posibles_enfermedades": posibles,
                        "recomendacion": generar_recomendacion(principal["enfermedad"], principal["confianza"])
                    }
                else:
                    diagnostico = {
                        "diagnostico_principal": "Sin diagnóstico claro",
                        "confianza": 0.0,
                        "sintomas_detectados": sintomas_identificados,
                        "posibles_enfermedades": [],
                        "recomendacion": recomendacion_llm
                    }
            else:
                # Fallback: sklearn no disponible, usar lo que dijo el LLM
                diagnostico = {
                    "diagnostico_principal": "Evaluación preliminar",
                    "confianza": 0.5,
                    "sintomas_detectados": sintomas_identificados,
                    "posibles_enfermedades": [],
                    "recomendacion": recomendacion_llm
                }

            return {
                "message": mensaje_limpio or "He recopilado suficiente información. Aquí está tu pre-evaluación:",
                "finished": True,
                "diagnostico": diagnostico
            }

        return {
            "message": assistant_message,
            "finished": False,
            "diagnostico": None
        }

    except Exception as e:
        logger.error(f"Error Groq API: {e}")
        raise HTTPException(status_code=502, detail="Error al procesar la solicitud con el servicio de IA. Intenta de nuevo.")


@app.post("/predict")
@limiter.limit("10/minute")
def predict(request: Request, req: PredictRequest):
    """Endpoint legacy con modelo sklearn (formulario de síntomas)."""
    if model is None:
        raise HTTPException(status_code=503, detail="Modelo sklearn no disponible. Ejecuta train_model.py primero.")

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
    port = int(os.environ.get("PORT", 5000))
    uvicorn.run(app, host="0.0.0.0", port=port)
