import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
import joblib

# 1. Cargar dataset
# Asegúrate de crear este archivo en el mismo directorio que este script
# con columnas como las descritas en la documentación.
df = pd.read_csv("dataset_pacientes.csv")

# 2. Separar features y etiqueta
X = df.drop(columns=["diagnostico"])
y = df["diagnostico"]

# 3. Dividir en train/test (opcional, solo para evaluar)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# 4. Crear y entrenar modelo (RandomForest como ejemplo sencillo)
model = RandomForestClassifier(
    n_estimators=100,
    random_state=42,
    class_weight="balanced"
)
model.fit(X_train, y_train)

# 5. Evaluación rápida en consola (para ustedes)
y_pred = model.predict(X_test)
print(classification_report(y_test, y_pred))

# 6. Guardar modelo entrenado
joblib.dump(model, "modelo_ia.pkl")
print("Modelo guardado en modelo_ia.pkl")
