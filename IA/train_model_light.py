#!/usr/bin/env python3
"""
Modelo ligero para producción (Railway/Render).
Solo usa datos sintéticos, sin CSV de Kaggle.
Modelo: HistGradientBoosting — preciso y compacto (~10MB).
"""

import numpy as np
import json
import pickle
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import warnings
warnings.filterwarnings('ignore')

SYMPTOM_COLS = [
    'fiebre', 'tos', 'tos_seca', 'dolor_garganta', 'congestion_nasal',
    'estornudos', 'dolor_cabeza', 'dolor_cuerpo', 'cansancio', 'nauseas',
    'vomito', 'diarrea', 'dolor_abdominal', 'perdida_apetito', 'perdida_olfato',
    'erupcion_piel', 'picazon', 'ojos_rojos', 'lagrimeo', 'dolor_orinar',
    'frecuencia_orinar', 'mareos', 'palpitaciones', 'sensibilidad_luz',
    'dolor_articulaciones', 'sudoracion', 'escalofrios', 'dolor_espalda',
    'dificultad_respirar', 'fiebre_alta', 'sangre_orina', 'orina_turbia',
    'confusion', 'rigidez_cuello',
]


def make(disease, base, n=1000, noise=0.08):
    records, labels = [], []
    for _ in range(n):
        row = []
        for col in SYMPTOM_COLS:
            prob = base.get(col, 0.03)
            val = 1 if np.random.random() < np.clip(prob + np.random.uniform(-noise, noise), 0, 1) else 0
            row.append(val)
        records.append(row)
        labels.append(disease)
    return records, labels


