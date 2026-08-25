# 217-graphify

Integracion de Graphify con Codex, Claude y Antigravity en dos niveles distintos:

- **instalacion global**: la herramienta Graphify y sus skills globales de Codex/Claude/Antigravity en la shell de WSL Debian (`graphify_install`);
- **preparacion por proyecto**: integracion local con `AGENTS.md`, `.codex/hooks.json`, `CLAUDE.md`, `.claude/settings.json`, la config de Antigravity, y actualizacion del grafo del repositorio (`graphify_run .`).

**Regla clave: Graphify workspace != raiz de Git.** `graphify_run <ruta>` resuelve `<ruta>` (por defecto `.`) a una ruta absoluta y la usa SIEMPRE como raiz del workspace de Graphify, sin importar si existe un `.git/` ahi, mas arriba, o en ningun lado. `git rev-parse --show-toplevel` nunca se usa para decidir donde escribir `AGENTS.md`/`CLAUDE.md`/`.codex/`/`.claude/`/`graphify-out/`/`.gitignore` - esto es intencional, no un descuido: si tu proyecto vive dentro de un repo Git mas grande (monorepo, subcarpeta de un repo superior), `graphify_run .` prepara *esa subcarpeta* como su propio workspace en vez de escribir en la raiz del repo superior. Esto es valido y funciona igual con o sin Git:

```
mkdir proyecto
cd proyecto
graphify_run .

# Git puede inicializarse despues si se desea
git init
```

Git solo se usa para una comprobacion auxiliar y opcional (archivos de `graphify-out/` ya versionados, ver `graphify_scan_gitignore` mas abajo), nunca para reubicar el target.

```
WSL Debian
│
├── graphify_install
│      ├── Graphify (uv tool)
│      ├── Codex global skill        (graphify install --platform codex)
│      ├── Claude global skill       (graphify install --platform claude)
│      └── Antigravity global skill  (graphify install --platform antigravity → ~/.gemini/config/skills/graphify/)
│
└── Proyecto (workspace = <ruta> pasada a graphify_run, con o sin Git)
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
              ├── graphify antigravity install
              │      ├── .agents/rules/graphify.md
              │      └── .agents/workflows/graphify.md
              │
              └── graphify update .
                     └── graphify-out/ (graph.json, graph.html, GRAPH_REPORT.md, cache, ...)
```

`graphify-out/` es local y regenerable en cualquier momento con `graphify update .`; por eso `graphify_run` la agrega siempre a `.gitignore` en vez de versionarla.

## Funciones publicas

- `graphify_help`: resume los cuatro niveles de comando (`graphify_install`, `graphify_run .`, `graphify update .`, `graphify .`), las consultas (`query`/`explain`/`path`) y variables.
- `graphify_check`: valida dependencias y binarios disponibles.
- `graphify_install`: instala `uv` si hace falta, instala Graphify y configura la skill global de Codex, Claude y Antigravity con `graphify install --platform codex`, `graphify install --platform claude` y `graphify install --platform antigravity`. Es puramente global: no toca ningun proyecto ni depende del directorio actual.
- `graphify_update`: actualiza la herramienta Graphify global y reaplica la skill global de Codex, Claude y Antigravity.
- `graphify_uninstall`: elimina Graphify de `uv`.
- `graphify_run [ruta|.]`: prepara el proyecto local (gitignore + Codex + Claude + Antigravity) y termina con `graphify update` para regenerar `graphify-out/graph.json` y el resto del grafo. No requiere API key.
- `graphify_batch <ruta> [ruta ...]`: ejecuta `graphify_run` varias veces sobre distintas rutas.
- `graphify_workspace <ruta> [nombre]`: crea un workspace nuevo, escribe `README.md` y `.gitignore`, y deja preparado el proyecto para Codex + Claude + Antigravity + Graphify.
- `graphify_report_open [ruta]`: abre el reporte de texto mas reciente (Markdown/JSON/etc.) con `$EDITOR`, `less` o `cat`.
- `graphify_graph_open [ruta]`: abre `graphify-out/graph.html` en el navegador. Prueba, en orden, `wslview`, `explorer.exe` (via `wslpath`), `xdg-open` y `$BROWSER`.
- `graphify_scan_gitignore [ruta]`: agrega exclusiones de Graphify a `.gitignore` (incluyendo obligatoriamente `graphify-out/`) y advierte si ya hay archivos de `graphify-out/` versionados en Git.
- `graphify_codex_note [mensaje]`: crea una nota Markdown en `.codex/notes/`.

