#!/usr/bin/env python3
"""
Extractor de síntomas por reglas y guion de preguntas.

Sustituye al LLM cuando no hay proveedor configurado o cuando este falla:
traduce lo que escribe el estudiante en español a los identificadores que
espera el clasificador sklearn (los mismos de feature_names.json).

No sustituye al diagnóstico — de eso sigue encargándose model.pkl.
"""

import re
import unicodedata

# ─── Guion de preguntas (modo sin LLM) ───────────────────────────────────────
# El chat cierra tras MIN_RESPUESTAS respuestas del estudiante, igual que el
# criterio que le pedimos al LLM en su prompt.
MIN_RESPUESTAS = 3

PREGUNTAS = [
    "Hola, soy el asistente del consultorio. Cuéntame, ¿qué es lo que sientes?",
    "Entiendo. ¿Desde cuándo lo sientes y ha ido empeorando?",
    "¿Traes algo más además de eso? Por ejemplo fiebre, tos, náuseas o dolor de cabeza.",
    "¿Hay algo más que quieras que el médico sepa antes de tu consulta?",
]

CIERRE = (
    "Gracias, con eso es suficiente. Ya registré lo que me contaste; "
    "el médico lo revisará antes de tu consulta."
)

CIERRE_SIN_SINTOMAS = (
    "Gracias por contarme. No alcancé a identificar síntomas concretos en lo que "
    "escribiste, así que será el médico quien te valore directamente en la consulta."
)

# ─── Negación ────────────────────────────────────────────────────────────────
# Marcadores que invierten el sentido de lo que viene justo después.
NEGACIONES = {"no", "sin", "ningun", "ninguna", "ningunos", "tampoco", "niego", "nunca", "nada"}

# Alcance de la negación, en palabras. "no tengo fiebre" la niega; en
# "no puedo dormir y me siento cansado" el cansancio queda fuera del alcance.
VENTANA_NEGACION = 4

# Además, la cláusula acota: "me duele la cabeza, no tengo fiebre" afirma el
# dolor y niega la fiebre.
# La "y" separa solo cuando abre una oración con sujeto propio ("... y me enojo"),
# no cuando enumera ("no tengo fiebre y tos", donde la negación sí alcanza a ambos).
SEPARADOR_CLAUSULAS = re.compile(
    r"[,.;:!?\n]"
    r"|\bpero\b|\baunque\b|\bsin embargo\b|\bademas\b|\btambien\b"
    r"|\by(?=\s+(?:me|se me|ando|traigo|tengo|siento|estoy|ya)\b)"
)

# Palabras de relleno que el estudiante intercala: "me duele mucho la cabeza",
# "la orina sale turbia".
INTENSIFICADORES = [
    "muy", "mucho", "mucha", "bastante", "demasiado", "poco", "poca", "algo",
    "harto", "super", "bien", "feo", "gacho", "tan", "tanto", "todo", "toda", "ya", "casi", "siempre",
]

ENLACES = ["sale", "salen", "esta", "estan", "se ve", "se ven", "se siente", "se sienten"]

RELLENO = INTENSIFICADORES + ENLACES

