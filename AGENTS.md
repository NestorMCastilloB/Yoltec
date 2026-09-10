# AGENTS.md — instrucciones para agentes de código

Este archivo lo leen los agentes automáticos (Jules, Claude Code) antes de tocar el
repositorio. La guía completa para humanos es [`CONTRIBUTING.md`](CONTRIBUTING.md);
aquí está lo que un agente necesita saber para no romper nada.

## Qué es Yoltec

Sistema de gestión de un consultorio médico escolar (ITSV): citas, historiales,
recetas y dos modelos de IA. Lo desarrolla **una sola persona**.

**El objetivo es que sea una pieza de portafolio profesional, no un producto que
crezca en funcionalidad.** Eso ordena las prioridades: código ejemplar, coherencia,
documentación honesta y pruebas visibles **por encima de añadir características**.
No propongas funcionalidad nueva salvo que se pida explícitamente.

## Estructura

| Carpeta | Stack | Notas |
|---|---|---|
| `backend/` | Laravel 12, PHP 8.2+, PostgreSQL | Lógica de negocio en `Services/`, no en los controladores |
| `frontend/` | Angular 20 | Componentes reutilizables en `shared/` |
| `mobile/` | Flutter | Exclusivo para estudiantes |
| `IA/` | Python + FastAPI | Microservicio de pre-evaluación de síntomas |

## Construir y probar

Todo va por Docker. Es el único camino soportado y no toca ninguna base remota:

```bash
./local.sh up      # PostgreSQL, backend, frontend, IA y Mailpit
./local.sh seed    # cuentas ficticias
./local.sh test    # pruebas de backend (php artisan test) e IA (unittest)
```

El CI (`.github/workflows/local.yml`, check `local`) corre exactamente esos tres
comandos. Si pasan en local, pasan en CI.

**Si el entorno no tiene Docker**, estas pruebas no necesitan ninguna dependencia y
sirven como verificación mínima:

```bash
python3 -m unittest discover -s tests -v          # arranque y scripts
cd IA && python3 -m unittest discover -s tests -v # extractor y chat guiado
```

Deja dicho en el PR qué pudiste ejecutar y qué no. **No afirmes que corriste una
suite que no corriste.**

## Reglas no negociables

1. **`main` está protegida.** Solo se actualiza por Pull Request, con el check
   `local` en verde y la rama al día. La regla aplica también al dueño del repo: no
   hay bypass. Nunca intentes un push directo a `main`.
2. **Un PR, una unidad de trabajo.** Es más fácil revisar 200 líneas coherentes que
   2 000 dispersas, sobre todo cuando el revisor es la misma persona que escribió el
   código.
3. **Todo en español**: código, comentarios, commits, títulos de PR y documentación.
4. **Conventional Commits en español**, en presente y sin punto final:
   `fix(citas): impedir la doble reserva del mismo horario`.
   El cuerpo explica **el porqué**, no el qué — el diff ya dice qué cambió.
   Los commits de un agente llevan su línea `Co-Authored-By`.
5. **Ramas** `tipo/descripcion-en-kebab-case`: `feat/`, `fix/`, `hotfix/`,
   `refactor/`, `chore/`, `docs/`, `test/`.
6. **Ningún secreto en el repo.** Ni `.env`, ni claves en el código, ni valores
   reales en los `.env.example`. Una credencial que llega al historial se considera
   comprometida aunque el commit se borre después.
7. **El código muerto se borra, no se comenta.** El historial de git es el archivo.

## Migraciones — leer antes de tocar el esquema

- Toda modificación del esquema va en una **migración versionada**.
- **Una migración ya fusionada no se edita jamás.** Si salió mal, se corrige con una
  migración nueva.
- Deben ser **idempotentes** (`Schema::hasTable`, `hasColumn`, `hasIndex`, o
  `CREATE ... IF NOT EXISTS`), de modo que reconstruir el esquema desde cero dé
  siempre el mismo resultado.
- Las migraciones **destructivas** van en su propio PR.

**Aviso importante:** el despliegue publica código pero **no aplica migraciones**.
Si tu cambio incluye una migración, dilo **de forma destacada** en la descripción del
PR: hay que aplicarla de forma deliberada antes de fusionar. Si se olvida, el código
nuevo acaba corriendo contra un esquema viejo. Ver la sección «Despliegue y drift de
esquema» de `CONTRIBUTING.md`.

## La IA — separación que no se rompe

Hay **dos** modelos, y se confunden con facilidad:

1. **Clasificador de prioridad de citas** — PHP, `backend/app/IA/`. Es una
   **heurística ponderada** (`PriorityClassifier`, 9 factores) sobre el historial del
   alumno, alimentada por `MedicalDataset`. No es scikit-learn. Sus pesos se entrenan
   en memoria al construir `IAService` y **no se persisten**.
2. **Pre-evaluación de síntomas** — Python, `IA/`. `model.pkl` (scikit-learn 1.5.2,
   46 enfermedades) es quien **siempre** da el diagnóstico.

En la número 2, el proveedor de LLM (hoy Groq) **solo conduce la conversación**. Si
falta o falla, `IA/extractor.py` extrae los síntomas por reglas y el chat sigue vivo
en modo guiado.

**Esa separación es deliberada y no debe romperse: ninguna funcionalidad esencial
puede depender de que un tercero responda.** Si añades algo que use el LLM, define
primero cómo se comporta cuando no está disponible.

No atribuyas a estos modelos precisiones ni capacidades que no tengan. El README ya
se corrigió una vez por describir un clasificador que no existe.

## Estilo de código

- Comentarios en español, una línea por método: `qué hace · por qué · qué retorna`.
- Antes de crear algo nuevo, comprueba si ya existe algo reutilizable.
- No añadas librerías externas si el framework ya resuelve el problema.
- Sin `console.log`, sin imports sin usar, sin archivos temporales de prueba.
- Los colores van a **tokens CSS de `styles.css`**, nunca escritos a mano en el
  componente. Es la causa raíz de que el modo oscuro se rompa una y otra vez.

### Tamaño de archivos

Si un archivo hace más de una cosa, es demasiado grande.

| Tipo | Ideal | Dividir |
|---|---|---|
| Cualquier archivo | <300 | >700 |
| Controlador Laravel | <80 | >200 |
| Componente Angular/Flutter | <200 | >500 |
| Servicio o helper | <150 | >400 |

## Pruebas

No se persigue cobertura. Se prueban **las invariantes que duelen si se rompen**:
reserva de horario, expiración y verificación del 2FA, bloqueo de login, y que cada
rol solo alcance lo suyo.

Si tu cambio toca una de esas, tiene que venir con prueba.

## Antes de abrir el PR

- [ ] Título y commits siguen la nomenclatura, en español.
- [ ] El PR explica qué se hizo, qué cambió y **por qué**.
- [ ] No hay credenciales ni datos personales en el código ni en el historial.
- [ ] Se añadieron pruebas si el cambio lo permite.
- [ ] Si hay migración, está señalada de forma destacada.
- [ ] La documentación afectada se actualizó (`README.md`, `docs/`).
- [ ] El PR toca una sola unidad de trabajo.