## Funciones internas

- `_graphify_setup_project`: recibe el directorio ya resuelto por el llamador (`graphify_run` o `graphify_workspace`), se posiciona en el con `cd` y usa `pwd -P` (nunca Git) para fijar `root_dir`; ejecuta `graphify codex install`, `graphify claude install` y `graphify antigravity install` ahi (son idempotentes por si mismos), avisando y continuando con las demas integraciones si alguna falla; luego complementa `AGENTS.md` con el bloque administrado por este modulo.
- `_graphify_upsert_agents_block`: inserta o reemplaza el bloque administrado por este modulo sin duplicar contenido ni acumular lineas en blanco en ejecuciones repetidas.
- `_graphify_agents_custom_block`: genera el bloque de instrucciones personalizado para Codex.
- `_graphify_workspace_root`: resuelve la raiz Git del proyecto o usa el directorio actual. Se mantiene para las funciones de solo lectura (`graphify_report_open`, `graphify_graph_open`, `graphify_codex_note`), pero `graphify_run` **ya no la usa** para decidir su workspace - ese fue el bug original (`graphify_run .` terminaba escribiendo en un repo Git superior en vez de la carpeta actual).
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
3. Esa capa global ejecuta `graphify install --platform codex`, `graphify install --platform claude` y `graphify install --platform antigravity`.

## Flujo por proyecto

1. `graphify_workspace` crea un proyecto nuevo y llama a `_graphify_setup_project`.
2. `graphify_run <ruta|.>` hace lo mismo para repositorios nuevos o existentes, cada vez que se ejecuta:
   0. Resuelve `<ruta>` (por defecto `.`) a una ruta absoluta/canonica con `cd "<ruta>" && pwd -P` - ese directorio, y solo ese, es el workspace para el resto del flujo. Nunca se sube a una raiz de Git superior.
   1. `graphify_scan_gitignore` asegura `graphify-out/` (y el resto de exclusiones) en `.gitignore` dentro de ese workspace, y advierte si ya hay archivos de `graphify-out/` versionados.
   2. `_graphify_setup_project` ejecuta `graphify codex install`, `graphify claude install` y `graphify antigravity install` con ese workspace como directorio de trabajo (`root_dir="$(pwd -P)"`, no `git rev-parse --show-toplevel`). Si una falla, avisa y continua con las demas.
   3. La misma funcion complementa `AGENTS.md` con instrucciones para WSL Debian, Codex, Claude, Antigravity y Graphify.
   4. `graphify_run` termina ejecutando `graphify update .` con el workspace como directorio de trabajo, para refrescar el knowledge graph (sin API).
3. Nada de esto depende de que `codex` o `claude` esten instalados como CLI: `graphify codex install` / `graphify claude install` / `graphify antigravity install` solo requieren el binario `graphify`.
4. Nada de esto depende de Git: un workspace sin `.git/`, dentro de un repo superior, o con su propio `.git/` se comportan igual - el workspace siempre es la ruta pedida.

## Comandos que ejecutan

- `graphify install --platform codex`
  - se usa en `graphify_install` y `graphify_update` para la skill global.
- `graphify install --platform claude`
  - se usa en `graphify_install` y `graphify_update` para la skill global.
- `graphify install --platform antigravity`
  - se usa en `graphify_install` y `graphify_update` para la skill global (escribe en `~/.gemini/config/skills/graphify/`; Antigravity guarda su config bajo `~/.gemini`).
- `graphify codex install`
  - se usa en `_graphify_setup_project` para la integracion local por proyecto (AGENTS.md + .codex/hooks.json). Se ejecuta en cada llamada; el propio comando es idempotente.
- `graphify claude install`
  - se usa en `_graphify_setup_project` para la integracion local por proyecto (CLAUDE.md + .claude/settings.json). Se ejecuta en cada llamada; el propio comando es idempotente.
- `graphify antigravity install`
  - se usa en `_graphify_setup_project` para la integracion local por proyecto (`.agents/rules/graphify.md` + `.agents/workflows/graphify.md`, ademas de reinstalar la skill global). Se ejecuta en cada llamada; el propio comando es idempotente (verificado: la segunda corrida reporta "no change" en ambos archivos).
  - imprime una sugerencia manual para habilitar MCP (agregar un bloque `graphify` a `~/.gemini/antigravity/mcp_config.json`); este modulo no automatiza ese paso.
