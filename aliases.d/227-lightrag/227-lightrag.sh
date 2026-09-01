########################################################################################## LIGHTRAG

# LightRAG: servidor RAG local para documentos, con grafo de conocimiento,
# WebUI y API. A diferencia de Graphify, esta pensado para corpus de
# apuntes, PDFs, manuales y notas, no para codebases.

_lightrag_pkg() {
    printf '%s' "${LIGHTRAG_UV_PACKAGE:-lightrag-hku[api,offline-llm]}"
}

_lightrag_bin() {
    printf '%s' "${LIGHTRAG_BIN:-lightrag-server}"
}

_lightrag_default_host() {
    printf '%s' "${LIGHTRAG_HOST:-127.0.0.1}"
}

_lightrag_default_port() {
    printf '%s' "${LIGHTRAG_PORT:-9621}"
}

_lightrag_resolve_root() {
    local target
    target="${1:-.}"

    ( cd "$target" >/dev/null 2>&1 && pwd -P )
}

_lightrag_workspace_name() {
    local root
    root="$(_lightrag_resolve_root "${1:-.}")" || return 1
    if [ -n "${2:-}" ]; then
        printf '%s' "$2"
    else
        basename "$root"
    fi
}

_lightrag_open_url() {
    local url
    url="$1"

    if command -v wslview >/dev/null 2>&1; then
        wslview "$url" >/dev/null 2>&1 &
        return 0
    fi

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 &
        return 0
    fi

    if command -v explorer.exe >/dev/null 2>&1; then
        explorer.exe "$url" >/dev/null 2>&1 &
        return 0
    fi

    if [ -n "${BROWSER:-}" ]; then
        "$BROWSER" "$url" >/dev/null 2>&1 &
        return 0
    fi

    echo "No encontre un navegador para abrir: $url"
    return 1
}

