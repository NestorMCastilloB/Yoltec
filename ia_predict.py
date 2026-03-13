import sys
import json
import joblib
import numpy as np

# Cargar modelo entrenado (asegúrate de haber corrido antes ia_train_model.py)
model = joblib.load("modelo_ia.pkl")

# Leer JSON de stdin
data = json.loads(sys.stdin.read())

# Orden de features. Debe coincidir con las columnas usadas en el entrenamiento
feature_order = [
    "edad",
    "sexo",            # 0 = M, 1 = F (ejemplo)
    "glucosa_ayuno",
    "ta_sistolica",
    "ta_diastolica",
    "imc",
    "poliuria",
    "polidipsia",
    "perdida_peso"
]

x = [data.get(k, 0) for k in feature_order]
X = np.array([x])

pred = model.predict(X)[0]
probas = model.predict_proba(X)[0]
classes = model.classes_.tolist()

pairs = sorted(zip(classes, probas), key=lambda p: p[1], reverse=True)

resultados = [
    {
        "diagnostico": c,
        "probabilidad": float(p)
    }
    for c, p in pairs
]

salida = {
    "prediccion_principal": pred,
    "diagnosticos_ordenados": resultados
}

print(json.dumps(salida))
