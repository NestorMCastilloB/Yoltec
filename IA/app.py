#!/usr/bin/env python3
"""
Microservicio FastAPI para la IA de Yoltec.
Corre en el contenedor 'ia' y es llamado por el backend Laravel via HTTP.
"""

from contextlib import asynccontextmanager
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

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("yoltec-ia")

limiter = Limiter(key_func=get_remote_address)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    load_model()
    yield


app = FastAPI(title="Yoltec IA", version="2.0.0", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:4200",
        "http://127.0.0.1:4200",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "https://yoltec.vercel.app",
        "https://frontend-nu-weld-77.vercel.app",
        "https://yoltec-backend.onrender.com",
    ],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "Accept"],
    allow_credentials=True,
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ─── Configuración Groq LLM ──────────────────────────────────────────────────
GROQ_API_KEY = os.getenv('GROQ_API_KEY', '').strip()
GROQ_MODEL = os.getenv('GROQ_MODEL', 'llama-3.1-8b-instant')

if not GROQ_API_KEY:
    raise RuntimeError(
        "GROQ_API_KEY no está definida. Configúrala en .env (local) o como variable "
        "de entorno en Render antes de iniciar el servicio."
    )

groq_client = Groq(api_key=GROQ_API_KEY)

logger.info("LLM Provider: GROQ (modelo: %s)", GROQ_MODEL)

SYSTEM_PROMPT = """Eres parte del equipo médico del consultorio universitario Yoltec, en Ciudad Valles, San Luis Potosí. Tu trabajo es platicar con el estudiante antes de su consulta para entender cómo se siente y qué síntomas tiene.

Habla en español, con un tono cercano y tranquilo. Eres amable pero directo — no adornes de más, no uses frases de manual. Imagina que eres un enfermero joven que lleva un rato en la clínica y sabe cómo hacer que el paciente se sienta cómodo.

CÓMO LLEVAR LA CONVERSACIÓN:
- Pregunta una cosa a la vez, sin bombardear
- Empieza por lo más importante: "¿Qué es lo que te trae hoy?" o algo natural
- Después profundiza: desde cuándo, qué tan fuerte, si hay algo más
- Con 3 a 5 respuestas ya tienes suficiente para cerrar

SÍNTOMAS QUE EL SISTEMA RECONOCE (usa estos identificadores exactos en el JSON final):
fiebre, fiebre_alta, tos, tos_seca, dolor_garganta, congestion_nasal, estornudos,
dificultad_respirar, dolor_cabeza, mareos, confusion, sensibilidad_luz, rigidez_cuello,
perdida_balance, hormigueo, desmayo, dolor_cuerpo, dolor_articulaciones, dolor_espalda,
dolor_pecho, debilidad_muscular, nauseas, vomito, diarrea, dolor_abdominal,
perdida_apetito, ardor_estomago, estrenimiento, dolor_orinar, frecuencia_orinar,
sangre_orina, orina_turbia, dolor_menstrual, sangrado_anormal, erupcion_piel, picazon,
hinchazon, enrojecimiento, ojos_rojos, lagrimeo, vision_borrosa, dolor_oido,
secrecion_oido, cansancio, sudoracion, escalofrios, perdida_olfato, palpitaciones,
sequedad_boca, deshidratacion, ansiedad, insomnio, irritabilidad, tristeza_persistente,
sangrado_severo, golpe_reciente, quemadura

PARA CERRAR:
Cuando ya tengas lo necesario (mínimo 3 respuestas), despídete de forma natural y agrega esto al final:

DIAGNÓSTICO_FINAL:{"sintomas_identificados":["fiebre","dolor_cabeza"],"recomendacion":"Texto corto de recomendación."}

REGLAS DEL JSON:
- DIAGNÓSTICO_FINAL: pegado al { sin espacios ni saltos de línea
- Todo el JSON en una sola línea
- sintomas_identificados: solo identificadores de la lista de arriba, en minúsculas con guion bajo
- recomendacion: algo breve — si debe ir urgente o puede esperar su consulta normal
- No pongas el marcador hasta tener al menos 3 respuestas del paciente
- No intentes adivinar la enfermedad, eso lo determina el sistema médico"""

# ─── Sanity check de emergencias / trauma ────────────────────────────────────
# Frases que indican lesión física, accidente o emergencia: NO pasamos por el clasificador.
EMERGENCIA_KEYWORDS = [
    'atropell', 'atropellaron', 'me chocaron', 'choque', 'accidente', 'auto',
    'camion', 'camión', 'moto', 'motocicleta', 'bicicleta',
    'me cai', 'me caí', 'me caigo', 'fractura', 'fracturé', 'fracture',
    'hueso roto', 'roto', 'dislocad', 'esguince',
    'apuñal', 'apunal', 'me cortaron', 'cuchillo', 'navaja', 'arma',
    'balazo', 'disparo', 'tiro',
    'quemadura grave', 'quemadura severa', 'me queme', 'me quemé',
    'incendio', 'fuego', 'electrocut', 'descarga eléctrica',
    'mucha sangre', 'sangro mucho', 'no para de sangrar', 'hemorragia',
    'intoxicacion', 'intoxicación', 'envenen', 'tome veneno',
    'suicid', 'me quiero matar', 'no quiero vivir',
    'sobredosis', 'overdose',
    'ahog', 'me ahogo', 'no respiro', 'asfixi',
    'mordedura', 'me mordio', 'me mordió', 'serpiente', 'perro me mordió',
    'convulsi', 'ataque',
    'inconsciente', 'no responde', 'desmay',
]

