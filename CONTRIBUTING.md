# Guía de contribución — Yoltec

Yoltec lo desarrolla **una sola persona**. Este documento no describe cómo coordinar a un equipo: describe la disciplina que sustituye a ese equipo cuando no hay nadie más para revisar tu trabajo.

Esa es la idea de fondo. Sin un segundo par de ojos, las garantías tienen que venir de otra parte: de la rama protegida, del CI, de las pruebas y de un historial que se explique solo dentro de seis meses, cuando ya no recuerdes por qué hiciste algo.

---

## Antes de empezar

Levanta el entorno local con Docker; es el único camino soportado y no toca ninguna base remota:

```bash
./local.sh up      # PostgreSQL, backend, frontend, IA y Mailpit
./local.sh seed    # cuentas ficticias
./local.sh test    # pruebas de backend e IA
```

Los detalles están en [`docs/desarrollo-local.md`](docs/desarrollo-local.md). El arranque nativo (`./start.sh`) existe, pero exige montar PHP, Node, Python y PostgreSQL por separado.

---

## Flujo de trabajo

`main` está **protegida en GitHub**. No es una convención que puedas saltarte: el servidor rechaza el push.

- Solo se actualiza mediante Pull Request.
- El check `local` (el workflow de CI) debe estar **en verde**.
- La rama debe estar **al día con `main`** antes de fusionar.
- Sin force-push y sin borrar la rama.
- La regla **se aplica también al dueño del repositorio**. No hay bypass, tampoco en una urgencia.

```bash
# 1. Partir de main actualizada
git checkout main && git pull

# 2. Una rama por tarea
git checkout -b feat/agendar-cita-movil

# 3. Commits pequeños, cada uno con un cambio lógico completo
git commit -m "feat(citas): agrega validación de horario"

# 4. Antes del PR, ponerse al día con main
git fetch origin && git rebase origin/main

# 5. Abrir el PR
git push -u origin feat/agendar-cita-movil
gh pr create --base main
```

Una vez fusionada, **la rama se borra** (local y remota). No se dejan ramas «por si acaso»: el trabajo fusionado vive en `main` y el no fusionado se pierde de vista. Si necesitas conservar una rama que no llegó a fusionarse, guárdala como referencia de respaldo:

```bash
git update-ref refs/respaldo/nombre-descriptivo <sha>
```

Las ramas son de **corta duración**. Cuanto más tiempo vive una rama sin integrarse, más conflictos genera. Si una tarea es grande, pártela en varios PRs.

### Nomenclatura de ramas

Formato `tipo/descripcion-corta-en-kebab-case`:

| Prefijo | Uso | Ejemplo |
|---|---|---|
| `feat/` | Funcionalidad nueva | `feat/ia-modo-guiado` |
| `fix/` | Corrección de bug | `fix/doble-reserva-citas` |
| `hotfix/` | Corrección urgente en producción | `hotfix/token-expirado` |
| `refactor/` | Reorganización sin cambio de comportamiento | `refactor/servicio-citas` |
| `chore/` | Mantenimiento, dependencias, limpieza | `chore/borrar-codigo-muerto` |
| `docs/` | Solo documentación | `docs/readme-honesto` |
| `test/` | Solo pruebas | `test/reserva-concurrente` |

---

## Convención de commits