_lightrag_append_line() {
    local file line
    file="$1"
    line="$2"

    touch "$file" || return 1
    grep -qxF "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

_lightrag_agents_begin_marker() {
    printf '%s' '<!-- BEGIN LIGHTRAG CUSTOM -->'
}

_lightrag_agents_end_marker() {
    printf '%s' '<!-- END LIGHTRAG CUSTOM -->'
}

_lightrag_agents_custom_block() {
    cat <<'EOF'
<!-- BEGIN LIGHTRAG CUSTOM -->

## LightRAG + Course Corpus

- WSL Debian is the execution environment for project tools.
- If you are running from Windows or PowerShell, switch into WSL Debian before using LightRAG.
- This workspace is for documents, notes, PDFs and study material, not for codebase graph analysis.
- If `inputs/` and `rag_storage/` exist, consult LightRAG first for questions about the corpus before answering from memory.
- For a new workspace, start with `lightrag_run .` or `lightrag_seed` so the project files and agent instructions are written once.
- Prefer `lightrag_query "<question>"` for content questions and `lightrag_open .` for browsing.
- After adding, editing or importing documents, run `lightrag_refresh .` so the corpus stays current.
- Keep source material inside `inputs/`; keep knowledge notes inside `notes/`.
- If retrieval is weak, add more source material or split topics into smaller notes.
- Codex, Claude and Antigravity should all follow this same LightRAG workspace flow.

<!-- END LIGHTRAG CUSTOM -->
EOF
}

_lightrag_upsert_agents_block() {
    local agents_file temp_file begin_marker end_marker content
    agents_file="$1"
    begin_marker="$(_lightrag_agents_begin_marker)"
    end_marker="$(_lightrag_agents_end_marker)"
    temp_file="$(mktemp)"

    if [ -f "$agents_file" ]; then
        awk -v begin="$begin_marker" -v end="$end_marker" '
            BEGIN { skip = 0 }
            $0 == begin { skip = 1; next }
            $0 == end { skip = 0; next }
            skip == 0 { print }
        ' "$agents_file" > "$temp_file"
    else
        : > "$temp_file"
    fi

    content="$(cat "$temp_file")"
    : > "$temp_file"
    if [ -n "$content" ]; then
        printf '%s\n\n' "$content" >> "$temp_file"
    fi
    _lightrag_agents_custom_block >> "$temp_file"

    mv "$temp_file" "$agents_file"
}

_lightrag_setup_project() {
    local root agents_file claude_file antigravity_rules_file antigravity_workflow_file
    root="${1:-$PWD}"
    agents_file="$root/AGENTS.md"
    claude_file="$root/CLAUDE.md"
    antigravity_rules_file="$root/.agents/rules/lightrag.md"
    antigravity_workflow_file="$root/.agents/workflows/lightrag.md"

    mkdir -p "$root/inputs" "$root/rag_storage" || return 1

    _lightrag_append_line "$root/.gitignore" "rag_storage/" || return 1
    _lightrag_append_line "$root/.gitignore" ".env" || return 1

    if [ ! -f "$root/.env.example" ]; then
        cat > "$root/.env.example" <<'EOF'
INPUT_DIR=./inputs
WORKING_DIR=./rag_storage
LIGHTRAG_HOST=127.0.0.1
LIGHTRAG_PORT=9621
# LIGHTRAG_API_KEY=
#
# Configuracion local recomendada con Ollama:
# LLM_BINDING=ollama
# LLM_BINDING_HOST=http://localhost:11434
# LLM_MODEL=llama3.2:3b
# EMBEDDING_BINDING=ollama
# EMBEDDING_BINDING_HOST=http://localhost:11434
# EMBEDDING_MODEL=bge-m3:latest
#
# Cambia estos valores si usas otro proveedor (OpenAI, Gemini, etc.).
EOF
    fi

    _lightrag_upsert_agents_block "$agents_file"
    _lightrag_upsert_agents_block "$claude_file"

    mkdir -p "$(dirname "$antigravity_rules_file")" "$(dirname "$antigravity_workflow_file")" || return 1
    _lightrag_upsert_agents_block "$antigravity_rules_file"
    _lightrag_upsert_agents_block "$antigravity_workflow_file"
}

lightrag_help() {
    cat <<'EOF'
LightRAG helpers

lightrag_check
lightrag_install
lightrag_update
lightrag_uninstall
lightrag_workspace [ruta|.] [workspace]
lightrag_serve [ruta|.] [port] [workspace]
lightrag_query [ruta|.] "pregunta" [mode]
lightrag_status [ruta|.] [port]
lightrag_open [ruta|.] [port]
lightrag_ingest [fuente] [ruta|.]
lightrag_seed [ruta|.] [nombre]
lightrag_refresh [ruta|.] [fuente] [port]
lightrag_run [ruta|.] [fuente] [nombre] [port]

Niveles de comando:
- lightrag_install
    Instala LightRAG globalmente con uv tool. La opcion recomendada es
    `lightrag-hku[api]`, porque incluye el servidor, la WebUI y la API.
- lightrag_workspace [ruta|.] [workspace]
    Prepara una carpeta de curso/documentos como workspace local y escribe
    las instrucciones para Codex, Claude y Antigravity:
      - crea `inputs/` para los archivos fuente
      - crea `rag_storage/` para el estado persistente
      - agrega un `.gitignore` minimo para no versionar el storage local
      - escribe `.env.example` con las variables basicas
      - escribe el bloque de `AGENTS.md` para Codex y agentes que sigan
        ese contrato
      - escribe el mismo bloque en `CLAUDE.md`
      - escribe reglas de Antigravity en `.agents/rules/lightrag.md` y
        `.agents/workflows/lightrag.md`
- lightrag_serve [ruta|.] [port] [workspace]
    Arranca `lightrag-server` desde un workspace concreto. Por defecto usa
    host `127.0.0.1` y puerto `9621`. Puedes cambiar el host con
    `LIGHTRAG_HOST=0.0.0.0` si quieres exponerlo en la red.
- lightrag_query [ruta|.] "pregunta" [mode]
    Hace una consulta HTTP contra el servidor que ya esta corriendo. El
    modo por defecto es `mix`. Otros modos comunes: `local`, `global`,
    `hybrid`, `naive`.
- lightrag_status [ruta|.] [port]
    Consulta `/health` y muestra si el servidor responde.
- lightrag_open [ruta|.] [port]
    Abre la WebUI en el navegador.
- lightrag_ingest [fuente] [ruta|.]
    Copia documentos compatibles desde una carpeta o archivo fuente hacia
    `inputs/` del workspace. Sirve para cargar apuntes, PDFs y material de
    estudio sin hacerlo a mano.
- lightrag_seed [nombre]
    Crea una plantilla inicial de estudio usando el directorio actual como
    workspace. Agrega `notes/` y archivos base para arrancar un corpus nuevo
    de curso.
- lightrag_refresh [ruta|.] [fuente] [port]
    Repite la preparacion del workspace, ingiere material nuevo si le pasas
    una fuente y, si existe `LIGHTRAG_REFRESH_CMD`, ejecuta ese comando
    dentro del workspace. Si no hay comando custom, deja el corpus listo y
    muestra estado.
- lightrag_run [ruta|.] [fuente] [nombre] [port]
    Flujo de una sola llamada para tener el corpus listo y actualizado:
    prepara el workspace, escribe `AGENTS.md`/`CLAUDE.md`/`.agents/`, ingiere
    una fuente opcional y refresca el corpus usando
    `LIGHTRAG_REFRESH_CMD` si existe. Es la funcion principal para arrancar
    un nuevo proyecto documental.

Variables:
- LIGHTRAG_UV_PACKAGE: paquete a instalar con uv (default: lightrag-hku[api])
- LIGHTRAG_BIN: binario CLI esperado en PATH (default: lightrag-server)
- LIGHTRAG_HOST: host para servir (default: 127.0.0.1)
- LIGHTRAG_PORT: puerto por defecto (default: 9621)
- LIGHTRAG_API_KEY: api key opcional para /health y /query
- LIGHTRAG_REFRESH_CMD: comando opcional para reindexar o refrescar el
  backend cuando cambie el corpus

Typical flow:
1. lightrag_install
2. cd ./mi-curso
3. lightrag_run . ./fuentes "Mi curso"
4. lightrag_serve .
5. lightrag_open .
EOF
}

lightrag_check() {
    local missing=0

    for cmd in python3 uv curl; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '[ok] %s\n' "$cmd"
        else
            printf '[fail] %s\n' "$cmd" >&2
            missing=1
        fi
    done

    if command -v "$(_lightrag_bin)" >/dev/null 2>&1; then
        printf '[ok] %s\n' "$(_lightrag_bin)"
    else
        printf '[warn] %s no esta en PATH; corre lightrag_install\n' "$(_lightrag_bin)" >&2
        missing=1
    fi

    return "$missing"
}

lightrag_install() {
    local pkg
    pkg="$(_lightrag_pkg)"

    echo "======================================"
    echo " LightRAG Installer"
    echo "======================================"

    if ! command -v uv >/dev/null 2>&1; then
        echo "uv no esta instalado."
        echo "Instalando uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh || return 1
        export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 no esta instalado."
        return 1
    fi

    echo "Instalando LightRAG con soporte Ollama: $pkg"
    uv tool install --force --with ollama "$pkg" || return 1

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "Prueba el binario con:"
    echo ""
    echo "    lightrag_check"
    echo ""
    echo "Prepara una carpeta de curso con:"
    echo ""
    echo "    lightrag_workspace ./mi-curso"
    echo ""
}

lightrag_update() {
    local pkg
    pkg="$(_lightrag_pkg)"

    if ! command -v uv >/dev/null 2>&1; then
        echo "uv no esta instalado."
        return 1
    fi

    echo "Actualizando LightRAG con soporte Ollama: $pkg"
    uv tool install --force --with ollama "$pkg"
}

lightrag_uninstall() {
    local pkg
    pkg="$(_lightrag_pkg)"

    if ! command -v uv >/dev/null 2>&1; then
        echo "uv no esta instalado."
        return 1
    fi

    echo "Desinstalando LightRAG: $pkg"
    uv tool uninstall lightrag-hku >/dev/null 2>&1 || true
}

lightrag_workspace() {
    local target root workspace readme gitignore env_example
    target="${1:-.}"

    if [ ! -d "$target" ]; then
        mkdir -p "$target" || return 1
    fi

    workspace="$(_lightrag_workspace_name "$target" "${2:-}")" || return 1
    root="$(_lightrag_resolve_root "$target")" || return 1

    _lightrag_setup_project "$root" || return 1

    readme="$root/README.md"
    if [ ! -f "$readme" ]; then
        cat > "$readme" <<'EOF'
# LightRAG Workspace

Workspace preparado para LightRAG.

## Estructura

- `inputs/`: documentos de entrada
- `rag_storage/`: almacenamiento local del grafo y el indice
- `.env`: configuracion local del servidor

## Flujo sugerido

1. Coloca aqui tus apuntes, PDFs y documentos.
2. Configura el modelo y el embedding en `.env`.
3. Arranca el servidor con `lightrag_serve`.
4. Abre la WebUI con `lightrag_open`.
EOF
    fi

    echo "Workspace LightRAG preparado en: $root"
    echo "Workspace name: $workspace"
    echo "Archivos listos:"
    echo "  - $root/inputs"
    echo "  - $root/rag_storage"
    echo "  - $root/.gitignore"
    echo "  - $root/.env.example"
    echo "  - $root/README.md"
}

lightrag_serve() {
    local target root port workspace host
    target="${1:-.}"
    port="${2:-$(_lightrag_default_port)}"
    workspace="${3:-}"

    root="$(_lightrag_resolve_root "$target")" || return 1
    if [ -z "$workspace" ]; then
        workspace="$(_lightrag_workspace_name "$root")" || return 1
    fi
    host="$(_lightrag_default_host)"

    if ! command -v "$(_lightrag_bin)" >/dev/null 2>&1; then
        echo "No encontre $(_lightrag_bin). Ejecuta lightrag_install primero."
        return 1
    fi

    echo "Iniciando LightRAG en $host:$port"
    echo "  root: $root"
    echo "  workspace: $workspace"
    echo "  inputs: $root/inputs"
    echo "  storage: $root/rag_storage"

    (
        cd "$root" || exit 1
        INPUT_DIR="$root/inputs" \
        WORKING_DIR="$root/rag_storage" \
        LIGHTRAG_HOST="$host" \
        LIGHTRAG_PORT="$port" \
        "$(_lightrag_bin)" --host "$host" --port "$port" --working-dir "$root/rag_storage" --input-dir "$root/inputs" --workspace "$workspace"
    )
}

lightrag_status() {
    local target root port url auth_header health
    target="${1:-.}"
    port="${2:-$(_lightrag_default_port)}"
    root="$(_lightrag_resolve_root "$target")" || return 1
    url="http://$(_lightrag_default_host):$port"

    echo "workspace: $root"
    echo "server: $url"

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl no esta instalado."
        return 1
    fi

    auth_header=()
    if [ -n "${LIGHTRAG_API_KEY:-}" ]; then
        auth_header=(-H "X-API-Key: $LIGHTRAG_API_KEY")
    fi

    health="$(curl -sS -m 8 "${auth_header[@]}" "$url/health" 2>/dev/null)"
    if [ -n "$health" ]; then
        echo "$health"
        return 0
    fi

    echo "No pude consultar /health en $url"
    return 1
}

lightrag_query() {
    local target question mode root url payload auth_header
    target="${1:-.}"
    question="${2:-}"
    mode="${3:-mix}"
    root="$(_lightrag_resolve_root "$target")" || return 1
    url="http://$(_lightrag_default_host):$(_lightrag_default_port)"

    if [ -z "$question" ]; then
        echo "Uso: lightrag_query [ruta|.] \"pregunta\" [mode]"
        return 1
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl no esta instalado."
        return 1
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 no esta instalado."
        return 1
    fi

    payload="$(python3 - <<'PY'
import json
import os
print(json.dumps({
    "query": os.environ["LIGHTRAG_QUERY"],
    "mode": os.environ["LIGHTRAG_MODE"],
}, ensure_ascii=False))
PY
)"

    auth_header=()
    if [ -n "${LIGHTRAG_API_KEY:-}" ]; then
        auth_header=(-H "X-API-Key: $LIGHTRAG_API_KEY")
    fi

    echo "workspace: $root"
    echo "query: $question"
    echo "mode: $mode"
    echo ""

    LIGHTRAG_QUERY="$question" LIGHTRAG_MODE="$mode" \
    curl -sS "${auth_header[@]}" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$url/query"
}

