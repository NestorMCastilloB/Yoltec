#!/usr/bin/env python3
"""
Modelo completo: dataset sintetico (47 clases) + CSV real Kaggle (246k registros).
Algoritmo HistGradientBoostingClassifier puro — velocidad equivalente al light.
Objetivo: maxima cobertura de datos manteniendo inferencia rapida en Render.
Genera: model_full.pkl (NO sobreescribe model.pkl actual hasta validar benchmark).
"""

import numpy as np
import pandas as pd
import json
import pickle
import os
import time
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import warnings
warnings.filterwarnings('ignore')

from train_model_light import SYMPTOM_COLS, generate_dataset

CSV_PATH = 'data/Final_Augmented_dataset_Diseases_and_Symptoms.csv'

# Mapeo: nombre Kaggle → clase del modelo (alineado a las 47 del train_model_light.py)
DISEASE_MAP = {
    'dengue fever':                           'Dengue',
    'malaria':                                'Paludismo',
    'flu':                                    'Gripe',
    'common cold':                            'Resfriado Común',
    'acute bronchitis':                       'Bronquitis Aguda',
    'acute bronchiolitis':                    'Bronquitis Aguda',
    'pharyngitis':                            'Faringoamigdalitis',
    'tonsillitis':                            'Faringoamigdalitis',
    'strep throat':                           'Faringoamigdalitis',
    'acute sinusitis':                        'Sinusitis',
    'chronic sinusitis':                      'Sinusitis',
    'infectious gastroenteritis':             'Gastroenteritis / Intoxicación',
    'noninfectious gastroenteritis':          'Gastroenteritis / Intoxicación',
    'food poisoning':                         'Gastroenteritis / Intoxicación',
    'gastroesophageal reflux disease (gerd)': 'Gastritis / Reflujo',
    'gastritis':                              'Gastritis / Reflujo',
    'esophagitis':                            'Gastritis / Reflujo',
    'chronic constipation':                   'Estreñimiento Funcional',
    'migraine':                               'Migraña',
    'tension headache':                       'Cefalea Tensional',
    'urinary tract infection':                'Infección Urinaria',
    'cystitis':                               'Infección Urinaria',
    'pyelonephritis':                         'Infección Urinaria',
    'vaginitis':                              'Vaginitis',
    'conjunctivitis due to allergy':          'Conjuntivitis',
    'conjunctivitis':                         'Conjuntivitis',
    'contact dermatitis':                     'Reacción Dérmica',
    'allergic reaction':                      'Reacción Dérmica',
    'eczema':                                 'Reacción Dérmica',
    'iron deficiency anemia':                 'Anemia',
    'anemia':                                 'Anemia',
    'hypertension':                           'Hipertensión Arterial',
    'malignant hypertension':                 'Hipertensión Arterial',
    'hypoglycemia':                           'Hipoglucemia',
    'heat exhaustion':                        'Golpe de Calor / Insolación',
    'dehydration':                            'Deshidratación',
    'chickenpox':                             'Varicela',
    'scabies':                                'Escabiosis',
    'sunburn':                                'Quemadura Solar',
    'pneumonia':                              'Neumonía Leve',
    'asthma':                                 'Asma Bronquial Leve',
    'allergic rhinitis':                      'Alergia Estacional',
    'anxiety':                                'Ansiedad',
    'panic disorder':                         'Ansiedad',
    'depression':                             'Depresión Leve',
    'insomnia':                               'Insomnio',
    'appendicitis':                           'Apendicitis (Posible)',
    'concussion':                             'Trauma o Lesión Física',
    'sprain or strain':                       'Trauma o Lesión Física',
    'otitis media':                           'Otitis Media',
    'otitis externa':                         'Otitis Externa',
    'low back pain':                          'Lumbalgia',
    'vertigo':                                'Vértigo Postural',
    'benign paroxysmal positional vertigo':   'Vértigo Postural',
}

