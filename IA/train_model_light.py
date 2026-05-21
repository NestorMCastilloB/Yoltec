#!/usr/bin/env python3
"""
Modelo ligero para producción (Render).
Dataset sintético expandido: ~50 enfermedades + 2 clases especiales (Trauma/Lesión, Sin Patrón Claro).
Modelo: HistGradientBoostingClassifier.
"""

import numpy as np
import json
import pickle
import os
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import warnings
warnings.filterwarnings('ignore')

SYMPTOM_COLS = [
    # respiratorios / generales
    'fiebre', 'fiebre_alta', 'tos', 'tos_seca', 'dolor_garganta',
    'congestion_nasal', 'estornudos', 'dificultad_respirar',
    # neurológicos
    'dolor_cabeza', 'mareos', 'confusion', 'sensibilidad_luz',
    'rigidez_cuello', 'perdida_balance', 'hormigueo', 'desmayo',
    # musculoesqueléticos
    'dolor_cuerpo', 'dolor_articulaciones', 'dolor_espalda',
    'dolor_pecho', 'debilidad_muscular',
    # digestivos
    'nauseas', 'vomito', 'diarrea', 'dolor_abdominal',
    'perdida_apetito', 'ardor_estomago', 'estrenimiento',
    # urinarios / ginecológicos
    'dolor_orinar', 'frecuencia_orinar', 'sangre_orina', 'orina_turbia',
    'dolor_menstrual', 'sangrado_anormal',
    # dermatológicos
    'erupcion_piel', 'picazon', 'hinchazon', 'enrojecimiento',
    # oftálmicos / óticos
    'ojos_rojos', 'lagrimeo', 'vision_borrosa', 'dolor_oido', 'secrecion_oido',
    # otros sistémicos
    'cansancio', 'sudoracion', 'escalofrios', 'perdida_olfato',
    'palpitaciones', 'sequedad_boca', 'deshidratacion',
    # mental / conductual
    'ansiedad', 'insomnio', 'irritabilidad', 'tristeza_persistente',
    # trauma / emergencia
    'sangrado_severo', 'golpe_reciente', 'quemadura',
]


def make(disease, base, n=1000, noise=0.04):
    """Genera n registros para `disease` perturbando las probabilidades base."""
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


def make_random(disease, n, low=0.02, high=0.18):
    """Patrones aleatorios bajos — clase 'Sin Patrón Claro' para inputs ambiguos."""
    records, labels = [], []
    for _ in range(n):
        row = [1 if np.random.random() < np.random.uniform(low, high) else 0 for _ in SYMPTOM_COLS]
        records.append(row)
        labels.append(disease)
    return records, labels


