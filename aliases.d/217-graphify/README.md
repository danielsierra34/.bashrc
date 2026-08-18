# 217-graphify

Instalacion e integracion de Graphify con Codex.

## Funciones
- `graphify_help`: muestra el mapa rapido de comandos.
- `graphify_check`: valida dependencias y binarios.
- `graphify_install`: instala `uv` si hace falta, instala Graphify y ejecuta `graphify install --platform codex`.
- `graphify_update`: actualiza Graphify y reaplica la integracion con Codex.
- `graphify_uninstall`: desinstala la herramienta instalada con `uv`.
- `graphify_run [ruta|.]`: ejecuta Graphify sobre una ruta o el directorio actual.
- `graphify_batch <ruta> [ruta ...]`: ejecuta Graphify en varias rutas.
- `graphify_workspace <ruta> [nombre]`: crea un workspace con `input/`, `output/`, `reports/` y `.graphify/`.
- `graphify_report_open [ruta]`: abre el reporte mas reciente.
- `graphify_scan_gitignore [ruta]`: agrega exclusiones comunes a `.gitignore`.
- `graphify_codex_note [mensaje]`: crea una nota en `.codex/notes/`.

## Personalizacion
- `GRAPHIFY_UV_PACKAGE`: nombre del paquete a instalar con `uv tool install` si no coincide con `graphify`.
- `GRAPHIFY_BIN`: nombre del binario que debe quedar disponible en `PATH` despues de la instalacion.

## Flujo
1. Verifica o instala Python 3 y `curl`.
2. Instala `uv` si no existe.
3. Instala Graphify como herramienta de `uv`.
4. Configura la integracion con Codex.
