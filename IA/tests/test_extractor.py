"""Verifica el extractor de síntomas por reglas (no necesita modelo ni proveedor)."""

import json
import os
import unittest

import extractor

from extractor import (
    PREGUNTAS,
    SINONIMOS,
    SINONIMOS_NEGADOS,
    conversacion_terminada,
    extraer_de_conversacion,
    extraer_sintomas,
    siguiente_pregunta,
)


class ExtractorTest(unittest.TestCase):
    def test_reconoce_sintomas_en_lenguaje_natural(self):
        self.assertEqual(
            extraer_sintomas("Tengo fiebre y me duele mucho la cabeza desde ayer"),
            ['fiebre', 'dolor_cabeza'],
        )

    def test_tolera_intensificadores_entre_palabras(self):
        self.assertIn('dolor_abdominal', extraer_sintomas("me duele bien gacho la panza"))

    def test_la_negacion_descarta_el_sintoma(self):
        self.assertEqual(extraer_sintomas("no tengo fiebre"), [])
        self.assertEqual(extraer_sintomas("sin tos ni fiebre"), [])

    def test_la_negacion_no_alcanza_a_la_siguiente_clausula(self):
        self.assertEqual(
            extraer_sintomas("Me duele la cabeza pero no tengo fiebre"),
            ['dolor_cabeza'],
        )

    def test_la_negacion_no_alcanza_mas_alla_de_su_ventana(self):
        # El cansancio queda fuera del alcance del "no" de "no puedo dormir".
        self.assertEqual(
            extraer_sintomas("no puedo dormir y me siento muy cansado"),
            ['cansancio', 'insomnio'],
        )

    def test_los_sinonimos_que_llevan_negacion_dentro_sobreviven(self):
        self.assertEqual(extraer_sintomas("no tengo hambre"), ['perdida_apetito'])
        self.assertIn('vision_borrosa', extraer_sintomas("no veo bien de lejos"))

    def test_el_sintoma_especifico_implica_el_general(self):
        sintomas = extraer_sintomas("traigo calentura alta y tos seca")
        self.assertIn('fiebre_alta', sintomas)
        self.assertIn('fiebre', sintomas)
        self.assertIn('tos_seca', sintomas)
        self.assertIn('tos', sintomas)

    def test_no_confunde_ir_al_bano_a_orinar_con_diarrea(self):
        sintomas = extraer_sintomas("me arde al orinar y voy mucho al baño a orinar")
        self.assertNotIn('diarrea', sintomas)
        self.assertIn('dolor_orinar', sintomas)
        self.assertIn('frecuencia_orinar', sintomas)

    def test_texto_sin_sintomas_no_inventa_nada(self):
        self.assertEqual(extraer_sintomas("Hola, vengo a mi consulta de rutina"), [])
        self.assertEqual(extraer_sintomas(""), [])

    def test_ignora_acentos_y_mayusculas(self):
        self.assertEqual(extraer_sintomas("NÁUSEAS"), extraer_sintomas("nauseas"))

    def test_solo_lee_los_mensajes_del_estudiante(self):
        conversacion = [
            {'role': 'user', 'content': 'tengo tos'},
            {'role': 'assistant', 'content': '¿Tienes fiebre o dolor de cabeza?'},
            {'role': 'user', 'content': 'no, nada de eso'},
        ]
        # Ni la fiebre ni el dolor de cabeza los dijo el estudiante.
        self.assertEqual(extraer_de_conversacion(conversacion), ['tos'])

    def test_reconoce_sintomas_afirmados_al_negar_una_capacidad(self):
        self.assertEqual(extraer_sintomas("tampoco tengo hambre"), ['perdida_apetito'])
        self.assertEqual(extraer_sintomas("no he podido dormir"), ['insomnio'])
        self.assertEqual(extraer_sintomas("no huelo nada"), ['perdida_olfato'])

    def test_la_capacidad_afirmada_no_es_un_sintoma(self):
        self.assertEqual(extraer_sintomas("tengo hambre y duermo bien"), [])

    def test_la_negacion_no_cruza_a_una_oracion_con_sujeto_propio(self):
        # "y me enojo" abre oración nueva: el "tampoco" no la alcanza.
        self.assertEqual(
            extraer_sintomas("tampoco tengo hambre y me enojo por todo"),
            ['perdida_apetito', 'irritabilidad'],
        )

    def test_la_negacion_si_se_reparte_en_una_enumeracion(self):
        self.assertEqual(extraer_sintomas("no tengo fiebre y tos"), [])

    def test_tolera_verbos_de_enlace(self):
        self.assertIn('orina_turbia', extraer_sintomas("la orina sale turbia"))

    def test_desambigua_ir_al_bano_segun_el_contexto(self):
        self.assertIn('frecuencia_orinar', extraer_sintomas("me arde al orinar y voy mucho al baño"))
        self.assertIn('diarrea', extraer_sintomas("voy mucho al baño, traigo el estómago suelto"))
        # Sin pistas no se elige ninguno: es peor inventar el síntoma equivocado.
        self.assertEqual(extraer_sintomas("voy mucho al baño y ya no sé qué hacer"), [])

    def test_los_sintomas_son_exactamente_los_del_clasificador(self):
        ruta = os.path.join(os.path.dirname(extractor.__file__), 'feature_names.json')
        with open(ruta) as f:
            features = json.load(f)
        self.assertEqual(set(SINONIMOS), set(features))
        self.assertLessEqual(set(SINONIMOS_NEGADOS), set(features))

    def test_todo_sintoma_del_clasificador_se_reconoce_por_su_propio_nombre(self):
        for sintoma, frases in SINONIMOS.items():
            with self.subTest(sintoma=sintoma):
                self.assertIn(sintoma, extraer_sintomas(frases[0]))


class GuionTest(unittest.TestCase):
    def test_avanza_por_las_preguntas(self):
        self.assertEqual(siguiente_pregunta(0), PREGUNTAS[0])
        self.assertEqual(siguiente_pregunta(1), PREGUNTAS[1])

    def test_no_se_sale_del_guion(self):
        self.assertEqual(siguiente_pregunta(99), PREGUNTAS[-1])

    def test_cierra_tras_tres_respuestas(self):
        self.assertFalse(conversacion_terminada(2))
        self.assertTrue(conversacion_terminada(3))


if __name__ == '__main__':
    unittest.main()
