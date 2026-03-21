#!/usr/bin/env python3
"""
Entrenamiento del modelo IA para Yoltec.
Usa dataset de Kaggle + datos sintéticos.
Modelo: VotingClassifier (RF + GB + ET) → ~90-95% precisión
Genera: model.pkl, label_encoder.pkl, feature_names.json
"""

import pandas as pd
import numpy as np
import json
import pickle
from sklearn.ensemble import (
    RandomForestClassifier,
    HistGradientBoostingClassifier,
    ExtraTreesClassifier,
    VotingClassifier,
)
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.metrics import classification_report, accuracy_score
import warnings
warnings.filterwarnings('ignore')

# ─────────────────────────────────────────────
# MAPEO: columnas del dataset → nuestros síntomas
# ─────────────────────────────────────────────
SYMPTOM_MAP = {
    'fiebre':               ['fever', 'feeling hot and cold', 'chills'],
    'tos':                  ['cough'],
    'tos_seca':             ['cough'],
    'dolor_garganta':       ['sore throat', 'throat irritation', 'throat redness'],
    'congestion_nasal':     ['nasal congestion', 'sinus congestion', 'coryza'],
    'estornudos':           ['sneezing'],
    'dolor_cabeza':         ['headache', 'frontal headache'],
    'dolor_cuerpo':         ['ache all over', 'muscle pain', 'lower body pain'],
    'cansancio':            ['fatigue', 'weakness', 'sleepiness'],
    'nauseas':              ['nausea'],
    'vomito':               ['vomiting', 'vomiting blood'],
    'diarrea':              ['diarrhea'],
    'dolor_abdominal':      ['sharp abdominal pain', 'burning abdominal pain', 'upper abdominal pain', 'lower abdominal pain'],
    'perdida_apetito':      ['decreased appetite'],
    'perdida_olfato':       ['disturbance of smell or taste'],
    'erupcion_piel':        ['skin rash', 'abnormal appearing skin'],
    'picazon':              ['itching of skin', 'skin irritation'],
    'ojos_rojos':           ['eye redness'],
    'lagrimeo':             ['lacrimation'],
    'dolor_orinar':         ['painful urination'],
    'frecuencia_orinar':    ['frequent urination'],
    'mareos':               ['dizziness'],
    'palpitaciones':        ['palpitations', 'increased heart rate', 'irregular heartbeat'],
    'sensibilidad_luz':     ['eye strain'],
    'dolor_articulaciones': ['joint pain', 'joint stiffness or tightness'],
    'sudoracion':           ['sweating'],
    'escalofrios':          ['chills'],
    'dolor_espalda':        ['back pain', 'low back pain'],
    'dificultad_respirar':  ['difficulty breathing', 'shortness of breath', 'wheezing'],
    'fiebre_alta':          ['fever'],
    'sangre_orina':         ['blood in urine'],
    'orina_turbia':         ['unusual color or odor to urine'],
    'confusion':            ['delusions or hallucinations'],
    'rigidez_cuello':       ['neck stiffness or tightness'],
}

DISEASE_MAP = {
    # Infecciones de garganta agrupadas (clínicamente manejadas igual en consultorio)
    'flu':                                    'Gripe',
    'common cold':                            'Resfriado Común',
    'acute bronchitis':                       'Bronquitis Aguda',
    'pharyngitis':                            'Infección de Garganta',
    'tonsillitis':                            'Infección de Garganta',
    'acute sinusitis':                        'Sinusitis',
    'infectious gastroenteritis':             'Gastroenteritis',
    'gastroesophageal reflux disease (gerd)': 'Reflujo Gástrico',
    'migraine':                               'Migraña',
    'urinary tract infection':                'Infección Urinaria',
    'conjunctivitis due to allergy':          'Conjuntivitis',
    'conjunctivitis':                         'Conjuntivitis',
    'contact dermatitis':                     'Dermatitis Alérgica',
    'iron deficiency anemia':                 'Anemia',
    'anemia':                                 'Anemia',
    'malignant hypertension':                 'Hipertensión',
    'hypoglycemia':                           'Hipoglucemia',
    'heat exhaustion':                        'Golpe de Calor',
    'chickenpox':                             'Varicela',
    'scabies':                                'Escabiosis',
    'malaria':                                'Paludismo',
    'dengue fever':                           'Dengue',
}


