"""El chat sigue dando pre-evaluación cuando el proveedor de LLM no está."""

import os
import unittest
from unittest.mock import Mock, patch

os.environ['GROQ_API_KEY'] = ''

from fastapi.testclient import TestClient
import app as service


def conversacion(*textos):
    """Historial con las respuestas del estudiante intercaladas con preguntas."""
    mensajes = []
    for texto in textos:
        mensajes.append({'role': 'user', 'content': texto})
        mensajes.append({'role': 'assistant', 'content': '¿Algo más?'})
    return mensajes[:-1]


class ChatGuiadoTest(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(service.app)
        service.limiter.reset()
        service._groq_cache.update(ok=False, ts=0.0)

    def test_sin_proveedor_pregunta_en_vez_de_fallar(self):
        with patch.object(service, 'groq_client', None):
            respuesta = self.client.post('/chat', json={'messages': conversacion('tengo tos')})
        self.assertEqual(respuesta.status_code, 200)
        cuerpo = respuesta.json()
        self.assertFalse(cuerpo['finished'])
        self.assertIn('?', cuerpo['message'])
        self.assertIsNone(cuerpo['diagnostico'])

    def test_sin_proveedor_cierra_con_diagnostico_del_clasificador(self):
        with patch.object(service, 'groq_client', None):
            respuesta = self.client.post('/chat', json={'messages': conversacion(
                'tengo mucha tos y me duele la garganta',
                'desde hace tres dias, va empeorando',
                'tambien traigo calentura y escurrimiento nasal',
            )})
        self.assertEqual(respuesta.status_code, 200)
        cuerpo = respuesta.json()
        self.assertTrue(cuerpo['finished'])
        diagnostico = cuerpo['diagnostico']
        self.assertIn('tos', diagnostico['sintomas_detectados'])
        self.assertIn('fiebre', diagnostico['sintomas_detectados'])
        self.assertIn('dolor_garganta', diagnostico['sintomas_detectados'])
        self.assertTrue(diagnostico['posibles_enfermedades'])
        self.assertNotEqual(diagnostico['diagnostico_principal'], 'Evaluación preliminar')

    def test_sin_sintomas_reconocibles_no_inventa_diagnostico(self):
        with patch.object(service, 'groq_client', None):
            respuesta = self.client.post('/chat', json={'messages': conversacion(
                'vengo por mi revision anual', 'todo bien', 'nada mas eso',
            )})
        cuerpo = respuesta.json()
        self.assertTrue(cuerpo['finished'])
        self.assertEqual(cuerpo['diagnostico']['diagnostico_principal'], 'Sin diagnóstico claro')
        self.assertEqual(cuerpo['diagnostico']['sintomas_detectados'], [])

    def test_si_el_proveedor_falla_se_degrada_en_vez_de_romper(self):
        proveedor = Mock()
        proveedor.chat.completions.create.side_effect = RuntimeError('429 rate limit')
        with patch.object(service, 'groq_client', proveedor):
            respuesta = self.client.post('/chat', json={'messages': conversacion(
                'me duele la cabeza y tengo nauseas',
                'desde ayer en la noche',
                'tambien ando mareado',
            )})
        self.assertEqual(respuesta.status_code, 200)
        cuerpo = respuesta.json()
        self.assertTrue(cuerpo['finished'])
        self.assertIn('mareos', cuerpo['diagnostico']['sintomas_detectados'])

    def test_la_confianza_nunca_se_presenta_como_certeza(self):
        with patch.object(service, 'groq_client', None):
            respuesta = self.client.post('/chat', json={'messages': conversacion(
                'me arde al orinar y voy mucho al bano',
                'empezo ayer en la tarde',
                'no tengo fiebre pero la orina sale turbia',
            )})
        diagnostico = respuesta.json()['diagnostico']
        self.assertEqual(diagnostico['diagnostico_principal'], 'Infección Urinaria')
        self.assertLessEqual(diagnostico['confianza'], service.CONFIANZA_MAX)
        for posible in diagnostico['posibles_enfermedades']:
            self.assertLessEqual(posible['confianza'], service.CONFIANZA_MAX)

    def test_la_emergencia_sigue_teniendo_prioridad(self):
        with patch.object(service, 'groq_client', None):
            respuesta = self.client.post('/chat', json={
                'messages': [{'role': 'user', 'content': 'me atropellaron y sangro mucho'}],
            })
        cuerpo = respuesta.json()
        self.assertTrue(cuerpo['finished'])
        self.assertEqual(cuerpo['diagnostico']['diagnostico_principal'], 'Emergencia / Trauma')

    def test_health_sano_sin_proveedor_y_declara_el_modo(self):
        with patch.object(service, 'groq_client', None), self.client:
            respuesta = self.client.get('/health')
        self.assertEqual(respuesta.status_code, 200)
        cuerpo = respuesta.json()
        self.assertEqual(cuerpo['status'], 'ok')
        self.assertEqual(cuerpo['modo_chat'], 'guiado')
        self.assertFalse(cuerpo['llm_available'])

    def test_sin_clasificador_el_servicio_si_esta_degradado(self):
        with patch.object(service, 'model', None), patch.object(service, 'groq_client', None):
            respuesta = self.client.get('/health')
        self.assertEqual(respuesta.status_code, 503)
        self.assertEqual(respuesta.json()['status'], 'degraded')


if __name__ == '__main__':
    unittest.main()