EMERGENCIA_MESSAGE = (
    "Lo que describes parece una emergencia o lesión física que requiere atención presencial "
    "inmediata. Yoltec es un sistema de pre-evaluación para malestares comunes, no un servicio "
    "de urgencias.\n\n"
    "• Si estás en peligro, llama al 911.\n"
    "• Si es una lesión que no puede esperar, acude al servicio médico universitario o a "
    "urgencias del hospital más cercano.\n"
    "• Si ya estás siendo atendido, comenta los detalles directamente al médico."
)


def detectar_emergencia(text: str) -> bool:
    if not text:
        return False
    t = text.lower()
    return any(kw in t for kw in EMERGENCIA_KEYWORDS)

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
        logger.warning("model.pkl no encontrado. Ejecuta train_model_full.py para habilitar /predict.")
        return

    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    with open(le_path, 'rb') as f:
        le = pickle.load(f)
    if os.path.exists(feat_path):
        with open(feat_path) as f:
            feature_names = json.load(f)

    logger.info("Modelo sklearn cargado. Enfermedades: %s", list(le.classes_))


# ─── Constantes (sklearn) ────────────────────────────────────────────────────
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

# Confianza mínima por clase con ~50 clases (la prob top suele ser <0.4 incluso en casos claros)
CONFIANZA_MIN_DIAGNOSTICO = 0.18
PROB_MIN_INCLUIR_POSIBLE = 0.04

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
    if diagnostico == 'Trauma o Lesión Física':
        return ("Los síntomas sugieren una lesión física (golpe, caída, quemadura). "
                "Esto no es una enfermedad infecciosa: acude a atención médica presencial "
                "o, si es severo, a urgencias. La IA no evalúa traumatismos.")
    if diagnostico == 'Sin Patrón Claro':
        return ("Los síntomas reportados no corresponden a un cuadro clínico claro. "
                "Se recomienda consulta médica para valoración personalizada.")
    if confianza < CONFIANZA_MIN_DIAGNOSTICO:
        return "Los síntomas no son lo suficientemente específicos. Se recomienda consulta médica para evaluación."
    if confianza >= 0.55:
        return f"Los síntomas sugieren con alta probabilidad {diagnostico}. Se recomienda atención médica prioritaria."
    if confianza >= 0.35:
        return f"Los síntomas son compatibles con {diagnostico}. Se recomienda consulta médica para confirmar."
    return f"Los síntomas podrían estar relacionados con {diagnostico}. Consulta al médico si persisten."


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
    messages: list[ChatMessage] = Field(..., min_length=1, max_length=10)


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
        # Sanity check: si el último mensaje del usuario sugiere emergencia/trauma,
        # cortamos antes de invocar al LLM y respondemos con redirección a urgencias.
        ultimo_user = next((m.content for m in reversed(req.messages) if m.role == 'user'), '')
        if detectar_emergencia(ultimo_user):
            return {
                "message": EMERGENCIA_MESSAGE,
                "finished": True,
                "diagnostico": {
                    "diagnostico_principal": "Emergencia / Trauma",
                    "confianza": 1.0,
                    "sintomas_detectados": [],
                    "posibles_enfermedades": [],
                    "recomendacion": "Atención médica presencial urgente. Llama al 911 si hay peligro inmediato.",
                }
            }

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
                    for i in top_indices if probs[i] > PROB_MIN_INCLUIR_POSIBLE
                ]

                if posibles:
                    principal = posibles[0]
                    nombre = principal["enfermedad"]
                    conf = principal["confianza"]
                    # Degradar a "Sin diagnóstico claro" si confianza < umbral y no es clase especial
                    if conf < CONFIANZA_MIN_DIAGNOSTICO and nombre not in ('Trauma o Lesión Física', 'Sin Patrón Claro'):
                        diagnostico = {
                            "diagnostico_principal": "Sin diagnóstico claro",
                            "confianza": conf,
                            "sintomas_detectados": sintomas_identificados,
                            "posibles_enfermedades": posibles,
                            "recomendacion": generar_recomendacion("Sin diagnóstico", conf)
                        }
                    else:
                        diagnostico = {
                            "diagnostico_principal": nombre,
                            "confianza": conf,
                            "sintomas_detectados": sintomas_identificados,
                            "posibles_enfermedades": posibles,
                            "recomendacion": generar_recomendacion(nombre, conf)
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
        for i in top_indices if probs[i] > PROB_MIN_INCLUIR_POSIBLE
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
    nombre = principal['enfermedad']
    conf = principal['confianza']
    # Degradar si confianza < umbral y no es clase especial
    if conf < CONFIANZA_MIN_DIAGNOSTICO and nombre not in ('Trauma o Lesión Física', 'Sin Patrón Claro'):
        return {
            'success': True,
            'diagnostico_principal': 'Sin diagnóstico claro',
            'confianza': conf,
            'sintomas_detectados': sintomas_detectados,
            'posibles_enfermedades': posibles,
            'recomendacion': generar_recomendacion('Sin diagnóstico', conf),
        }

    return {
        'success': True,
        'diagnostico_principal': nombre,
        'confianza': conf,
        'sintomas_detectados': sintomas_detectados,
        'posibles_enfermedades': posibles,
        'recomendacion': generar_recomendacion(nombre, conf),
    }


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 5000))
    uvicorn.run(app, host="0.0.0.0", port=port)
