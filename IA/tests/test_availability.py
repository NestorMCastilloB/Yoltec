"""Verifica la disponibilidad del servicio sin enviar solicitudes a Groq."""

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
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json()['status'], 'ok')
            self.assertTrue(response.json()['model_sklearn_loaded'])
            self.assertFalse(response.json()['llm_available'])
            prediction = self.client.post('/predict', json={'respuestas': {'fiebre': 'Sí'}})
            self.assertEqual(prediction.status_code, 200)
            self.assertTrue(prediction.json()['success'])

    def test_fallo_del_proveedor_no_tumba_el_servicio(self):
        provider = Mock()
        provider.models.list.side_effect = RuntimeError('Proveedor no disponible')
        with patch.object(service, 'groq_client', provider), patch.object(service, 'model', Mock()):
            response = self.client.get('/health')
            self.assertEqual(response.status_code, 200)
            self.assertFalse(response.json()['llm_available'])
            self.assertEqual(response.json()['modo_chat'], 'guiado')

    def test_health_cachea_la_consulta_al_proveedor(self):
        provider = Mock()
        with patch.object(service, 'groq_client', provider), patch.object(service, 'model', Mock()):
            for _ in range(2):
                response = self.client.get('/health')
                self.assertEqual(response.status_code, 200)
                self.assertTrue(response.json()['llm_available'])
            provider.models.list.assert_called_once()


if __name__ == '__main__':
    unittest.main()
