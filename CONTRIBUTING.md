# Guía de contribución — Yoltec

Gracias por tu interés en colaborar. Este documento describe el flujo de trabajo, las convenciones de código y el proceso de revisión.

---

## Antes de empezar

1. Lee el [`README.md`](README.md) para entender el proyecto y dejarlo corriendo en local.
2. Lee la [`SECURITY.md`](SECURITY.md) — especialmente la sección de buenas prácticas.
3. Asegúrate de tener:
   - PHP 8.4, Composer, Node 20+, Python 3.12, Flutter 3.x.
   - Acceso a un PostgreSQL (local o en Neon).
   - Un fork o permisos de push sobre el repo.

---

## Flujo de trabajo

Trabajamos con **trunk-based development**: una sola rama `main`, ramas cortas por feature, PR obligatorio.

```bash
# 1. Sincronizar
git checkout main && git pull

# 2. Crear rama
git checkout -b feat/agendar-cita-mobile

# 3. Desarrollar (commits pequeños y atómicos)
git add archivo1 archivo2
git commit -m "feat: nombre breve y claro"

# 4. Push y PR
git push origin feat/agendar-cita-mobile
gh pr create --base main --title "feat: agendar cita en mobile"
```

> Está **prohibido** hacer `git push` directo a `main`.

---

## Convención de commits

Formato corto inspirado en [Conventional Commits](https://www.conventionalcommits.org):

| Prefijo | Cuándo usar |
|---------|-------------|
| `feat:`     | Funcionalidad nueva visible para el usuario |
| `fix:`      | Corrección de bug |
| `refactor:` | Reorganización sin cambio de comportamiento |
| `docs:`     | Cambios solo en documentación |
| `chore:`    | Tareas de mantenimiento, dependencias, build |
| `test:`     | Pruebas (añadir o corregir) |
| `style:`    | Formato, espacios, sin cambio de lógica |

Reglas:

- En **español**.
- Imperativo, presente: "agrega validación", no "agregada".
- Una línea de asunto ≤ 72 caracteres.
- Sin `Co-Authored-By`.

---

## Estructura por carpeta

| Carpeta | Stack | Notas |
|---------|-------|-------|
| `backend/`  | Laravel 12 | Lógica de negocio en `Services/`, no en Controllers |
| `frontend/` | Angular 20 | Componentes en `shared/` si se reusan entre roles |
| `mobile/`   | Flutter | **Exclusivo para estudiantes** |
| `IA/`       | Python + FastAPI | Solo Groq (gratuito). No OpenAI ni Anthropic |

Cada carpeta puede tener su propio `CLAUDE.md` con convenciones internas.

---

## Tamaño de archivos

La regla real: **si un archivo hace más de una cosa, es demasiado grande**.

| Tipo | Ideal | Tolerable | Dividir |
|------|-------|-----------|---------|
| Cualquier archivo | <300 | 300–400 | >700 |
| Controller Laravel | <80 | 80–120 | >200 |
| Componente Angular/Flutter | <200 | 200–280 | >500 |
| Service/Helper | <150 | 150–250 | >400 |

---

## Reglas de código

- Eliminar código muerto, no comentarlo.
- Sin `console.log`, sin imports sin usar, sin archivos de prueba temporales.
- Antes de crear algo nuevo, verifica si ya existe uno reutilizable.
- No introducir librerías externas si el framework ya lo resuelve.
- Comentarios: una línea por método, formato `qué hace · por qué · qué retorna`.
- Idioma: **siempre español** en comentarios y mensajes de commit.

---

## Antes de abrir un PR

- [ ] El código compila / pasa lint en la subcarpeta correspondiente.
- [ ] No hay credenciales hardcodeadas ni archivos `.env` añadidos.
- [ ] Probado localmente (golden path + al menos un caso de error).
- [ ] El PR toca una sola unidad de trabajo (no mezcles refactor + feature).
- [ ] Título del PR descriptivo con prefijo de commit (`feat:`, `fix:`, …).

---

## Revisión

- Cada PR requiere al menos **1 review** antes de merge.
- Squash merge por default (1 PR = 1 commit en `main`).
- Si un PR queda inactivo más de 14 días, se cierra; puedes reabrirlo cuando lo retomes.

---

## Reportar bugs

Usa los [templates de issue](https://github.com/NestorMCastilloB/Yoltec/issues/new/choose):

- **Bug** — incluye pasos para reproducir, comportamiento esperado vs actual, capturas si aplica.
- **Historia de usuario** — formato `Como <rol> quiero <acción> para <beneficio>`.

Vulnerabilidades de seguridad: **no abras un issue público**, sigue las instrucciones de [`SECURITY.md`](SECURITY.md).

---

¡Gracias por contribuir!