lightrag_open() {
    local target port url
    target="${1:-.}"
    port="${2:-$(_lightrag_default_port)}"
    url="http://$(_lightrag_default_host):$port/webui"

    if ! _lightrag_resolve_root "$target" >/dev/null 2>&1; then
        return 1
    fi

    _lightrag_open_url "$url"
}

lightrag_ingest() {
    local source target root dest copied
    source="${1:-}"
    target="${2:-.}"

    if [ -z "$source" ]; then
        echo "Uso: lightrag_ingest <fuente> [ruta|.]"
        return 1
    fi

    root="$(_lightrag_resolve_root "$target")" || return 1
    dest="$root/inputs"

    if [ ! -e "$source" ]; then
        echo "La fuente no existe: $source"
        return 1
    fi

    mkdir -p "$dest" || return 1

    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 no esta instalado."
        return 1
    fi

    LIGHTRAG_SOURCE="$source" LIGHTRAG_DEST="$dest" python3 <<'PY'
import os
import shutil
import sys
from pathlib import Path

src = Path(os.environ["LIGHTRAG_SOURCE"]).expanduser().resolve()
dest = Path(os.environ["LIGHTRAG_DEST"]).expanduser().resolve()
allowed = {".md", ".markdown", ".txt", ".rst", ".org", ".pdf", ".docx", ".pptx", ".html", ".htm", ".csv", ".tsv", ".json", ".jsonl", ".xml", ".yaml", ".yml", ".png", ".jpg", ".jpeg", ".webp", ".gif"}

def is_allowed(path: Path) -> bool:
    return path.suffix.lower() in allowed

copied = 0
if src.is_file():
    if is_allowed(src):
        target = dest / src.name
        shutil.copy2(src, target)
        copied = 1
elif src.is_dir():
    for path in src.rglob("*"):
        if not path.is_file():
            continue
        if path.name.startswith(".") or any(part.startswith(".") for part in path.relative_to(src).parts):
            continue
        if not is_allowed(path):
            continue
        rel = path.relative_to(src)
        target = dest / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        copied += 1
else:
    print(f"La fuente no existe: {src}", file=sys.stderr)
    raise SystemExit(1)

print(f"Copiados {copied} archivo(s) a {dest}")
PY
}

