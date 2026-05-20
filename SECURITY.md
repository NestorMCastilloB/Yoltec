# Política de seguridad

## Versiones soportadas

| Versión | Soporte de seguridad |
|---------|----------------------|
| `main`  | ✅ activa            |
| Releases anteriores a la última publicada | ❌ no soportadas |

Solo se atienden reportes contra el código actual de `main` y la última versión publicada en [Releases](https://github.com/NestorMCastilloB/Yoltec/releases).

---

## Reportar una vulnerabilidad

Si encuentras una vulnerabilidad **no abras un issue público**. En su lugar:

1. Envía un correo a **22690495@tecvalles.mx** con el asunto `[SECURITY] Yoltec — <título breve>`.
2. Incluye:
   - Descripción del problema.
   - Pasos para reproducirlo.
   - Impacto potencial (qué dato/funcionalidad se ve comprometido).
   - Versión / commit afectado.
   - Tu nombre o handle para crédito (opcional).

Te responderemos en un plazo máximo de **5 días hábiles** con la confirmación de recepción y un estimado de resolución.

---

## Alcance

Se considera dentro de alcance:

- Inyecciones (SQL, LDAP, comandos).
- XSS, CSRF, SSRF.
- Bypass de autenticación o autorización (estudiante / doctor / admin).
- Exposición de datos médicos o personales.
- Escalada de privilegios.
- Vulnerabilidades en el flujo de pre‑evaluación con IA (prompt injection sensible).

**Fuera de alcance**:

- Ataques que requieran acceso físico al dispositivo del usuario.
- Denegación de servicio por fuerza bruta sin vulnerabilidad subyacente.
- Vulnerabilidades en dependencias ya reportadas y conocidas (revisar issues primero).
- Versiones que no estén en `main`.

---

## Buenas prácticas para colaboradores

- **Nunca** subir `.env`, credenciales, API keys o tokens al repo.
- **Nunca** ejecutar `php artisan migrate:fresh` contra la base de datos de producción.
- Usar `git secrets` o un pre‑commit hook que escanee credenciales antes de commitear.
- Reportar inmediatamente cualquier fuga accidental para rotar credenciales y purgar histórico.

---

## Histórico de incidentes

| Fecha | Resumen | Mitigación |
|-------|---------|------------|
| 2026‑05‑20 | Purga del histórico Git para eliminar `.env` versionado por accidente en commit antiguo. | Reescritura de historia con `git-filter-repo`, rotación de credenciales afectadas. |