def load_and_prepare(path: str) -> tuple:
    print("Cargando dataset...")
    df = pd.read_csv(path)
    print(f"  → {len(df):,} registros, {len(df.columns)} columnas")

    df_filtered = df[df['diseases'].isin(DISEASE_MAP.keys())].copy()
    df_filtered['diseases'] = df_filtered['diseases'].map(DISEASE_MAP)
    print(f"  → {len(df_filtered):,} registros tras filtrar enfermedades")

    features = pd.DataFrame(0, index=df_filtered.index, columns=list(SYMPTOM_MAP.keys()))
    dataset_cols = list(df.columns)
    for our_id, dataset_names in SYMPTOM_MAP.items():
        for col in dataset_names:
            if col in dataset_cols:
                features[our_id] = features[our_id] | df_filtered[col].fillna(0).astype(int)

    return features, df_filtered['diseases']


def generate_synthetic() -> tuple:
    np.random.seed(42)
    cols = list(SYMPTOM_MAP.keys())
    records, labels = [], []

    def make(disease, base, n=800, noise=0.08):
        for _ in range(n):
            row = []
            for col in cols:
                prob = base.get(col, 0.03)
                val = 1 if np.random.random() < np.clip(prob + np.random.uniform(-noise, noise), 0, 1) else 0
                row.append(val)
            records.append(row)
            labels.append(disease)

    make('COVID-19', {
        'fiebre': 0.85, 'tos': 0.80, 'tos_seca': 0.78, 'cansancio': 0.82,
        'perdida_olfato': 0.72, 'dolor_cabeza': 0.65, 'dolor_cuerpo': 0.60,
        'dificultad_respirar': 0.50, 'dolor_garganta': 0.40, 'nauseas': 0.25,
    }, n=900)

    make('Chikungunya', {
        'fiebre': 0.95, 'fiebre_alta': 0.85, 'dolor_articulaciones': 0.97,
        'erupcion_piel': 0.72, 'dolor_cabeza': 0.65, 'dolor_cuerpo': 0.72,
        'nauseas': 0.40, 'cansancio': 0.62, 'escalofrios': 0.52,
    }, n=700)

    make('Dengue', {
        'fiebre': 0.96, 'fiebre_alta': 0.90, 'dolor_cabeza': 0.87,
        'dolor_cuerpo': 0.92, 'dolor_articulaciones': 0.72, 'erupcion_piel': 0.62,
        'nauseas': 0.62, 'vomito': 0.42, 'cansancio': 0.78, 'escalofrios': 0.57,
        'dolor_abdominal': 0.37,
    }, n=900)

    make('Zika', {
        'fiebre': 0.80, 'erupcion_piel': 0.92, 'ojos_rojos': 0.72,
        'dolor_articulaciones': 0.62, 'dolor_cabeza': 0.55, 'cansancio': 0.52,
        'picazon': 0.68, 'lagrimeo': 0.47,
    }, n=600)

    make('Colitis', {
        'dolor_abdominal': 0.92, 'diarrea': 0.88, 'nauseas': 0.62,
        'perdida_apetito': 0.67, 'cansancio': 0.57, 'vomito': 0.37,
        'fiebre': 0.40,
    }, n=700)

    make('Intoxicación Alimentaria', {
        'nauseas': 0.92, 'vomito': 0.88, 'diarrea': 0.83, 'dolor_abdominal': 0.78,
        'fiebre': 0.57, 'cansancio': 0.62, 'dolor_cuerpo': 0.42,
    }, n=700)

    make('Paludismo', {
        'fiebre': 0.96, 'fiebre_alta': 0.87, 'escalofrios': 0.92,
        'sudoracion': 0.87, 'dolor_cabeza': 0.82, 'dolor_cuerpo': 0.77,
        'nauseas': 0.67, 'vomito': 0.57, 'cansancio': 0.82,
    }, n=700)

    # Refuerzo de enfermedades comunes del dataset real
    make('Gripe', {
        'fiebre': 0.90, 'tos': 0.85, 'dolor_garganta': 0.70,
        'congestion_nasal': 0.65, 'dolor_cabeza': 0.75, 'dolor_cuerpo': 0.80,
        'cansancio': 0.82, 'escalofrios': 0.70,
    }, n=500)

    make('Resfriado Común', {
        'congestion_nasal': 0.92, 'estornudos': 0.88, 'dolor_garganta': 0.72,
        'tos': 0.68, 'cansancio': 0.55,
    }, n=500)

    make('Infección Urinaria', {
        'dolor_orinar': 0.95, 'frecuencia_orinar': 0.90, 'orina_turbia': 0.70,
        'fiebre': 0.55, 'dolor_abdominal': 0.50, 'sangre_orina': 0.35,
    }, n=600)

    make('Migraña', {
        'dolor_cabeza': 0.98, 'sensibilidad_luz': 0.85, 'nauseas': 0.72,
        'vomito': 0.45, 'mareos': 0.60,
    }, n=600)

    # Refuerzo de enfermedades con pocos datos reales
    make('Infección de Garganta', {
        'dolor_garganta': 0.97, 'fiebre': 0.78, 'cansancio': 0.65,
        'dolor_cabeza': 0.55, 'congestion_nasal': 0.35, 'tos': 0.45,
        'perdida_apetito': 0.50,
    }, n=800)

    make('Escabiosis', {
        'picazon': 0.97, 'erupcion_piel': 0.90, 'ojos_rojos': 0.20,
        'cansancio': 0.35,
    }, n=600)

    make('Hipertensión', {
        'dolor_cabeza': 0.85, 'mareos': 0.75, 'palpitaciones': 0.65,
        'cansancio': 0.55, 'dificultad_respirar': 0.40,
    }, n=600)

    make('Golpe de Calor', {
        'fiebre_alta': 0.92, 'fiebre': 0.88, 'sudoracion': 0.80,
        'mareos': 0.78, 'dolor_cabeza': 0.75, 'cansancio': 0.80,
        'confusion': 0.45, 'nauseas': 0.55,
    }, n=600)

    make('Varicela', {
        'erupcion_piel': 0.97, 'picazon': 0.92, 'fiebre': 0.78,
        'cansancio': 0.65, 'dolor_cabeza': 0.55, 'perdida_apetito': 0.50,
    }, n=600)

    print(f"  → {len(records):,} registros sintéticos generados")
    return pd.DataFrame(records, columns=cols), labels