def generate_dataset():
    np.random.seed(42)
    all_records, all_labels = [], []

    enfermedades = [
        ('COVID-19', {
            'fiebre': 0.85, 'tos': 0.80, 'tos_seca': 0.78, 'cansancio': 0.82,
            'perdida_olfato': 0.72, 'dolor_cabeza': 0.65, 'dolor_cuerpo': 0.60,
            'dificultad_respirar': 0.50, 'dolor_garganta': 0.40, 'nauseas': 0.25,
        }, 1200),
        ('Chikungunya', {
            'fiebre': 0.95, 'fiebre_alta': 0.85, 'dolor_articulaciones': 0.97,
            'erupcion_piel': 0.72, 'dolor_cabeza': 0.65, 'dolor_cuerpo': 0.72,
            'nauseas': 0.40, 'cansancio': 0.62, 'escalofrios': 0.52,
        }, 1000),
        ('Dengue', {
            'fiebre': 0.96, 'fiebre_alta': 0.90, 'dolor_cabeza': 0.87,
            'dolor_cuerpo': 0.92, 'dolor_articulaciones': 0.72, 'erupcion_piel': 0.62,
            'nauseas': 0.62, 'vomito': 0.42, 'cansancio': 0.78, 'escalofrios': 0.57,
            'dolor_abdominal': 0.37,
        }, 1200),
        ('Zika', {
            'fiebre': 0.80, 'erupcion_piel': 0.92, 'ojos_rojos': 0.72,
            'dolor_articulaciones': 0.62, 'dolor_cabeza': 0.55, 'cansancio': 0.52,
            'picazon': 0.68, 'lagrimeo': 0.47,
        }, 900),
        ('Paludismo', {
            'fiebre': 0.96, 'fiebre_alta': 0.87, 'escalofrios': 0.92,
            'sudoracion': 0.87, 'dolor_cabeza': 0.82, 'dolor_cuerpo': 0.77,
            'nauseas': 0.67, 'vomito': 0.57, 'cansancio': 0.82,
        }, 1000),
        ('Gripe', {
            'fiebre': 0.90, 'tos': 0.85, 'dolor_garganta': 0.70,
            'congestion_nasal': 0.65, 'dolor_cabeza': 0.75, 'dolor_cuerpo': 0.80,
            'cansancio': 0.82, 'escalofrios': 0.70,
        }, 1200),
        ('Resfriado Común', {
            'congestion_nasal': 0.92, 'estornudos': 0.88, 'dolor_garganta': 0.72,
            'tos': 0.68, 'cansancio': 0.55,
        }, 1200),
        ('Bronquitis Aguda', {
            'tos': 0.95, 'tos_seca': 0.80, 'fiebre': 0.60, 'cansancio': 0.70,
            'dificultad_respirar': 0.55, 'dolor_garganta': 0.45, 'dolor_cuerpo': 0.50,
        }, 900),
        ('Sinusitis', {
            'congestion_nasal': 0.92, 'dolor_cabeza': 0.88, 'dolor_garganta': 0.55,
            'fiebre': 0.50, 'cansancio': 0.60, 'estornudos': 0.65,
        }, 900),
        ('Infección de Garganta', {
            'dolor_garganta': 0.97, 'fiebre': 0.78, 'cansancio': 0.65,
            'dolor_cabeza': 0.55, 'congestion_nasal': 0.35, 'tos': 0.45,
            'perdida_apetito': 0.50,
        }, 1000),
        ('Gastroenteritis', {
            'nauseas': 0.90, 'vomito': 0.85, 'diarrea': 0.92, 'dolor_abdominal': 0.80,
            'fiebre': 0.65, 'cansancio': 0.70,
        }, 1000),
        ('Colitis', {
            'dolor_abdominal': 0.92, 'diarrea': 0.88, 'nauseas': 0.62,
            'perdida_apetito': 0.67, 'cansancio': 0.57, 'vomito': 0.37,
            'fiebre': 0.40,
        }, 900),
        ('Intoxicación Alimentaria', {
            'nauseas': 0.92, 'vomito': 0.88, 'diarrea': 0.83, 'dolor_abdominal': 0.78,
            'fiebre': 0.57, 'cansancio': 0.62, 'dolor_cuerpo': 0.42,
        }, 900),
        ('Reflujo Gástrico', {
            'dolor_abdominal': 0.85, 'nauseas': 0.70, 'cansancio': 0.45,
            'perdida_apetito': 0.55, 'vomito': 0.40,
        }, 800),
        ('Infección Urinaria', {
            'dolor_orinar': 0.95, 'frecuencia_orinar': 0.90, 'orina_turbia': 0.70,
            'fiebre': 0.55, 'dolor_abdominal': 0.50, 'sangre_orina': 0.35,
        }, 900),
        ('Migraña', {
            'dolor_cabeza': 0.98, 'sensibilidad_luz': 0.85, 'nauseas': 0.72,
            'vomito': 0.45, 'mareos': 0.60,
        }, 900),
        ('Conjuntivitis', {
            'ojos_rojos': 0.97, 'lagrimeo': 0.88, 'picazon': 0.72,
            'dolor_cabeza': 0.30, 'cansancio': 0.25,
        }, 800),
        ('Dermatitis Alérgica', {
            'picazon': 0.95, 'erupcion_piel': 0.90, 'ojos_rojos': 0.40,
            'cansancio': 0.35, 'estornudos': 0.30,
        }, 800),
        ('Escabiosis', {
            'picazon': 0.97, 'erupcion_piel': 0.90, 'ojos_rojos': 0.20,
            'cansancio': 0.35,
        }, 800),
        ('Varicela', {
            'erupcion_piel': 0.97, 'picazon': 0.92, 'fiebre': 0.78,
            'cansancio': 0.65, 'dolor_cabeza': 0.55, 'perdida_apetito': 0.50,
        }, 800),
        ('Anemia', {
            'cansancio': 0.92, 'mareos': 0.80, 'dolor_cabeza': 0.70,
            'palpitaciones': 0.60, 'perdida_apetito': 0.55, 'dificultad_respirar': 0.45,
        }, 800),
        ('Hipertensión', {
            'dolor_cabeza': 0.85, 'mareos': 0.75, 'palpitaciones': 0.65,
            'cansancio': 0.55, 'dificultad_respirar': 0.40,
        }, 800),
        ('Hipoglucemia', {
            'mareos': 0.90, 'cansancio': 0.85, 'sudoracion': 0.80,
            'palpitaciones': 0.70, 'confusion': 0.55, 'dolor_cabeza': 0.60,
        }, 800),
        ('Golpe de Calor', {
            'fiebre_alta': 0.92, 'fiebre': 0.88, 'sudoracion': 0.80,
            'mareos': 0.78, 'dolor_cabeza': 0.75, 'cansancio': 0.80,
            'confusion': 0.45, 'nauseas': 0.55,
        }, 800),
    ]

    for nombre, base, n in enfermedades:
        r, l = make(nombre, base, n=n)
        all_records.extend(r)
        all_labels.extend(l)

    print(f"Dataset generado: {len(all_records):,} registros, {len(set(all_labels))} enfermedades")
    return np.array(all_records), all_labels


def main():
    X, y = generate_dataset()

    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y_enc, test_size=0.15, random_state=42, stratify=y_enc
    )

    print("Entrenando HistGradientBoostingClassifier...")
    model = HistGradientBoostingClassifier(
        max_iter=200, learning_rate=0.05,
        max_depth=6, l2_regularization=0.1,
        random_state=42,
    )
    model.fit(X_train, y_train)

    acc = accuracy_score(y_test, model.predict(X_test))
    print(f"Precisión: {acc:.2%}")

    with open('model.pkl', 'wb') as f:
        pickle.dump(model, f)
    with open('label_encoder.pkl', 'wb') as f:
        pickle.dump(le, f)
    with open('feature_names.json', 'w') as f:
        json.dump(SYMPTOM_COLS, f)

    import os
    size_mb = os.path.getsize('model.pkl') / 1024 / 1024
    print(f"model.pkl: {size_mb:.1f} MB")
    print("Listo.")


if __name__ == '__main__':
    main()