lightrag_seed() {
    local root name notes_dir
    root="$PWD"
    name="${1:-}"

    if [ -z "$name" ]; then
        name="$(basename "$root")"
    fi

    lightrag_workspace "$root" "$name" || return 1

    notes_dir="$root/notes"
    mkdir -p "$notes_dir" || return 1

    if [ ! -f "$notes_dir/00-index.md" ]; then
        cat > "$notes_dir/00-index.md" <<EOF
# $name

## Objetivo

Describe aqui el tema central del curso.

## Temas

- Tema 1
- Tema 2
- Tema 3

## Preguntas abiertas

- 

## Fuentes

- 
EOF
    fi

    if [ ! -f "$notes_dir/glossary.md" ]; then
        cat > "$notes_dir/glossary.md" <<EOF
# Glosario - $name

- 
EOF
    fi

    if [ ! -f "$notes_dir/questions.md" ]; then
        cat > "$notes_dir/questions.md" <<EOF
# Preguntas - $name

- 
EOF
    fi

    echo "Seed LightRAG listo en: $root"
    echo "Notas base creadas en: $notes_dir"
}

lightrag_run() {
    local target source name port root
    target="${1:-.}"
    source="${2:-}"
    name="${3:-}"
    port="${4:-$(_lightrag_default_port)}"

    root="$(_lightrag_resolve_root "$target")" || return 1

    lightrag_workspace "$root" "$name" || return 1

    if [ -n "$source" ]; then
        lightrag_ingest "$source" "$root" || return 1
    fi

    if [ -n "${LIGHTRAG_REFRESH_CMD:-}" ]; then
        echo "Ejecutando refresh custom: ${LIGHTRAG_REFRESH_CMD}"
        (
            cd "$root" || exit 1
            LIGHTRAG_REFRESH_CMD="${LIGHTRAG_REFRESH_CMD}" sh -c "${LIGHTRAG_REFRESH_CMD}"
        ) || return 1
    else
        echo "No hay LIGHTRAG_REFRESH_CMD configurado; usando estado actual del corpus."
    fi

    lightrag_status "$root" "$port" || true
}

