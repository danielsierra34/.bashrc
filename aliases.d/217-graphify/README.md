# 217-graphify

Integracion de Graphify con Codex y Claude en dos niveles distintos:

- **instalacion global**: la herramienta Graphify y sus skills globales de Codex/Claude en la shell de WSL Debian (`graphify_install`);
- **preparacion por proyecto**: integracion local con `AGENTS.md`, `.codex/hooks.json`, `CLAUDE.md`, `.claude/settings.json` y actualizacion del grafo del repositorio (`graphify_run .`).

```
WSL Debian
│
├── graphify_install
│      ├── Graphify (uv tool)
│      ├── Codex global skill   (graphify install --platform codex)
│      └── Claude global skill  (graphify install --platform claude)
│
└── Proyecto (cualquier repo)
       │
       └── graphify_run .
              ├── .gitignore → graphify-out/
              ├── graphify codex install
              │      ├── AGENTS.md
              │      └── .codex/hooks.json
              │
              ├── graphify claude install
              │      ├── CLAUDE.md
              │      └── .claude/settings.json
              │
              └── graphify update .
                     └── graphify-out/ (graph.json, graph.html, GRAPH_REPORT.md, cache, ...)
```

`graphify-out/` es local y regenerable en cualquier momento con `graphify update .`; por eso `graphify_run` la agrega siempre a `.gitignore` en vez de versionarla.

## Funciones publicas

- `graphify_help`: resume los cuatro niveles de comando (`graphify_install`, `graphify_run .`, `graphify update .`, `graphify .`), las consultas (`query`/`explain`/`path`) y variables.
- `graphify_check`: valida dependencias y binarios disponibles.
- `graphify_install`: instala `uv` si hace falta, instala Graphify y configura la skill global de Codex y Claude con `graphify install --platform codex` y `graphify install --platform claude`. Es puramente global: no toca ningun proyecto ni depende del directorio actual.
- `graphify_update`: actualiza la herramienta Graphify global y reaplica la skill global de Codex y Claude.
- `graphify_uninstall`: elimina Graphify de `uv`.
- `graphify_run [ruta|.]`: prepara el proyecto local (gitignore + Codex + Claude) y termina con `graphify update` para regenerar `graphify-out/graph.json` y el resto del grafo. No requiere API key.
- `graphify_batch <ruta> [ruta ...]`: ejecuta `graphify_run` varias veces sobre distintas rutas.
- `graphify_workspace <ruta> [nombre]`: crea un workspace nuevo, escribe `README.md` y `.gitignore`, y deja preparado el proyecto para Codex + Claude + Graphify.
- `graphify_report_open [ruta]`: abre el reporte de texto mas reciente (Markdown/JSON/etc.) con `$EDITOR`, `less` o `cat`.
- `graphify_graph_open [ruta]`: abre `graphify-out/graph.html` en el navegador. Prueba, en orden, `wslview`, `explorer.exe` (via `wslpath`), `xdg-open` y `$BROWSER`.
- `graphify_scan_gitignore [ruta]`: agrega exclusiones de Graphify a `.gitignore` (incluyendo obligatoriamente `graphify-out/`) y advierte si ya hay archivos de `graphify-out/` versionados en Git.
- `graphify_codex_note [mensaje]`: crea una nota Markdown en `.codex/notes/`.

## Funciones internas

- `_graphify_setup_project`: resuelve la raiz del repositorio y ejecuta `graphify codex install` y `graphify claude install` en cada llamada (son idempotentes por si mismos), avisando y continuando con la otra integracion si una falla; luego complementa `AGENTS.md` con el bloque administrado por este modulo.
- `_graphify_upsert_agents_block`: inserta o reemplaza el bloque administrado por este modulo sin duplicar contenido ni acumular lineas en blanco en ejecuciones repetidas.
- `_graphify_agents_custom_block`: genera el bloque de instrucciones personalizado para Codex.
- `_graphify_workspace_root`: resuelve la raiz Git del proyecto o usa el directorio actual.
- `_graphify_report_path`: localiza el reporte mas reciente en `reports/`, `output/` o en la raiz.
- `_graphify_open_url`: intenta abrir una ruta/URL con el navegador por defecto probando `wslview`, `explorer.exe` (via `wslpath -w`), `xdg-open` y `$BROWSER`, en ese orden.

## Variables y entorno

- `GRAPHIFY_UV_PACKAGE`: paquete que `uv tool install` o `uv tool upgrade` debe usar. Por defecto es `graphifyy`.
- `GRAPHIFY_BIN`: binario esperado en `PATH`. Por defecto es `graphify`.
- `PATH`: `graphify_install` lo extiende con `~/.local/bin` y `~/.cargo/bin`.
- `EDITOR`: si existe, `graphify_report_open` lo usa para abrir el reporte.

## Flujo global

1. `graphify_install` deja Graphify disponible en toda la shell de WSL Debian.
2. `graphify_update` mantiene esa instalacion global.
3. Esa capa global ejecuta `graphify install --platform codex` y `graphify install --platform claude`.

## Flujo por proyecto