def train_model(X: np.ndarray, y_enc: np.ndarray, le: LabelEncoder):
    print(f"\nDataset total: {len(X):,} registros, {len(le.classes_)} enfermedades")

    X_train, X_test, y_train, y_test = train_test_split(
        X, y_enc, test_size=0.15, random_state=42, stratify=y_enc
    )

    # Ensemble: combina 3 modelos con soft voting ponderado
    rf = RandomForestClassifier(
        n_estimators=400, max_features='sqrt',
        min_samples_leaf=1, class_weight='balanced',
        random_state=42, n_jobs=-1,
    )
    hgb = HistGradientBoostingClassifier(
        max_iter=400, learning_rate=0.05,
        max_depth=6, l2_regularization=0.1,
        random_state=42,
    )
    et = ExtraTreesClassifier(
        n_estimators=400, max_features='sqrt',
        min_samples_leaf=1, class_weight='balanced',
        random_state=42, n_jobs=-1,
    )

    model = VotingClassifier(
        estimators=[('rf', rf), ('hgb', hgb), ('et', et)],
        voting='soft',
        weights=[2, 3, 2],  # más peso al HistGradientBoosting
        n_jobs=-1,
    )

    print("Entrenando ensemble (RF + GradientBoosting + ExtraTrees)...")
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    print(f"\nPrecisión en test: {acc:.2%}")
    print("\nReporte por enfermedad:")
    print(classification_report(y_test, y_pred, target_names=le.classes_))

    return model


def main():
    dataset_path = '../archive/Final_Augmented_dataset_Diseases_and_Symptoms.csv'

    X_real, y_real = load_and_prepare(dataset_path)

    print("\nGenerando datos sintéticos...")
    X_syn, y_syn = generate_synthetic()

    X = np.vstack([X_real.values, X_syn.values])
    y = list(y_real) + list(y_syn)

    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    print("Distribución por enfermedad:")
    unique, counts = np.unique(y, return_counts=True)
    for disease, count in sorted(zip(unique, counts), key=lambda x: -x[1]):
        print(f"  {count:6,}  {disease}")

    model = train_model(X, y_enc, le)

    with open('model.pkl', 'wb') as f:
        pickle.dump(model, f)
    with open('label_encoder.pkl', 'wb') as f:
        pickle.dump(le, f)
    with open('feature_names.json', 'w') as f:
        json.dump(list(SYMPTOM_MAP.keys()), f)

    print("\nModelo guardado: model.pkl, label_encoder.pkl, feature_names.json")
    print("Para re-entrenar: python train_model.py")


if __name__ == '__main__':
    main()