lightrag_refresh() {
    local target source port root refresh_cmd
    target="${1:-.}"
    source="${2:-}"
    port="${3:-$(_lightrag_default_port)}"

    root="$(_lightrag_resolve_root "$target")" || return 1

    lightrag_workspace "$root" || return 1

    if [ -n "$source" ]; then
        lightrag_ingest "$source" "$root" || return 1
    fi

    refresh_cmd="${LIGHTRAG_REFRESH_CMD:-}"
    if [ -n "$refresh_cmd" ]; then
        echo "Ejecutando refresh custom: $refresh_cmd"
        (
            cd "$root" || exit 1
            LIGHTRAG_REFRESH_CMD="$refresh_cmd" sh -c "$refresh_cmd"
        ) || return 1
    else
        echo "No hay LIGHTRAG_REFRESH_CMD configurado; no ejecuto reindexado especifico del backend."
    fi

    lightrag_status "$root" "$port" || true

    echo "Resumen del corpus:"
    if [ -d "$root/inputs" ]; then
        printf '  inputs: %s\n' "$(find "$root/inputs" -type f 2>/dev/null | wc -l | tr -d ' ')"
    else
        printf '  inputs: 0\n'
    fi
    if [ -d "$root/notes" ]; then
        printf '  notes:  %s\n' "$(find "$root/notes" -type f 2>/dev/null | wc -l | tr -d ' ')"
    else
        printf '  notes:  0\n'
    fi
    if [ -d "$root/rag_storage" ]; then
        printf '  cache:  %s\n' "$(find "$root/rag_storage" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')"
    else
        printf '  cache:  0\n'
    fi
}