1. `graphify_workspace` crea un proyecto nuevo y llama a `_graphify_setup_project`.
2. `graphify_run <ruta|.>` hace lo mismo para repositorios nuevos o existentes, cada vez que se ejecuta:
   1. `graphify_scan_gitignore` asegura `graphify-out/` (y el resto de exclusiones) en `.gitignore`, y advierte si ya hay archivos de `graphify-out/` versionados.
   2. `_graphify_setup_project` ejecuta `graphify codex install` y `graphify claude install` desde la raiz del repo. Si una falla, avisa y continua con la otra.
   3. La misma funcion complementa `AGENTS.md` con instrucciones para WSL Debian, Codex y Graphify.
   4. `graphify_run` termina con `graphify update .` para refrescar el knowledge graph (sin API).
3. Nada de esto depende de que `codex` o `claude` esten instalados como CLI: `graphify codex install` / `graphify claude install` solo requieren el binario `graphify`.

## Comandos que ejecutan

- `graphify install --platform codex`
  - se usa en `graphify_install` y `graphify_update` para la skill global.
- `graphify install --platform claude`
  - se usa en `graphify_install` y `graphify_update` para la skill global.
- `graphify codex install`
  - se usa en `_graphify_setup_project` para la integracion local por proyecto (AGENTS.md + .codex/hooks.json). Se ejecuta en cada llamada; el propio comando es idempotente.
- `graphify claude install`
  - se usa en `_graphify_setup_project` para la integracion local por proyecto (CLAUDE.md + .claude/settings.json). Se ejecuta en cada llamada; el propio comando es idempotente.
- `graphify update <ruta>`
  - se usa en `graphify_run` para generar o refrescar `graphify-out/graph.json` sin usar ninguna API de LLM.
- `graphify .` (extraccion completa, AST + semantica)
  - no la ejecuta ningun helper de este modulo; es manual y puede requerir una API key (Gemini/OpenAI/Anthropic/etc.) si el proyecto tiene documentacion, PDFs o imagenes.
- `graphify query "<question>"`, `graphify explain "<concept>"`, `graphify path "<A>" "<B>"`
  - no se ejecutan automaticamente desde Bash; son las consultas que Codex/Claude usan sobre `graphify-out/graph.json`, y las instrucciones escritas en `AGENTS.md`/`CLAUDE.md` (por `graphify codex install`/`graphify claude install`) les dicen cuando usarlas.

## AGENTS.md y Codex

El bloque administrado por este modulo deja claro que:

- WSL Debian es el entorno real de ejecucion de las herramientas.
- Si Codex esta operando desde Windows o PowerShell, debe entrar a WSL Debian para correr Graphify.
- Graphify no debe buscarse como connector, plugin o integracion externa.
- Si existe `graphify-out/graph.json`, las consultas de codebase deben empezar por Graphify.
- `graphify query "<question>"` es la primera opcion.
- `graphify explain "<concept>"` y `graphify path "<A>" "<B>"` se usan cuando corresponde.
- `graphify-out/GRAPH_REPORT.md` sirve para analisis arquitectonicos amplios.
- `graphify-out/wiki/index.md`, si existe, se usa para navegacion general.
- Si una busqueda devuelve `No matching nodes found`, se debe refinar con nombres reales del codebase antes de abandonar Graphify.
- Despues de modificar codigo se debe ejecutar `graphify update .`.

## Idempotencia

- `graphify codex install` y `graphify claude install` no reescriben nada si el proyecto ya esta configurado (verificado contra Graphify 0.9.46); `_graphify_setup_project` los deja correr en cada `graphify_run` en vez de intentar detectar por su cuenta si "ya estan instalados".
- El bloque de `AGENTS.md` esta delimitado por marcadores claros y se regenera (no se duplica) en cada llamada; el separador en blanco entre el contenido previo y el bloque tampoco se acumula entre ejecuciones.
- Las instrucciones que Graphify escribe en `AGENTS.md`/`CLAUDE.md`, y las de otros agentes o herramientas, no se eliminan.
- `graphify_scan_gitignore` agrega cada entrada (incluida `graphify-out/`) una sola vez; correrla varias veces no duplica lineas.
- Ejecutar `graphify_run .` repetidamente (probado 10 veces seguidas) no duplica bloques, no acumula lineas en blanco y no produce errores solo porque una integracion ya existe.

## graphify-out/ y Git

- `graphify-out/` (graph.json, graph.html, GRAPH_REPORT.md, cache, manifest, analysis, labels, snapshots de comunidades) es siempre local y regenerable con `graphify update .`; no debe versionarse.
- `graphify_scan_gitignore` la agrega a `.gitignore`, pero el `.gitignore` no afecta archivos que Git ya rastreaba de antes.
- Si detecta archivos ya versionados dentro de `graphify-out/`, solo muestra una advertencia sugiriendo `git rm -r --cached graphify-out/`; nunca ejecuta `git rm`, `git add` ni `git commit` automaticamente.

## Notas

- Esta configuracion no escribe `AGENTS.md` en `graphify_install` ni `graphify_update`; solo en la preparacion por proyecto.
- No hay logica especial para connectors, plugins o PowerShell dentro de Bash; la instruccion de salto a WSL vive en `AGENTS.md`.
- Ni `graphify codex install` ni `graphify claude install` requieren que los CLI `codex` o `claude` esten instalados: preparan la configuracion del proyecto independientemente de que el asistente este abierto en ese momento.