# Mapeo: nuestro sintoma → columnas Kaggle (OR logico sobre todas las matches)
SYMPTOM_MAP = {
    'fiebre':               ['fever'],
    'fiebre_alta':          ['fever'],
    'tos':                  ['cough'],
    'tos_seca':             ['cough'],
    'dolor_garganta':       ['sore throat', 'throat irritation', 'throat redness', 'swollen or red tonsils'],
    'congestion_nasal':     ['nasal congestion'],
    'estornudos':           ['drainage in throat'],
    'dificultad_respirar':  ['shortness of breath', 'congestion in chest'],
    'dolor_cabeza':         ['headache', 'frontal headache'],
    'mareos':               ['dizziness'],
    'confusion':            ['depressive or psychotic symptoms'],
    'sensibilidad_luz':     ['eye strain'],
    'rigidez_cuello':       ['neck swelling'],
    'perdida_balance':      ['dizziness'],
    'hormigueo':            ['focal weakness'],
    'desmayo':              ['fainting'],
    'dolor_cuerpo':         ['muscle pain'],
    'dolor_articulaciones': ['joint pain', 'joint stiffness or tightness'],
    'dolor_espalda':        ['back pain', 'low back pain'],
    'dolor_pecho':          ['sharp chest pain', 'chest tightness', 'burning chest pain'],
    'debilidad_muscular':   ['weakness', 'muscle weakness'],
    'nauseas':              ['nausea'],
    'vomito':               ['vomiting', 'vomiting blood'],
    'diarrea':              ['diarrhea'],
    'dolor_abdominal':      ['sharp abdominal pain', 'upper abdominal pain', 'lower abdominal pain'],
    'perdida_apetito':      ['decreased appetite'],
    'ardor_estomago':       ['burning abdominal pain', 'heartburn'],
    'estrenimiento':        ['constipation'],
    'dolor_orinar':         ['painful urination'],
    'frecuencia_orinar':    ['frequent urination', 'excessive urination at night'],
    'sangre_orina':         ['blood in urine'],
    'orina_turbia':         ['unusual color or odor to urine', 'pus in urine'],
    'dolor_menstrual':      ['painful menstruation'],
    'sangrado_anormal':     ['intermenstrual bleeding', 'heavy menstrual flow', 'vaginal bleeding after menopause'],
    'erupcion_piel':        ['skin rash', 'abnormal appearing skin', 'skin lesion'],
    'picazon':              ['itching of skin', 'skin irritation'],
    'hinchazon':            ['skin swelling', 'joint swelling', 'leg swelling'],
    'enrojecimiento':       ['redness in or around nose', 'penis redness'],
    'ojos_rojos':           ['eye redness'],
    'lagrimeo':             ['white discharge from eye'],
    'vision_borrosa':       ['symptoms of eye'],
    'dolor_oido':           ['ear pain'],
    'secrecion_oido':       ['bleeding from ear', 'redness in ear'],
    'cansancio':            ['fatigue'],
    'sudoracion':           ['sweating'],
    'escalofrios':          ['chills'],
    'perdida_olfato':       ['disturbance of smell or taste'],
    'palpitaciones':        ['palpitations', 'increased heart rate'],
    'sequedad_boca':        [],
    'deshidratacion':       [],
    'ansiedad':             ['anxiety and nervousness'],
    'insomnio':             ['insomnia'],
    'irritabilidad':        ['premenstrual tension or irritability', 'irritable infant'],
    'tristeza_persistente': ['depression'],
    'sangrado_severo':      ['rectal bleeding', 'bleeding gums', 'nosebleed'],
    'golpe_reciente':       [],
    'quemadura':            ['skin pain'],
}


def load_real_dataset() -> tuple[np.ndarray, list[str]]:
    print(f"Cargando CSV real ({CSV_PATH})...")
    df = pd.read_csv(CSV_PATH)
    print(f"  → {len(df):,} filas, {len(df.columns)} columnas")

    df = df[df['diseases'].isin(DISEASE_MAP.keys())].copy()
    df['target'] = df['diseases'].map(DISEASE_MAP)
    print(f"  → {len(df):,} filas tras filtrar a clases mapeadas ({df['target'].nunique()} clases)")

    csv_cols = set(df.columns)
    matrix = np.zeros((len(df), len(SYMPTOM_COLS)), dtype=np.int8)
    for i, sintoma in enumerate(SYMPTOM_COLS):
        for kaggle_col in SYMPTOM_MAP.get(sintoma, []):
            if kaggle_col in csv_cols:
                matrix[:, i] |= df[kaggle_col].fillna(0).astype(np.int8).values

    print(f"  → matriz {matrix.shape} construida")
    print("\nDistribución por clase (CSV real):")
    for clase, n in df['target'].value_counts().items():
        print(f"  {n:6,}  {clase}")

    return matrix, df['target'].tolist()