Se sigue [Conventional Commits](https://www.conventionalcommits.org), **en español**:

```
<tipo>(<ámbito opcional>): <descripción corta, en presente, sin punto final>

<cuerpo opcional: el qué y, sobre todo, el porqué>

<footer opcional: BREAKING CHANGE, referencias a issues>
```

| Tipo | Cuándo usarlo |
|---|---|
| `feat` | Funcionalidad nueva |
| `fix` | Corrección de bug |
| `docs` | Solo documentación |
| `refactor` | Cambio de código sin alterar comportamiento |
| `perf` | Mejora de rendimiento |
| `test` | Añadir o corregir pruebas |
| `chore` | Dependencias, configuración, limpieza |
| `ci` | Cambios en integración continua |
| `build` | Cambios en el sistema de build |
| `style` | Formato y espacios, sin cambio de lógica |

Reglas:

- **Un commit, un cambio lógico.** Nada de commits gigantes que mezclen cosas sin relación.
- Descripción en **presente**: «agrega validación», no «agregada» ni «agregué».
- Asunto de 72 caracteres o menos.
- **El cuerpo explica el porqué**, no el qué: el diff ya dice qué cambió. Un buen historial se lee como una bitácora y evita tener que abrir el código para entender una decisión.
- Si el cambio rompe compatibilidad, `BREAKING CHANGE:` en el footer.
- Los commits escritos con asistencia de IA llevan su línea `Co-Authored-By`. Es trazabilidad, no un adorno.

---

## Pull Requests

El título usa el mismo formato que los commits: `tipo(ámbito): descripción corta`.

El contenido lo cubre [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md), que se rellena solo al abrir el PR. En resumen: qué se hizo, qué se cambió, **por qué**, cómo se probó y qué riesgos tiene.

**Un PR pequeño y enfocado en un solo objetivo es más fácil de revisar que uno gigante con cambios sin relación.** Eso vale incluso cuando el revisor eres tú: es más fácil detectar un error en 200 líneas coherentes que en 2 000 dispersas.

Como no hay un segundo revisor, antes de fusionar:

1. **Lee el diff completo en GitHub**, no en tu editor. Verlo en otro contexto destapa cosas que en local pasan desapercibidas.
2. Comprueba que el CI está en verde. Si falla, se arregla; no se fusiona «porque sé que funciona».
3. Verifica la parte que el CI no cubre. Si tocaste algo desplegado, pruébalo contra el entorno local levantado.

Se fusiona con **merge commit**. Los mensajes de commit son documentación del proyecto y se conservan.

### Checklist antes de fusionar

- [ ] El título y los commits siguen la nomenclatura.
- [ ] El PR explica qué se hizo, qué cambió y **por qué**.
- [ ] No hay credenciales, tokens ni datos personales en el código ni en el historial.
- [ ] Se añadieron o actualizaron pruebas si el cambio lo permite.
- [ ] El CI está en verde y la rama está al día con `main`.
- [ ] La documentación afectada se actualizó (`README.md`, `docs/`).
- [ ] El PR toca una sola unidad de trabajo.

---

## Estructura por carpeta

| Carpeta | Stack | Notas |
|---|---|---|
| `backend/` | Laravel 12 | Lógica de negocio en `Services/`, no en los controladores |
| `frontend/` | Angular 20 | Componentes reutilizables en `shared/` |
| `mobile/` | Flutter | Exclusivo para estudiantes |
| `IA/` | Python + FastAPI | El clasificador es propio; el LLM es **opcional** y sustituible |

### Sobre la IA

El diagnóstico lo da siempre `model.pkl`. El proveedor de LLM (hoy Groq) solo conduce la conversación, y el servicio funciona sin él gracias al extractor por reglas de `IA/extractor.py`.

Esa separación es deliberada y **no debe romperse**: ninguna funcionalidad esencial puede depender de que un tercero responda. Si añades algo que use el LLM, define primero cómo se comporta cuando no está disponible.

---

## Tamaño de archivos

La regla real: **si un archivo hace más de una cosa, es demasiado grande**.

| Tipo | Ideal | Tolerable | Dividir |
|---|---|---|---|
| Cualquier archivo | <300 | 300–400 | >700 |
| Controlador Laravel | <80 | 80–120 | >200 |
| Componente Angular/Flutter | <200 | 200–280 | >500 |
| Servicio o helper | <150 | 150–250 | >400 |

---

## Reglas de código

- **Eliminar el código muerto, no comentarlo.** El historial de git es el archivo; el editor no.
- Antes de crear algo nuevo, comprueba si ya existe algo reutilizable.
- No añadas librerías externas si el framework ya resuelve el problema.
- Sin `console.log`, sin imports sin usar, sin archivos temporales de prueba.
- Comentarios en **español**, una línea por método: `qué hace · por qué · qué retorna`.
- Los colores van a tokens CSS de `styles.css`, nunca escritos a mano en el componente. Es la causa raíz de que el modo oscuro se rompa una y otra vez.

---

## Migraciones

Toda modificación del esquema se hace con una **migración versionada**. Nunca se edita la base a mano en producción, ni desde un panel.

- **Una migración ya fusionada no se edita jamás.** Si salió mal, se corrige con una migración nueva. Editarla rompe el historial y desincroniza los entornos.
- **Deben ser idempotentes**: comprobar antes de crear (`Schema::hasTable`, `Schema::hasColumn`, `hasIndex`), de modo que reconstruir el esquema desde cero dé siempre el mismo resultado.
- Una migración, un cambio lógico.
- Las migraciones **destructivas** (borrar columnas o tablas) van en su propio PR y se revisan con más cuidado que el resto.

Cuidado con el reverso de la idempotencia: comprobar antes de crear evita que la migración falle, pero también puede **esconder** que la base real dejó de coincidir con lo que describen tus archivos. Protege el pipeline; no te avisa del desajuste.

---

## Pruebas

- `./local.sh test` corre las de backend e IA. El CI corre exactamente lo mismo.
- Las del extractor de síntomas no necesitan dependencias: `python3 -m unittest discover -s tests` dentro de `IA/`.
- No se persigue cobertura. Se prueban **las invariantes que duelen si se rompen**: reserva de horario, expiración y verificación del 2FA, bloqueo de login, y que cada rol solo alcance lo suyo.

---

## Seguridad y secretos

- Ningún `.env` se versiona, nunca. `.env.local` lo genera `./local.sh` y está ignorado.
- Los `.env.example` se mantienen al día, **sin valores reales**.
- Una credencial que llega al historial de git se considera comprometida aunque el commit se borre después: hay que **rotarla**, no solo quitarla del árbol.
- Los datos de la instancia desplegada son de demostración; aun así, las credenciales de acceso no se publican.
- Vulnerabilidades: no abras un issue público. Sigue [`SECURITY.md`](SECURITY.md).

---

## Reportar bugs

Usa los [templates de issue](https://github.com/NestorMCastilloB/Yoltec/issues/new/choose): **Bug** (pasos para reproducir, esperado contra actual) o **Historia de usuario** (`Como <rol> quiero <acción> para <beneficio>`).

Un issue bien escrito hoy es el recordatorio que vas a agradecer dentro de tres meses.