- `graphify update .`
  - se usa en `graphify_run`, ejecutado con `cd` al workspace resuelto, para generar o refrescar `graphify-out/graph.json` sin usar ninguna API de LLM.
- `graphify .` (extraccion completa, AST + semantica)
  - no la ejecuta ningun helper de este modulo; es manual y puede requerir una API key (Gemini/OpenAI/Anthropic/etc.) si el proyecto tiene documentacion, PDFs o imagenes.
- `graphify query "<question>"`, `graphify explain "<concept>"`, `graphify path "<A>" "<B>"`
  - no se ejecutan automaticamente desde Bash; son las consultas que Codex/Claude/Antigravity usan sobre `graphify-out/graph.json`, y las instrucciones escritas en `AGENTS.md`/`CLAUDE.md`/`.agents/rules/graphify.md` (por `graphify codex install`/`graphify claude install`/`graphify antigravity install`) les dicen cuando usarlas.

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

- `graphify codex install`, `graphify claude install` y `graphify antigravity install` no reescriben nada si el proyecto ya esta configurado (verificado contra Graphify 0.9.46); `_graphify_setup_project` los deja correr en cada `graphify_run` en vez de intentar detectar por su cuenta si "ya estan instalados".
- El bloque de `AGENTS.md` esta delimitado por marcadores claros y se regenera (no se duplica) en cada llamada; el separador en blanco entre el contenido previo y el bloque tampoco se acumula entre ejecuciones.
- Las instrucciones que Graphify escribe en `AGENTS.md`/`CLAUDE.md`, y las de otros agentes o herramientas, no se eliminan.
- `graphify_scan_gitignore` agrega cada entrada (incluida `graphify-out/`) una sola vez; correrla varias veces no duplica lineas.
- Ejecutar `graphify_run .` repetidamente (probado 10 veces seguidas) no duplica bloques, no acumula lineas en blanco y no produce errores solo porque una integracion ya existe.

## graphify-out/ y Git

- `graphify-out/` (graph.json, graph.html, GRAPH_REPORT.md, cache, manifest, analysis, labels, snapshots de comunidades) es siempre local y regenerable con `graphify update .`; no debe versionarse.
- `graphify_scan_gitignore` la agrega a `.gitignore`, pero el `.gitignore` no afecta archivos que Git ya rastreaba de antes.
- Si detecta archivos ya versionados dentro de `graphify-out/`, solo muestra una advertencia sugiriendo `git rm -r --cached graphify-out/`; nunca ejecuta `git rm`, `git add` ni `git commit` automaticamente.

## Parche local de Graphify (`graphify-patch/`)

`graphify-patch/` es una copia de respaldo de un parche aplicado directamente
a la instalacion de Graphify (`~/.local/share/uv/tools/graphifyy/...`), **no**
a este repo — agrega un fallback textual generico para extensiones que
Graphify no reconoce (`.cml`, `.puml`, `.mmd`, `.customdsl`, etc.), gateado
por un sniff binario/texto en vez de una whitelist. Detalle completo del
parche en `graphify-patch/README.md`.

El problema: cada `uv tool install`/`uv tool upgrade` escribe un venv limpio
y borra ese parche, y si clonas este repo en otra maquina, la instalacion de
Graphify ahi tampoco lo tiene. Por eso `graphify_install` y `graphify_update`
llaman a `_graphify_reapply_local_patch` al final — busca
`graphify-patch/reapply.sh` **relativo a este mismo archivo**
(`_GRAPHIFY_MODULE_DIR`, capturado con `${BASH_SOURCE[0]}` al cargar el
modulo, nunca una ruta `~/bashrc` fija), asi que funciona sin importar donde
clonaste el repo. Si `graphify-patch/` no existe (un clone viejo, o se borro
a proposito), no es un error: el modulo sigue funcionando sin el parche.

## Notas

- Esta configuracion no escribe `AGENTS.md` en `graphify_install` ni `graphify_update`; solo en la preparacion por proyecto.
- No hay logica especial para connectors, plugins o PowerShell dentro de Bash; la instruccion de salto a WSL vive en `AGENTS.md`.
- Ni `graphify codex install`, ni `graphify claude install`, ni `graphify antigravity install` requieren que los CLI `codex`, `claude` o Antigravity esten instalados: preparan la configuracion del proyecto independientemente de que el asistente este abierto en ese momento.
