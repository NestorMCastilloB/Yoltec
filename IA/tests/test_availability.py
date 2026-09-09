"""Verifica disponibilidad parcial sin enviar solicitudes a Groq."""

import os
import unittest
from unittest.mock import Mock, patch

os.environ['GROQ_API_KEY'] = ''

from fastapi.testclient import TestClient
import app as service


class AvailabilityTest(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(service.app)
        service.limiter.reset()
        service._groq_cache.update(ok=False, ts=0.0)

    def test_arranca_y_predice_sin_clave_de_groq(self):
        with patch.object(service, 'groq_client', None), self.client:
            self.client.get('/live').raise_for_status()
            response = self.client.get('/health')
            self.assertEqual(response.status_code, 503)
            self.assertEqual(response.json()['status'], 'degraded')
            self.assertTrue(response.json()['model_sklearn_loaded'])
            self.assertFalse(response.json()['llm_available'])
            prediction = self.client.post('/predict', json={'respuestas': {'fiebre': 'Sí'}})
            self.assertEqual(prediction.status_code, 200)
            self.assertTrue(prediction.json()['success'])

    def test_chat_sin_configurar_devuelve_503(self):
        with patch.object(service, 'groq_client', None):
            response = self.client.post('/chat', json={
                'messages': [{'role': 'user', 'content': 'Tengo tos desde ayer'}],
            })
            self.assertEqual(response.status_code, 503)

    def test_fallo_del_proveedor_se_refleja_en_health(self):
        provider = Mock()
        provider.models.list.side_effect = RuntimeError('Proveedor no disponible')
        with patch.object(service, 'groq_client', provider), patch.object(service, 'model', Mock()):
            response = self.client.get('/health')
            self.assertEqual(response.status_code, 503)
            self.assertFalse(response.json()['llm_available'])

    def test_health_sano_requiere_ambos_servicios_y_cachea_la_consulta(self):
        provider = Mock()
        with patch.object(service, 'groq_client', provider), patch.object(service, 'model', Mock()):
            for _ in range(2):
                response = self.client.get('/health')
                self.assertEqual(response.status_code, 200)
                self.assertTrue(response.json()['llm_available'])
            provider.models.list.assert_called_once()


if __name__ == '__main__':
    unittest.main()