# ─── Sinónimos ───────────────────────────────────────────────────────────────
# Cada identificador del clasificador con las formas en que un estudiante lo
# escribiría. Se comparan como frases completas (con límites de palabra), sin
# acentos y en minúsculas.
SINONIMOS: dict[str, list[str]] = {
    "fiebre_alta": ["fiebre alta", "fiebre muy alta", "calentura alta", "40 grados", "39 grados", "ardiendo en fiebre"],
    "fiebre": ["fiebre", "calentura", "traigo temperatura", "tengo temperatura", "destemplado", "febril"],
    "tos_seca": ["tos seca", "tos sin flema", "tos irritativa"],
    "tos": ["tos", "toso", "tose", "toser", "tosiendo", "tos con flema", "tosido"],
    "dolor_garganta": ["dolor de garganta", "me duele la garganta", "garganta irritada", "arde la garganta",
                       "me arde la garganta", "dolor al tragar", "duele al tragar", "anginas"],
    "congestion_nasal": ["congestion nasal", "congestionado", "nariz tapada", "nariz congestionada",
                         "moco", "mocos", "escurrimiento nasal", "gripa", "resfriado"],
    "estornudos": ["estornudos", "estornudo", "estornudando", "no paro de estornudar"],
    "dificultad_respirar": ["dificultad para respirar", "me cuesta respirar",
                            "me falta el aire", "falta de aire", "ahogo al caminar", "respiro con dificultad"],
    "dolor_cabeza": ["dolor de cabeza", "me duele la cabeza", "cefalea", "jaqueca", "migrana", "migrana",
                     "duele la cabeza", "cabeza me duele"],
    "mareos": ["mareo", "mareos", "mareado", "mareada", "todo me da vueltas", "me ando mareando"],
    "confusion": ["confusion", "confundido", "confundida", "desorientado", "desorientada"],
    "sensibilidad_luz": ["sensibilidad a la luz", "me molesta la luz", "fotofobia", "la luz me lastima"],
    "rigidez_cuello": ["rigidez de cuello", "cuello tieso", "no puedo mover el cuello", "cuello rigido",
                       "me duele el cuello"],
    "perdida_balance": ["perdida de equilibrio", "pierdo el equilibrio", "me tambaleo"],
    "hormigueo": ["hormigueo", "se me duermen las manos", "se me duermen los pies", "adormecimiento",
                  "siento cosquilleo"],
    "desmayo": ["desmayo", "me desmaye", "perdi el conocimiento", "me desvaneci", "perdida de conciencia"],
    "dolor_cuerpo": ["dolor de cuerpo", "me duele todo el cuerpo", "dolor muscular", "cuerpo cortado",
                     "me duele todo"],
    "dolor_articulaciones": ["dolor de articulaciones", "me duelen las articulaciones", "dolor en las rodillas",
                             "me duelen las rodillas", "articulaciones hinchadas", "dolor en las coyunturas"],
    "dolor_espalda": ["dolor de espalda", "me duele la espalda", "dolor lumbar", "dolor en la cintura",
                      "me duele la cintura"],
    "dolor_pecho": ["dolor de pecho", "me duele el pecho", "opresion en el pecho", "presion en el pecho",
                    "punzadas en el pecho"],
    "debilidad_muscular": ["debilidad muscular", "sin fuerza", "me siento debil", "musculos debiles"],
    "nauseas": ["nauseas", "nausea", "ganas de vomitar", "asco", "me da asco la comida", "revoltura de estomago"],
    "vomito": ["vomito", "vomite", "vomitando", "he vomitado", "devolvi el estomago", "guacareo"],
    "diarrea": ["diarrea", "estomago suelto", "evacuaciones liquidas", "me anda del estomago", "chorro"],
    "dolor_abdominal": ["dolor abdominal", "dolor de estomago", "me duele el estomago", "me duele la panza",
                        "dolor de panza", "retortijones", "colicos", "dolor en el vientre"],
    "perdida_apetito": ["perdida de apetito", "inapetencia", "se me quito el hambre"],
    "ardor_estomago": ["ardor de estomago", "acidez", "agruras", "reflujo", "me arde el estomago", "agrieras"],
    "estrenimiento": ["estrenimiento", "estrenido", "estrenida"],
    "dolor_orinar": ["dolor al orinar", "me arde al orinar", "ardor al orinar", "duele hacer pipi",
                     "arde cuando hago pipi"],
    "frecuencia_orinar": ["orino mucho", "voy mucho al bano a orinar", "ganas constantes de orinar",
                          "frecuencia urinaria", "muchas ganas de hacer pipi"],
    "sangre_orina": ["sangre en la orina", "orino sangre", "orina con sangre", "hematuria"],
    "orina_turbia": ["orina turbia", "orina oscura", "orina con mal olor", "pipi turbia"],
    "dolor_menstrual": ["dolor menstrual", "colicos menstruales", "dolor de regla", "me duele la regla",
                        "dismenorrea"],
    "sangrado_anormal": ["sangrado anormal", "sangrado fuera de regla", "sangrado inusual", "manchado"],
    "erupcion_piel": ["erupcion", "sarpullido", "ronchas", "granitos en la piel", "salpullido", "brote en la piel"],
    "picazon": ["picazon", "comezon", "me pica", "prurito", "rasquera"],
    "hinchazon": ["hinchazon", "hinchado", "hinchada", "inflamado", "inflamacion", "se me hincho"],
    "enrojecimiento": ["enrojecimiento", "piel roja", "area enrojecida", "se puso rojo"],
    "ojos_rojos": ["ojos rojos", "ojo rojo", "conjuntivitis", "ojos irritados"],
    "lagrimeo": ["lagrimeo", "me lloran los ojos", "ojos llorosos"],
    "vision_borrosa": ["vision borrosa", "veo borroso", "vista nublada"],
    "dolor_oido": ["dolor de oido", "me duele el oido", "otitis", "punzadas en el oido"],
    "secrecion_oido": ["secrecion del oido", "me sale liquido del oido", "supuracion del oido", "pus en el oido"],
    "cansancio": ["cansancio", "fatiga", "cansado", "cansada", "agotado", "agotada", "sin energia", "sin fuerzas"],
    "sudoracion": ["sudoracion", "sudo mucho", "sudores", "sudo en las noches", "transpiro mucho"],
    "escalofrios": ["escalofrios", "escalofrio", "temblores de frio", "me da mucho frio"],
    "perdida_olfato": ["perdida del olfato", "perdi el gusto", "perdi el olfato", "todo me sabe igual"],
    "palpitaciones": ["palpitaciones", "el corazon me late rapido", "taquicardia", "corazon acelerado",
                      "siento que se me sale el corazon"],
    "sequedad_boca": ["sequedad de boca", "boca seca", "se me seca la boca"],
    "deshidratacion": ["deshidratacion", "deshidratado", "deshidratada", "mucha sed", "no he tomado agua"],
    "ansiedad": ["ansiedad", "ansioso", "ansiosa", "angustia", "nervios", "me siento nervioso",
                 "me siento nerviosa", "ataques de panico"],
    "insomnio": ["insomnio", "me cuesta dormir", "desvelado", "desvelada", "doy vueltas en la cama"],
    "irritabilidad": ["irritabilidad", "irritable", "de mal humor", "me enojo por todo", "malhumorado"],
    "tristeza_persistente": ["tristeza", "triste", "deprimido", "deprimida", "depresion", "sin ganas de nada",
                             "desanimado", "desanimada"],
    "sangrado_severo": ["sangrado severo", "sangro mucho", "no para de sangrar", "hemorragia", "mucha sangre"],
    "golpe_reciente": ["golpe", "me golpee", "me pegue", "me cai", "caida", "moreton", "contusion", "trauma"],
    "quemadura": ["quemadura", "me queme", "quemado con agua caliente", "quemadura de sol"],
}