def benchmark(model: HistGradientBoostingClassifier, X_test: np.ndarray, y_test: np.ndarray, le: LabelEncoder):
    print("\n" + "=" * 60)
    print("BENCHMARK")
    print("=" * 60)

    acc = accuracy_score(y_test, model.predict(X_test))
    print(f"Precisión global: {acc:.2%}")

    # Tiempo de inferencia: 1000 predicciones individuales (peor caso prod)
    sample = X_test[:1000]
    t0 = time.perf_counter()
    for row in sample:
        model.predict(row.reshape(1, -1))
    elapsed = time.perf_counter() - t0
    print(f"Inferencia: {elapsed * 1000:.1f}ms para 1000 predicciones · {elapsed:.3f}ms/predicción")

    # Tiempo en batch
    t0 = time.perf_counter()
    model.predict(X_test)
    print(f"Batch ({len(X_test):,}): {(time.perf_counter() - t0) * 1000:.0f}ms")

    return acc


def main():
    print("=" * 60)
    print("ENTRENAMIENTO MODELO COMPLETO (sintético + CSV real)")
    print("=" * 60)

    print("\n[1/3] Generando dataset sintético...")
    X_syn, y_syn = generate_dataset()
    print(f"  → {len(X_syn):,} registros sintéticos, {len(set(y_syn))} clases")

    print("\n[2/3] Cargando CSV real...")
    X_real, y_real = load_real_dataset()

    print("\n[3/3] Combinando datasets...")
    X = np.vstack([X_syn, X_real])
    y = y_syn + y_real
    print(f"  → TOTAL: {len(X):,} registros, {len(set(y))} clases únicas")

    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y_enc, test_size=0.15, random_state=42, stratify=y_enc
    )

    # HGB puro: rapido en inferencia, agnostico al tamaño del dataset
    # max_iter=600 + depth=8: balance velocidad/precisión, model.pkl ~30-50MB
    print("\nEntrenando HistGradientBoostingClassifier...")
    t0 = time.perf_counter()
    model = HistGradientBoostingClassifier(
        max_iter=600,
        learning_rate=0.05,
        max_depth=8,
        l2_regularization=0.1,
        early_stopping=True,
        validation_fraction=0.1,
        n_iter_no_change=15,
        random_state=42,
    )
    model.fit(X_train, y_train)
    print(f"Entrenamiento: {time.perf_counter() - t0:.1f}s")

    benchmark(model, X_test, y_test, le)

    out_pkl = 'model_full.pkl'
    out_le = 'label_encoder_full.pkl'
    out_feat = 'feature_names_full.json'

    with open(out_pkl, 'wb') as f:
        pickle.dump(model, f)
    with open(out_le, 'wb') as f:
        pickle.dump(le, f)
    with open(out_feat, 'w') as f:
        json.dump(SYMPTOM_COLS, f)

    size_mb = os.path.getsize(out_pkl) / 1024 / 1024
    print(f"\n{out_pkl}: {size_mb:.1f}MB · {len(SYMPTOM_COLS)} síntomas · {len(le.classes_)} clases")

    actual_size = os.path.getsize('model.pkl') / 1024 / 1024 if os.path.exists('model.pkl') else None
    if actual_size:
        print(f"Comparado con model.pkl actual: {actual_size:.1f}MB → {size_mb:.1f}MB ({(size_mb - actual_size):+.1f}MB)")

    print("\nListo. Para usar en producción: mv model_full.pkl model.pkl && mv label_encoder_full.pkl label_encoder.pkl")


if __name__ == '__main__':
    main()
