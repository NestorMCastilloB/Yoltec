"""Comprueba que el arranque local conserva secretos y no reutiliza los antiguos."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('openssl'), 'Requiere OpenSSL')
class LocalEnvironmentTest(unittest.TestCase):
    def test_inicializacion_privada_idempotente_sin_modificar_entornos_anteriores(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copy(ROOT / 'local.sh', root / 'local.sh')
            (root / 'backend').mkdir()
            old = root / 'backend/.env'
            old.write_text('APP_KEY=clave-antigua-ficticia\nDB_HOST=proveedor.invalid\n')
            (root / 'bin').mkdir()
            docker = root / 'bin/docker'
            docker.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$CALLS"\n')
            docker.chmod(0o755)
            env = {
                'PATH': str(root / 'bin') + os.pathsep + os.environ['PATH'],
                'CALLS': str(root / 'calls'),
            }
            command = ['/bin/bash', str(root / 'local.sh'), 'init']
            first = subprocess.run(command, env=env, capture_output=True, text=True, timeout=5)
            self.assertEqual(first.returncode, 0, first.stderr)
            generated = root / '.env.local'
            values = generated.read_text()
            self.assertEqual(generated.stat().st_mode & 0o777, 0o600)
            self.assertIn('LOCAL_APP_KEY=base64:', values)
            self.assertNotIn('clave-antigua', values)
            self.assertNotIn('LOCAL_APP_KEY=', first.stdout + first.stderr)

            second = subprocess.run(command, env=env, capture_output=True, text=True, timeout=5)
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertEqual(generated.read_text(), values)
            self.assertEqual(old.read_text(), 'APP_KEY=clave-antigua-ficticia\nDB_HOST=proveedor.invalid\n')
            self.assertIn('--project-name yoltec-local --env-file .env.local', (root / 'calls').read_text())


if __name__ == '__main__':
    unittest.main()