# Síntomas que se afirman negando una capacidad: "tampoco tengo hambre" es
# pérdida de apetito. Estas frases solo cuentan cuando van negadas.
SINONIMOS_NEGADOS: dict[str, list[str]] = {
    "dificultad_respirar": ["puedo respirar", "respiro bien", "me entra el aire"],
    "perdida_apetito": ["hambre", "apetito", "ganas de comer", "quiero comer", "se me antoja"],
    "estrenimiento": ["puedo ir al bano", "he obrado", "puedo evacuar", "he ido al bano"],
    "perdida_olfato": ["huelo", "siento los olores", "siento el sabor", "siento sabores", "percibo olores"],
    "insomnio": ["dormir", "dormido", "duermo", "concilio el sueno"],
    "vision_borrosa": ["veo bien", "alcanzo a ver"],
    "debilidad_muscular": ["tengo fuerza", "tengo fuerzas", "fuerza en las piernas"],
    "confusion": ["pienso bien", "me concentro", "puedo concentrarme"],
    "dolor_garganta": ["puedo tragar", "puedo pasar bocado"],
    "perdida_balance": ["me puedo parar bien", "puedo caminar derecho"],
}

# Frases que solo significan algo con contexto. "voy mucho al baño" es urinario
# si se habla de orina y digestivo si se habla del estómago; sin pistas se ignora.
AMBIGUAS: dict[str, dict[str, list[str]]] = {
    "voy mucho al bano": {
        "frecuencia_orinar": ["orinar", "orino", "orina", "pipi", "miccion", "vejiga"],
        "diarrea": ["estomago", "panza", "diarrea", "suelto", "evacuar", "heces", "intestino"],
    },
    "voy seguido al bano": {
        "frecuencia_orinar": ["orinar", "orino", "orina", "pipi", "miccion", "vejiga"],
        "diarrea": ["estomago", "panza", "diarrea", "suelto", "evacuar", "heces", "intestino"],
    },
}

# Un síntoma específico implica el general: quien reporta fiebre alta tiene fiebre.
IMPLICA = {
    "fiebre_alta": "fiebre",
    "tos_seca": "tos",
    "sangrado_severo": "sangrado_anormal",
}


