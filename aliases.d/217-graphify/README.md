# 217-graphify

Integracion de Graphify con Codex para dos niveles distintos:

- instalacion global de la herramienta Graphify en la shell de WSL Debian;
- preparacion por proyecto con `AGENTS.md`, `.codex/` y actualizacion del grafo del repositorio.

## Funciones publicas

- `graphify_help`: resume comandos, variables y flujo recomendado.
- `graphify_check`: valida dependencias y binarios disponibles.
- `graphify_install`: instala `uv` si hace falta, instala Graphify y configura la skill global de Codex y Claude con `graphify install --platform codex` y `graphify install --platform claude`.
- `graphify_update`: actualiza la herramienta Graphify global y reaplica la skill global de Codex y Claude.
- `graphify_uninstall`: elimina Graphify de `uv`.
- `graphify_run [ruta|.]`: prepara el proyecto local para Codex si hace falta, luego ejecuta `graphify update` para regenerar `graphify-out/graph.json` y el resto del grafo.
- `graphify_batch <ruta> [ruta ...]`: ejecuta `graphify_run` varias veces sobre distintas rutas.
- `graphify_workspace <ruta> [nombre]`: crea un workspace nuevo, escribe `README.md` y `.gitignore`, y deja preparado el proyecto para Codex + Graphify.
- `graphify_report_open [ruta]`: abre el reporte mas reciente generado por Graphify.
- `graphify_scan_gitignore [ruta]`: agrega exclusiones comunes de Graphify a `.gitignore`.
- `graphify_codex_note [mensaje]`: crea una nota Markdown en `.codex/notes/`.

## Funciones internas

- `_graphify_setup_project_codex`: detecta la raiz del repositorio y ejecuta `graphify codex install` y `graphify claude install` una sola vez por proyecto, luego complementa `AGENTS.md`.
- `_graphify_upsert_agents_block`: inserta o reemplaza el bloque administrado por este modulo sin duplicar contenido.
- `_graphify_agents_custom_block`: genera el bloque de instrucciones personalizado para Codex.
- `_graphify_workspace_root`: resuelve la raiz Git del proyecto o usa el directorio actual.
- `_graphify_report_path`: localiza el reporte mas reciente en `reports/`, `output/` o en la raiz.

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

1. `graphify_workspace` crea un proyecto nuevo y llama a `_graphify_setup_project_codex`.
2. `graphify_run` hace lo mismo para repositorios existentes si todavia no tienen la integracion local.
3. `_graphify_setup_project_codex` ejecuta `graphify codex install` y `graphify claude install` desde la raiz del repo.
4. La misma funcion complementa `AGENTS.md` con instrucciones para WSL Debian, Codex y Graphify.
5. `graphify_run` termina con `graphify update .` o el path equivalente para refrescar el knowledge graph.

## Comandos que ejecutan

- `graphify install --platform codex`
  - se usa en `graphify_install` y `graphify_update` para la skill global.
- `graphify install --platform claude`
  - se usa en `graphify_install` y `graphify_update` para la skill global.
- `graphify codex install`
  - se usa en `_graphify_setup_project_codex` para la integracion local por proyecto.
- `graphify claude install`
  - se usa en `_graphify_setup_project_codex` para la integracion local por proyecto.
- `graphify update <ruta>`
  - se usa en `graphify_run` para generar o refrescar `graphify-out/graph.json`.
- `graphify query`, `graphify explain`, `graphify path`
  - no se ejecutan automaticamente desde Bash; forman parte de las instrucciones escritas en `AGENTS.md`.

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

- El bloque de `AGENTS.md` esta delimitado por marcadores claros.
- Ejecutar la preparacion varias veces no duplica instrucciones.
- Las instrucciones de otros agentes o herramientas no se eliminan.
- Si `AGENTS.md` ya contiene el bloque administrado, la preparacion local se considera completa.

## Notas

- Esta configuracion no escribe `AGENTS.md` en `graphify_install` ni `graphify_update`; solo en la preparacion por proyecto.
- No hay logica especial para connectors, plugins o PowerShell dentro de Bash; la instruccion de salto a WSL vive en `AGENTS.md`.