def generate_dataset():
    np.random.seed(42)
    all_records, all_labels = [], []

    enfermedades = [
        # ── Virales transmitidas por mosquito (Huasteca) ──
        # Dengue: distintivo por sensibilidad retro-orbital + sangrado leve + fiebre muy alta
        ('Dengue', {
            'fiebre': 0.97, 'fiebre_alta': 0.92, 'dolor_cabeza': 0.90,
            'dolor_cuerpo': 0.93, 'dolor_articulaciones': 0.72, 'erupcion_piel': 0.65,
            'nauseas': 0.65, 'vomito': 0.45, 'cansancio': 0.82, 'escalofrios': 0.58,
            'dolor_abdominal': 0.40, 'sensibilidad_luz': 0.75, 'sangrado_anormal': 0.38,
            'vision_borrosa': 0.35,
        }, 1500),
        # Chikungunya: distintivo por dolor articular EXTREMO + hinchazón articular
        ('Chikungunya', {
            'fiebre': 0.95, 'fiebre_alta': 0.85, 'dolor_articulaciones': 0.99,
            'erupcion_piel': 0.72, 'dolor_cabeza': 0.62, 'dolor_cuerpo': 0.70,
            'nauseas': 0.40, 'cansancio': 0.62, 'escalofrios': 0.52,
            'hinchazon': 0.70, 'debilidad_muscular': 0.55,
        }, 1300),
        ('Zika', {
            'fiebre': 0.78, 'erupcion_piel': 0.94, 'ojos_rojos': 0.85,
            'dolor_articulaciones': 0.62, 'dolor_cabeza': 0.55, 'cansancio': 0.52,
            'picazon': 0.72, 'lagrimeo': 0.55, 'enrojecimiento': 0.55,
        }, 1100),
        ('Paludismo', {
            'fiebre': 0.97, 'fiebre_alta': 0.90, 'escalofrios': 0.95,
            'sudoracion': 0.92, 'dolor_cabeza': 0.82, 'dolor_cuerpo': 0.77,
            'nauseas': 0.67, 'vomito': 0.57, 'cansancio': 0.82,
        }, 1100),

        # ── Respiratorias agudas ──
        # COVID-19: distintivo por pérdida olfato/gusto + tos seca
        ('COVID-19', {
            'fiebre': 0.82, 'tos': 0.78, 'tos_seca': 0.85, 'cansancio': 0.82,
            'perdida_olfato': 0.88, 'dolor_cabeza': 0.60, 'dolor_cuerpo': 0.55,
            'dificultad_respirar': 0.55, 'dolor_garganta': 0.38, 'nauseas': 0.22,
        }, 1500),
        # Gripe: distintivo por dolor cuerpo intenso + escalofríos + sin pérdida olfato
        ('Gripe', {
            'fiebre': 0.92, 'tos': 0.82, 'dolor_garganta': 0.70,
            'congestion_nasal': 0.65, 'dolor_cabeza': 0.78, 'dolor_cuerpo': 0.92,
            'cansancio': 0.85, 'escalofrios': 0.82, 'debilidad_muscular': 0.55,
        }, 1500),
        ('Resfriado Común', {
            'congestion_nasal': 0.95, 'estornudos': 0.92, 'dolor_garganta': 0.72,
            'tos': 0.65, 'cansancio': 0.50,
        }, 1500),
        ('Bronquitis Aguda', {
            'tos': 0.97, 'tos_seca': 0.85, 'fiebre': 0.60, 'cansancio': 0.72,
            'dificultad_respirar': 0.60, 'dolor_garganta': 0.42, 'dolor_cuerpo': 0.45,
            'dolor_pecho': 0.50,
        }, 1100),
        ('Sinusitis', {
            'congestion_nasal': 0.95, 'dolor_cabeza': 0.92, 'dolor_garganta': 0.50,
            'fiebre': 0.45, 'cansancio': 0.60, 'estornudos': 0.55,
        }, 1100),
        # Faringoamigdalitis: fusión de Faringitis Bacteriana + Amigdalitis
        ('Faringoamigdalitis', {
            'dolor_garganta': 0.98, 'fiebre': 0.85, 'cansancio': 0.68,
            'dolor_cabeza': 0.58, 'congestion_nasal': 0.25, 'tos': 0.30,
            'perdida_apetito': 0.60, 'enrojecimiento': 0.70, 'hinchazon': 0.45,
        }, 1800),
        # Mononucleosis: distintivo por cansancio EXTREMO + hinchazón ganglionar + debilidad prolongada
        ('Mononucleosis', {
            'dolor_garganta': 0.88, 'cansancio': 0.98, 'fiebre': 0.78,
            'dolor_cuerpo': 0.78, 'dolor_cabeza': 0.55, 'hinchazon': 0.90,
            'perdida_apetito': 0.72, 'debilidad_muscular': 0.85,
            'dolor_articulaciones': 0.45,
        }, 1100),
        ('Neumonía Leve', {
            'tos': 0.90, 'fiebre': 0.85, 'fiebre_alta': 0.55,
            'dificultad_respirar': 0.75, 'dolor_pecho': 0.65, 'cansancio': 0.85,
            'escalofrios': 0.60, 'dolor_cuerpo': 0.55,
        }, 1000),
        # Asma: distintivo por dificultad respirar MUY alta + palpitaciones + sin fiebre
        ('Asma Bronquial Leve', {
            'tos_seca': 0.78, 'dificultad_respirar': 0.95, 'dolor_pecho': 0.65,
            'palpitaciones': 0.60, 'cansancio': 0.55, 'ansiedad': 0.40,
        }, 1000),
        ('Alergia Estacional', {
            'estornudos': 0.92, 'congestion_nasal': 0.85, 'picazon': 0.55,
            'ojos_rojos': 0.60, 'lagrimeo': 0.70, 'dolor_cabeza': 0.40,
            'tos_seca': 0.40,
        }, 1100),

        # ── Digestivas ──
        # Gastroenteritis + Intoxicación: clínicamente mismo manejo (rehidratación)
        ('Gastroenteritis / Intoxicación', {
            'nauseas': 0.92, 'vomito': 0.86, 'diarrea': 0.90, 'dolor_abdominal': 0.80,
            'fiebre': 0.62, 'cansancio': 0.68, 'deshidratacion': 0.55,
            'dolor_cuerpo': 0.30, 'perdida_apetito': 0.55,
        }, 2400),
        ('Colitis', {
            'dolor_abdominal': 0.94, 'diarrea': 0.92, 'nauseas': 0.55,
            'perdida_apetito': 0.70, 'cansancio': 0.55, 'vomito': 0.25,
            'fiebre': 0.35, 'sangre_orina': 0.08,
        }, 1100),
        # Gastritis + Reflujo: clínicamente mismo tratamiento (omeprazol, dieta)
        ('Gastritis / Reflujo', {
            'dolor_abdominal': 0.88, 'ardor_estomago': 0.95, 'nauseas': 0.72,
            'perdida_apetito': 0.62, 'vomito': 0.32, 'cansancio': 0.45,
            'sequedad_boca': 0.30,
        }, 2100),
        ('Estreñimiento Funcional', {
            'estrenimiento': 0.95, 'dolor_abdominal': 0.70, 'perdida_apetito': 0.45,
            'cansancio': 0.40, 'hinchazon': 0.55,
        }, 800),

        # ── Urinarias / ginecológicas ──
        # Infección Urinaria: fusión de Cistitis + IVU (clínicamente mismo tratamiento)
        ('Infección Urinaria', {
            'dolor_orinar': 0.96, 'frecuencia_orinar': 0.92, 'orina_turbia': 0.72,
            'fiebre': 0.50, 'dolor_abdominal': 0.55, 'sangre_orina': 0.30,
        }, 2000),
        ('Cólico Menstrual', {
            'dolor_menstrual': 0.95, 'dolor_abdominal': 0.80, 'dolor_espalda': 0.55,
            'cansancio': 0.60, 'nauseas': 0.40, 'irritabilidad': 0.45,
        }, 900),
        ('Vaginitis', {
            'picazon': 0.78, 'sangrado_anormal': 0.55, 'dolor_orinar': 0.50,
            'enrojecimiento': 0.60, 'dolor_abdominal': 0.45,
        }, 800),

        # ── Neurológicas / dolor ──
        # Migraña: distintivo por sensibilidad luz fuerte + aura (visión borrosa) + náusea
        ('Migraña', {
            'dolor_cabeza': 0.98, 'sensibilidad_luz': 0.95, 'nauseas': 0.78,
            'vomito': 0.50, 'mareos': 0.55, 'vision_borrosa': 0.70,
            'irritabilidad': 0.30,
        }, 1100),
        # Cefalea Tensional: dolor cabeza dominante + rigidez cuello + dolor espalda (sin insomnio dominante, sin tristeza)
        ('Cefalea Tensional', {
            'dolor_cabeza': 0.98, 'rigidez_cuello': 0.60, 'dolor_espalda': 0.55,
            'cansancio': 0.55, 'irritabilidad': 0.40, 'dolor_cuerpo': 0.30,
        }, 1000),
        ('Vértigo Postural', {
            'mareos': 0.95, 'perdida_balance': 0.88, 'nauseas': 0.55,
            'vomito': 0.30, 'dolor_cabeza': 0.40, 'vision_borrosa': 0.35,
        }, 900),
        ('Lumbalgia', {
            'dolor_espalda': 0.97, 'dolor_cuerpo': 0.55, 'debilidad_muscular': 0.50,
            'hormigueo': 0.35, 'cansancio': 0.45,
        }, 1000),

        # ── Oftálmicas / óticas ──
        ('Conjuntivitis', {
            'ojos_rojos': 0.97, 'lagrimeo': 0.88, 'picazon': 0.72,
            'dolor_cabeza': 0.30, 'cansancio': 0.25, 'enrojecimiento': 0.80,
        }, 900),
        ('Otitis Media', {
            'dolor_oido': 0.95, 'secrecion_oido': 0.55, 'fiebre': 0.65,
            'dolor_cabeza': 0.50, 'cansancio': 0.55, 'irritabilidad': 0.40,
        }, 900),
        ('Otitis Externa', {
            'dolor_oido': 0.92, 'picazon': 0.60, 'enrojecimiento': 0.65,
            'secrecion_oido': 0.50, 'hinchazon': 0.45,
        }, 800),

        # ── Dermatológicas ──
        # Reacción Dérmica: fusión Alérgica + Contacto + Picadura (mismo manejo sintomático)
        ('Reacción Dérmica', {
            'picazon': 0.93, 'erupcion_piel': 0.88, 'enrojecimiento': 0.85,
            'hinchazon': 0.65, 'cansancio': 0.25,
        }, 2200),
        ('Escabiosis', {
            'picazon': 0.98, 'erupcion_piel': 0.92, 'insomnio': 0.60,
            'cansancio': 0.30,
        }, 800),
        ('Varicela', {
            'erupcion_piel': 0.97, 'picazon': 0.92, 'fiebre': 0.78,
            'cansancio': 0.65, 'dolor_cabeza': 0.55, 'perdida_apetito': 0.50,
        }, 800),
        ('Quemadura Solar', {
            'enrojecimiento': 0.95, 'dolor_cuerpo': 0.65, 'picazon': 0.40,
            'cansancio': 0.45, 'sequedad_boca': 0.45, 'deshidratacion': 0.55,
            'quemadura': 0.80,
        }, 800),

        # ── Sistémicas / metabólicas ──
        ('Anemia', {
            'cansancio': 0.92, 'mareos': 0.80, 'dolor_cabeza': 0.70,
            'palpitaciones': 0.60, 'perdida_apetito': 0.55, 'dificultad_respirar': 0.45,
            'debilidad_muscular': 0.65,
        }, 900),
        ('Hipertensión Arterial', {
            'dolor_cabeza': 0.85, 'mareos': 0.75, 'palpitaciones': 0.65,
            'cansancio': 0.55, 'dificultad_respirar': 0.40, 'vision_borrosa': 0.35,
        }, 900),
        # Hipotensión: distintivo por desmayo + visión borrosa al levantarse
        ('Hipotensión', {
            'mareos': 0.95, 'cansancio': 0.78, 'desmayo': 0.78,
            'vision_borrosa': 0.65, 'palpitaciones': 0.35, 'sudoracion': 0.45,
            'debilidad_muscular': 0.55,
        }, 800),
        ('Hipoglucemia', {
            'mareos': 0.90, 'cansancio': 0.85, 'sudoracion': 0.80,
            'palpitaciones': 0.70, 'confusion': 0.55, 'dolor_cabeza': 0.60,
            'irritabilidad': 0.55, 'debilidad_muscular': 0.60,
        }, 900),
        ('Golpe de Calor / Insolación', {
            'fiebre_alta': 0.92, 'fiebre': 0.88, 'sudoracion': 0.80,
            'mareos': 0.78, 'dolor_cabeza': 0.75, 'cansancio': 0.80,
            'confusion': 0.45, 'nauseas': 0.55, 'deshidratacion': 0.85,
            'sequedad_boca': 0.70, 'enrojecimiento': 0.55,
        }, 900),
        ('Deshidratación', {
            'sequedad_boca': 0.92, 'deshidratacion': 0.95, 'mareos': 0.65,
            'cansancio': 0.75, 'dolor_cabeza': 0.55, 'palpitaciones': 0.40,
        }, 800),

        # ── Mental / conductual (estudiantes) ──
        # Ansiedad: distintivo por palpitaciones + sudoración + dolor pecho + sequedad boca (cuerpo en alerta)
        ('Ansiedad', {
            'ansiedad': 0.97, 'palpitaciones': 0.88, 'sudoracion': 0.78,
            'dolor_pecho': 0.65, 'sequedad_boca': 0.70, 'irritabilidad': 0.55,
            'cansancio': 0.40, 'mareos': 0.45,
        }, 1100),
        # Insomnio: distintivo por insomnio puro + cansancio (sin ansiedad ni dolor cabeza fuerte)
        ('Insomnio', {
            'insomnio': 0.98, 'cansancio': 0.92, 'irritabilidad': 0.55,
            'dolor_cabeza': 0.20, 'sequedad_boca': 0.25,
        }, 900),
        # Estrés Académico: distintivo por ansiedad + dolor cabeza + dolor espalda + perdida apetito (no insomnio dominante)
        ('Estrés Académico', {
            'ansiedad': 0.85, 'dolor_cabeza': 0.85, 'cansancio': 0.78,
            'irritabilidad': 0.75, 'dolor_espalda': 0.70, 'perdida_apetito': 0.55,
            'insomnio': 0.40,
        }, 1000),
        # Depresión Leve: distintivo por tristeza dominante + perdida apetito + sin dolor cabeza ni ansiedad
        ('Depresión Leve', {
            'tristeza_persistente': 0.97, 'cansancio': 0.92, 'perdida_apetito': 0.78,
            'insomnio': 0.45, 'irritabilidad': 0.40, 'debilidad_muscular': 0.45,
        }, 1000),

        # ── Infecciones generales ──
        ('Infección Viral Inespecífica', {
            'fiebre': 0.65, 'dolor_cuerpo': 0.65, 'cansancio': 0.75,
            'dolor_cabeza': 0.55, 'escalofrios': 0.40, 'perdida_apetito': 0.45,
        }, 1000),

        # ── Emergencias abdominales ──
        # Apendicitis: dolor abdominal SEVERO + fiebre + náusea + pérdida apetito + SIN diarrea (distinguir de gastroenteritis)
        ('Apendicitis (Posible)', {
            'dolor_abdominal': 0.98, 'fiebre': 0.78, 'nauseas': 0.85,
            'vomito': 0.55, 'perdida_apetito': 0.90, 'cansancio': 0.55,
            'escalofrios': 0.40, 'sudoracion': 0.45, 'dolor_espalda': 0.30,
        }, 1100),

        # ── Clases especiales (manejo OOD) ──
        ('Trauma o Lesión Física', {
            'golpe_reciente': 0.92, 'dolor_cuerpo': 0.70, 'dolor_espalda': 0.55,
            'dolor_articulaciones': 0.55, 'hinchazon': 0.55, 'enrojecimiento': 0.50,
            'sangrado_severo': 0.40, 'debilidad_muscular': 0.35, 'mareos': 0.30,
            'confusion': 0.20, 'dolor_pecho': 0.25, 'quemadura': 0.20,
        }, 1500),
    ]

    for nombre, base, n in enfermedades:
        r, l = make(nombre, base, n=n)
        all_records.extend(r)
        all_labels.extend(l)

    # Clase "Sin Patrón Claro" — síntomas aleatorios bajos para no forzar predicción
    r, l = make_random('Sin Patrón Claro', n=1500)
    all_records.extend(r)
    all_labels.extend(l)

    print(f"Dataset generado: {len(all_records):,} registros, {len(set(all_labels))} clases")
    return np.array(all_records), all_labels


def main():
    X, y = generate_dataset()

    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y_enc, test_size=0.15, random_state=42, stratify=y_enc
    )

    print("Entrenando HistGradientBoostingClassifier...")
    # max_iter=900 + lr=0.03 + depth=10: máxima precisión sin overfitting, model.pkl ~50-80MB
    model = HistGradientBoostingClassifier(
        max_iter=900, learning_rate=0.03,
        max_depth=10, l2_regularization=0.05,
        random_state=42,
    )
    model.fit(X_train, y_train)

    acc = accuracy_score(y_test, model.predict(X_test))
    print(f"Precisión global: {acc:.2%}")

    with open('model.pkl', 'wb') as f:
        pickle.dump(model, f)
    with open('label_encoder.pkl', 'wb') as f:
        pickle.dump(le, f)
    with open('feature_names.json', 'w') as f:
        json.dump(SYMPTOM_COLS, f)

    size_mb = os.path.getsize('model.pkl') / 1024 / 1024
    print(f"model.pkl: {size_mb:.1f} MB · {len(SYMPTOM_COLS)} síntomas · {len(le.classes_)} clases")
    print("Listo.")


if __name__ == '__main__':
    main()