def _normalizar(texto: str) -> str:
    """Minúsculas, sin acentos y con espacios colapsados."""
    t = unicodedata.normalize("NFD", texto.lower())
    t = "".join(c for c in t if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", t).strip()


def _compilar(frase: str) -> re.Pattern:
    """Patrón de la frase tolerando intensificadores entre sus palabras."""
    relleno = r"(?:\s+(?:" + "|".join(RELLENO) + r"))*\s+"
    palabras = [re.escape(p) for p in _normalizar(frase).split()]
    return re.compile(r"\b" + relleno.join(palabras) + r"\b")


# Los patrones se compilan una sola vez al importar el módulo.
PATRONES: dict[str, list[re.Pattern]] = {
    sintoma: [_compilar(f) for f in frases] for sintoma, frases in SINONIMOS.items()
}

PATRONES_NEGADOS: dict[str, list[re.Pattern]] = {
    sintoma: [_compilar(f) for f in frases] for sintoma, frases in SINONIMOS_NEGADOS.items()
}

PATRONES_AMBIGUOS: dict[str, re.Pattern] = {frase: _compilar(frase) for frase in AMBIGUAS}

# Un sinónimo que ya lleva la negación dentro ("no para de sangrar") nunca se niega.
FRASE_NEGATIVA: dict[str, list[bool]] = {
    sintoma: [bool(NEGACIONES & set(_normalizar(f).split())) for f in frases]
    for sintoma, frases in SINONIMOS.items()
}


def _negado(clausula: str, inicio: int) -> bool:
    """¿Hay un marcador de negación en las palabras previas a la coincidencia?"""
    previas = clausula[:inicio].split()[-VENTANA_NEGACION:]
    return bool(NEGACIONES & set(previas))


def _resolver_ambiguas(texto: str, encontrados: list[str]) -> None:
    """
    Resuelve las frases ambiguas mirando el resto del texto. Si no hay pistas
    suficientes —o apuntan a más de un síntoma— se descarta la frase: es
    preferible perder un síntoma a inventarse el equivocado.
    """
    completo = _normalizar(texto)
    for frase, candidatos in AMBIGUAS.items():
        if PATRONES_AMBIGUOS[frase].search(completo) is None:
            continue
        con_pistas = [
            sintoma for sintoma, pistas in candidatos.items()
            if any(re.search(rf"\b{re.escape(p)}\w*", completo) for p in pistas)
        ]
        if len(con_pistas) == 1 and con_pistas[0] not in encontrados:
            encontrados.append(con_pistas[0])


def extraer_sintomas(texto: str) -> list[str]:
    """
    Devuelve los identificadores de síntomas presentes en el texto, en el orden
    de SINONIMOS y sin repetir.

    La negación alcanza a las palabras que le siguen dentro de su cláusula:
    "me duele la cabeza pero no tengo fiebre" devuelve solo dolor_cabeza, y
    "no tengo fiebre y tos" no devuelve ninguno. Al revés también cuenta:
    negar una capacidad afirma un síntoma ("tampoco tengo hambre").
    """
    if not texto:
        return []

    encontrados: list[str] = []
    for clausula in SEPARADOR_CLAUSULAS.split(_normalizar(texto)):
        clausula = clausula.strip()
        if not clausula:
            continue
        for sintoma, patrones in PATRONES.items():
            if sintoma in encontrados:
                continue
            for patron, es_negativa in zip(patrones, FRASE_NEGATIVA[sintoma]):
                coincidencia = patron.search(clausula)
                if coincidencia is None:
                    continue
                if not es_negativa and _negado(clausula, coincidencia.start()):
                    continue
                encontrados.append(sintoma)
                break

        # Capacidades que solo cuentan cuando se niegan: "tampoco tengo hambre".
        for sintoma, patrones in PATRONES_NEGADOS.items():
            if sintoma in encontrados:
                continue
            for patron in patrones:
                coincidencia = patron.search(clausula)
                if coincidencia is not None and _negado(clausula, coincidencia.start()):
                    encontrados.append(sintoma)
                    break

    _resolver_ambiguas(texto, encontrados)

    for especifico, general in IMPLICA.items():
        if especifico in encontrados and general not in encontrados:
            encontrados.append(general)

    return [s for s in SINONIMOS if s in encontrados]


def extraer_de_conversacion(messages: list) -> list[str]:
    """Extrae los síntomas de todo lo que ha escrito el estudiante."""
    textos = [
        m.content if hasattr(m, "content") else m.get("content", "")
        for m in messages
        if (m.role if hasattr(m, "role") else m.get("role")) == "user"
    ]
    return extraer_sintomas(" . ".join(textos))


def siguiente_pregunta(respuestas_dadas: int) -> str:
    """Pregunta que toca según cuántas veces ha escrito ya el estudiante."""
    indice = min(respuestas_dadas, len(PREGUNTAS) - 1)
    return PREGUNTAS[indice]


def conversacion_terminada(respuestas_dadas: int) -> bool:
    return respuestas_dadas >= MIN_RESPUESTAS
