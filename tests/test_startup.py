"""Pruebas de arranque sin proveedores, credenciales ni base de datos reales."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EntrypointTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.calls = self.directory / "calls"
        php = self.directory / "php"
        php.write_text(
            '#!/bin/sh\n'
            'echo "$*" >> "$CALLS"\n'
            'if [ "$*" = "artisan config:clear" ] && [ "${FAIL_CONFIG:-}" = 1 ]; then exit 7; fi\n'
        )
        php.chmod(0o755)
        self.env = {
            "PATH": str(self.directory) + os.pathsep + os.defpath,
            "CALLS": str(self.calls),
            "APP_KEY": "clave-ficticia-solo-para-prueba",
        }

    def run_entrypoint(self, *args):
        return subprocess.run(
            ["/bin/sh", str(ROOT / "backend/docker-entrypoint.sh"), *args],
            env=self.env, cwd=self.directory, capture_output=True, text=True,
            timeout=5,
        )

    def test_arranca_sin_migrar_sembrar_ni_limpiar_cache_compartida(self):
        result = self.run_entrypoint()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls.read_text().splitlines(), [
            "artisan config:clear", "artisan route:clear",
            "artisan serve --host=0.0.0.0 --port=8080",
        ])
        self.assertFalse((self.directory / ".env").exists())

    def test_falta_app_key_detiene_el_arranque(self):
        del self.env["APP_KEY"]
        result = self.run_entrypoint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("APP_KEY", result.stderr)
        self.assertFalse(self.calls.exists())

    def test_error_de_configuracion_no_se_oculta(self):
        self.env["FAIL_CONFIG"] = "1"
        result = self.run_entrypoint()
        self.assertEqual(result.returncode, 7)
        self.assertEqual(self.calls.read_text().splitlines(), ["artisan config:clear"])

    def test_respeta_puerto_del_proveedor(self):
        self.env["PORT"] = "9000"
        self.assertEqual(self.run_entrypoint().returncode, 0)
        self.assertIn("--port=9000", self.calls.read_text())

    def test_comando_explicito_no_arranca_servidor(self):
        del self.env["APP_KEY"]
        result = self.run_entrypoint("php", "artisan", "migrate:status")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.calls.read_text().splitlines(), ["artisan migrate:status"])

    def test_neon_url_es_alias_sin_imprimir_secretos(self):
        self.env["NEON_URL"] = "postgresql://ficticio:secreto@invalid/test"
        result = self.run_entrypoint(
            "/bin/sh", "-c", '[ "$DB_URL" = "$NEON_URL" ]'
        )
        self.assertEqual(result.returncode, 0)
        self.assertNotIn("secreto", result.stdout + result.stderr)

    def test_db_url_explicita_tiene_prioridad(self):
        self.env.update(DB_URL="conexion-explicita", NEON_URL="conexion-antigua")
        result = self.run_entrypoint(
            "/bin/sh", "-c", '[ "$DB_URL" = "conexion-explicita" ]'
        )
        self.assertEqual(result.returncode, 0)


class LocalStartupTest(unittest.TestCase):
    @unittest.skipUnless(shutil.which("setsid"), "Requiere setsid en Linux")
    def test_error_de_un_servicio_detiene_los_otros(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            shutil.copyfile(ROOT / "start.sh", project / "start.sh")
            for folder in ["bin", "backend/vendor", "IA/venv/bin", "frontend/node_modules"]:
                (project / folder).mkdir(parents=True)
            for file in ["backend/.env", "backend/vendor/autoload.php", "IA/.env",
                         "IA/model.pkl", "IA/label_encoder.pkl", "IA/feature_names.json"]:
                (project / file).touch()
            service = (
                'trap \'echo "$SERVICE" >> "$STOPPED"; exit 0\' TERM\n'
                'echo "$SERVICE" >> "$STARTED"\n'
                'while :; do sleep 0.1; done\n'
            )
            scripts = {
                "bin/php": '#!/bin/sh\n[ "$1" = artisan ] || exit 0\nSERVICE=backend\n' + service,
                "bin/composer": '#!/bin/sh\nexit 0\n',
                "bin/python3.12": '#!/bin/sh\nexit 0\n',
                "IA/venv/bin/python": '#!/bin/sh\n[ "$2" = uvicorn ] || exit 0\nSERVICE=ia\n' + service,
                "bin/npm": (
                    '#!/bin/sh\n'
                    'while [ ! -f "$STARTED" ] || [ "$(wc -l < "$STARTED")" -lt 2 ]; do sleep 0.1; done\n'
                    'exit 42\n'
                ),
            }
            for name, content in scripts.items():
                path = project / name
                path.write_text(content)
                path.chmod(0o755)
            result = subprocess.run(
                ["/bin/bash", str(project / "start.sh")],
                env={"PATH": str(project / "bin") + os.pathsep + os.defpath,
                     "STARTED": str(project / "started"),
                     "STOPPED": str(project / "stopped")},
                capture_output=True, text=True, timeout=10,
            )
            self.assertEqual(result.returncode, 42, result.stderr)
            self.assertEqual(set((project / "stopped").read_text().splitlines()), {"backend", "ia"})

    def test_ia_mal_configurada_no_deja_servicios_corriendo(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            shutil.copyfile(ROOT / "start.sh", project / "start.sh")
            for folder in ["bin", "backend/vendor", "IA/venv/bin", "frontend"]:
                (project / folder).mkdir(parents=True)
            for file in ["backend/.env", "backend/vendor/autoload.php", "IA/.env"]:
                (project / file).touch()
            calls = project / "calls"
            for name in ["php", "composer", "npm", "python3.12", "setsid"]:
                stub = project / "bin" / name
                stub.write_text('#!/bin/sh\necho "' + name + ' $*" >> "$CALLS"\n')
                stub.chmod(0o755)
            python = project / "IA/venv/bin/python"
            python.write_text(
                '#!/bin/sh\n'
                'echo "venv $*" >> "$CALLS"\n'
                'if [ "$*" = "-c import app" ]; then exit 9; fi\n'
            )
            python.chmod(0o755)
            result = subprocess.run(
                ["/bin/bash", str(project / "start.sh")],
                env={"PATH": str(project / "bin") + os.pathsep + os.defpath,
                     "CALLS": str(calls)},
                capture_output=True, text=True, timeout=5,
            )
            self.assertEqual(result.returncode, 9, result.stderr)
            executed = calls.read_text()
            self.assertIn("venv -m pip install -r requirements.txt", executed)
            self.assertNotIn("setsid", executed)
            self.assertNotIn("npm", executed)


if __name__ == "__main__":
    unittest.main()
