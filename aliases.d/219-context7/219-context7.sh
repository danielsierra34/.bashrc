########################################################################################## CONTEXT7

# Context7 (upstash/context7): servidor MCP remoto que resuelve documentacion
# de librerias actualizada (resolve-library-id -> get-library-docs) contra
# mcp.context7.com. A diferencia de Graphify (217) y Serena (218), Context7 NO
# indexa tu codigo ni genera estado local por proyecto - es un servicio de
# consulta de docs, agnostico de proyecto. Por eso context7_run no prepara
# nada: hace un smoke test real de conectividad end-to-end.
#
# Requiere Node.js >= 20 (probado: @upstash/context7-mcp y la CLI `ctx7`
# crashean en Node 18.x con "ReferenceError: File is not defined" / "Unexpected
# token 'with'" - usan APIs de undici/import-attributes que no existen antes
# de Node 20). Si administras Node con nvm, `nvm ls` debe mostrar >=20 como
# default; si no, `nvm install 20 && nvm alias default 20`.

_context7_pkg() {
    printf '%s' "${CONTEXT7_UV_PACKAGE:-@upstash/context7-mcp}"
}

_context7_cli_pkg() {
    printf '%s' "${CONTEXT7_CLI_PACKAGE:-ctx7}"
}

_context7_node_major() {
    command -v node >/dev/null 2>&1 || return 1
    node -e 'process.stdout.write(String(process.versions.node.split(".")[0]))' 2>/dev/null
}

_context7_node_ok() {
    local major
    major="$(_context7_node_major)"
    [ -n "$major" ] && [ "$major" -ge 20 ] 2>/dev/null
}

# Antigravity no tiene comando de setup dedicado para Context7 (a diferencia
# de Claude Code/Codex): solo config manual, con la misma forma que ya usa
# para Serena (mismo archivo, entrada distinta bajo mcpServers).
_context7_antigravity_config_path() {
    printf '%s' "${CONTEXT7_ANTIGRAVITY_CONFIG:-$HOME/.gemini/antigravity/mcp_config.json}"
}

# Fusiona (no sobreescribe) el bloque mcpServers.context7 en el JSON de
# Antigravity. Mismo patron que _serena_configure_antigravity (218-serena):
# python3 para no depender de jq, preserva cualquier otra entrada existente,
# escritura atomica via archivo temporal + os.replace.
_context7_configure_antigravity() {
    local config_path
    config_path="$(_context7_antigravity_config_path)"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "[warn] python3 no encontrado; no se pudo configurar Antigravity en $config_path" >&2
        return 1
    fi

    mkdir -p "$(dirname "$config_path")" || return 1

    CONTEXT7_AG_CONFIG_PATH="$config_path" CONTEXT7_AG_API_KEY="${CONTEXT7_API_KEY:-}" python3 <<'PY'
import json
import os
import sys

path = os.environ["CONTEXT7_AG_CONFIG_PATH"]
api_key = os.environ.get("CONTEXT7_AG_API_KEY", "")

desired = {"serverUrl": "https://mcp.context7.com/mcp"}
if api_key:
    desired["headers"] = {"Authorization": f"Bearer {api_key}"}

data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        print(f"[warn] {path} no es JSON valido ({exc}); no se modifica.", file=sys.stderr)
        sys.exit(1)

servers = data.setdefault("mcpServers", {})

if servers.get("context7") == desired:
    print(f"Sin cambios: {path}")
    sys.exit(0)

servers["context7"] = desired

tmp_path = path + ".tmp"
with open(tmp_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp_path, path)

print(f"Actualizado: {path}")
PY
}

context7_help() {
    cat <<'EOF'
Context7 helpers

context7_check
context7_install
context7_update
context7_uninstall
context7_run [ruta|.] [query]

Niveles de comandos:
- context7_install
    Instalacion GLOBAL: no hay binario que instalar (Context7 se ejecuta via
    `npx -y @upstash/context7-mcp`, sin uv/pip). Este comando registra el
    servidor MCP UNA sola vez para cada cliente disponible:
      - Claude Code: `claude mcp add --scope user context7 -- npx -y ...`
        (requiere `claude` en PATH)
      - Codex:       `codex mcp add context7 -- npx -y ...`
        (requiere `codex` en PATH)
      - Antigravity: parcheo manual de ~/.gemini/antigravity/mcp_config.json
        (mismo archivo que usa Serena, entrada separada)
    Cada cliente se omite de forma independiente si su CLI no esta disponible.
- context7_run [ruta|.] [query]
    Context7 NO indexa proyectos (no hay grafo ni cache de simbolos como en
    Graphify/Serena). Este comando hace un smoke test real de conectividad:
    resuelve una libreria (detectada de package.json/requirements.txt en
    <ruta>, o "react" por defecto) via `ctx7 library`, y pide su
    documentacion via `ctx7 docs`. Sirve para confirmar que el pipeline
    completo (red + API key si la tienes) funciona.

Environment:
- CONTEXT7_API_KEY: opcional. Sin ella, Context7 funciona con rate limit mas
  bajo. Gratis en https://context7.com/dashboard
- CONTEXT7_UV_PACKAGE: paquete MCP a usar (default: @upstash/context7-mcp)
- CONTEXT7_CLI_PACKAGE: paquete de la CLI de pruebas (default: ctx7)
- CONTEXT7_ANTIGRAVITY_CONFIG: ruta del mcp_config.json de Antigravity

Typical flow:
1. context7_check
2. export CONTEXT7_API_KEY=...   (opcional pero recomendado)
3. context7_install
4. context7_run .
EOF
}

context7_check() {
    local missing=0 node_major
    for cmd in node npm npx; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '[ok] %s\n' "$cmd"
        else
            printf '[fail] %s\n' "$cmd" >&2
            missing=1
        fi
    done

    if command -v node >/dev/null 2>&1; then
        node_major="$(_context7_node_major)"
        if [ -n "$node_major" ] && [ "$node_major" -ge 20 ] 2>/dev/null; then
            printf '[ok] node >= 20 (%s)\n' "$(node --version)"
        else
            printf '[fail] node %s es muy viejo; @upstash/context7-mcp y ctx7 requieren Node >= 20 (crashean en 18.x). Si usas nvm: nvm install 20 && nvm alias default 20\n' "$(node --version 2>/dev/null)" >&2
            missing=1
        fi
    fi

    if [ -n "${CONTEXT7_API_KEY:-}" ]; then
        printf '[ok] CONTEXT7_API_KEY configurada\n'
    else
        printf '[warn] CONTEXT7_API_KEY no configurada; Context7 funciona sin key pero con rate limit mas bajo (gratis en https://context7.com/dashboard)\n'
    fi

    if command -v claude >/dev/null 2>&1; then
        printf '[ok] claude\n'
    else
        printf '[warn] claude CLI no encontrado; el registro MCP para Claude Code se omitira\n'
    fi

    if command -v codex >/dev/null 2>&1; then
        printf '[ok] codex\n'
    else
        printf '[warn] codex CLI no encontrado; el registro MCP para Codex se omitira\n'
    fi

    return "$missing"
}

context7_install() {
    local pkg
    pkg="$(_context7_pkg)"

    echo "======================================"
    echo " Context7 Installer"
    echo "======================================"

    if ! command -v npx >/dev/null 2>&1; then
        echo "npx no esta disponible (viene con Node.js/npm)."
        echo "Si usas nvm: nvm install 20"
        return 1
    fi

    if ! _context7_node_ok; then
        echo "[warn] Node $(node --version 2>/dev/null) detectado (<20)." >&2
        echo "[warn] @upstash/context7-mcp fallara en runtime (ReferenceError: File is not defined)." >&2
        echo "[warn] Si usas nvm: nvm install 20 && nvm alias default 20, luego reintenta." >&2
        return 1
    fi

    if [ -z "${CONTEXT7_API_KEY:-}" ]; then
        echo "[nota] CONTEXT7_API_KEY no configurada; se registra sin API key (rate limit mas bajo)."
        echo "[nota] Consigue una gratis en https://context7.com/dashboard y exportala antes de reinstalar."
    fi

    echo ""
    if command -v claude >/dev/null 2>&1; then
        echo "Registrando Context7 como servidor MCP global para Claude Code..."
        if [ -n "${CONTEXT7_API_KEY:-}" ]; then
            claude mcp add --scope user context7 -- npx -y "$pkg" --api-key "$CONTEXT7_API_KEY" \
                || echo "[warn] 'claude mcp add context7' fallo; revisa 'claude mcp list' manualmente." >&2
        else
            claude mcp add --scope user context7 -- npx -y "$pkg" \
                || echo "[warn] 'claude mcp add context7' fallo; revisa 'claude mcp list' manualmente." >&2
        fi
    else
        echo "[warn] 'claude' CLI no encontrado; se omite el registro MCP con Claude Code." >&2
    fi

    echo ""
    if command -v codex >/dev/null 2>&1; then
        echo "Registrando Context7 como servidor MCP global para Codex..."
        if [ -n "${CONTEXT7_API_KEY:-}" ]; then
            codex mcp add context7 -- npx -y "$pkg" --api-key "$CONTEXT7_API_KEY" \
                || echo "[warn] 'codex mcp add context7' fallo; revisa la config de Codex manualmente." >&2
        else
            codex mcp add context7 -- npx -y "$pkg" \
                || echo "[warn] 'codex mcp add context7' fallo; revisa la config de Codex manualmente." >&2
        fi
    else
        echo "[warn] 'codex' CLI no encontrado; se omite el registro MCP con Codex." >&2
    fi

    echo ""
    echo "Configurando Antigravity (sin comando dedicado; parcheo manual del MCP config)..."
    _context7_configure_antigravity || echo "[warn] No se pudo configurar Antigravity automaticamente." >&2

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "Esta instalacion es global (registro MCP en Claude Code, Codex y Antigravity)."
    echo "No hay ningun proyecto que preparar: Context7 no indexa codigo."
    echo ""
    echo "Para probar que responde de verdad:"
    echo ""
    echo "    context7_run ."
    echo ""
}

context7_update() {
    local pkg
    pkg="$(_context7_pkg)"

    if ! command -v npx >/dev/null 2>&1; then
        echo "npx no esta disponible."
        return 1
    fi

    # No hay binario persistente que actualizar (npx sin version fijada
    # siempre resuelve contra la ultima publicada en cada corrida); "update"
    # aqui es reaplicar el registro MCP en los 3 clientes, util si cambio la
    # API key o el formato de config de algun cliente.
    echo "Context7 se ejecuta via npx (sin instalacion persistente); reaplicando registro MCP..."

    if command -v claude >/dev/null 2>&1; then
        if [ -n "${CONTEXT7_API_KEY:-}" ]; then
            claude mcp add --scope user context7 -- npx -y "$pkg" --api-key "$CONTEXT7_API_KEY" \
                || echo "[warn] 'claude mcp add context7' fallo al reaplicar." >&2
        else
            claude mcp add --scope user context7 -- npx -y "$pkg" \
                || echo "[warn] 'claude mcp add context7' fallo al reaplicar." >&2
        fi
    else
        echo "[warn] 'claude' CLI no encontrado; no se reaplico el registro de Claude Code." >&2
    fi

    if command -v codex >/dev/null 2>&1; then
        if [ -n "${CONTEXT7_API_KEY:-}" ]; then
            codex mcp add context7 -- npx -y "$pkg" --api-key "$CONTEXT7_API_KEY" \
                || echo "[warn] 'codex mcp add context7' fallo al reaplicar." >&2
        else
            codex mcp add context7 -- npx -y "$pkg" \
                || echo "[warn] 'codex mcp add context7' fallo al reaplicar." >&2
        fi
    else
        echo "[warn] 'codex' CLI no encontrado; no se reaplico el registro de Codex." >&2
    fi

    _context7_configure_antigravity || echo "[warn] No se pudo reaplicar la config de Antigravity." >&2
}

context7_uninstall() {
    echo "Context7 no tiene instalacion persistente (corre via npx bajo demanda);"
    echo "no hay binario ni paquete uv/pip que desinstalar."
    echo ""
    echo "El registro MCP no se elimina automaticamente en ningun cliente."
    echo "Si quieres limpiarlo:"
    echo "  Claude Code:  claude mcp remove context7"
    echo "  Codex:        revisa la config de Codex (mcp remove context7 si existe)"
    echo "  Antigravity:  quita el bloque \"context7\" de mcpServers en ~/.gemini/antigravity/mcp_config.json"
}

# Mejor esfuerzo: primera dependencia declarada en package.json o
# requirements.txt del directorio dado. No es critico acertar - solo alimenta
# el smoke test de context7_run; si no encuentra nada, el caller usa "react"
# como fallback fijo.
_context7_detect_library() {
    local dir="$1" lib

    if [ -f "$dir/package.json" ] && command -v python3 >/dev/null 2>&1; then
        lib="$(CONTEXT7_DETECT_PKG_JSON="$dir/package.json" python3 -c '
import json
import os

path = os.environ["CONTEXT7_DETECT_PKG_JSON"]
try:
    with open(path, "r", encoding="utf-8") as f:
        d = json.load(f)
except Exception:
    raise SystemExit(1)

deps = {}
deps.update(d.get("dependencies", {}))
deps.update(d.get("devDependencies", {}))
if deps:
    print(sorted(deps)[0])
' 2>/dev/null)"
        if [ -n "$lib" ]; then
            printf '%s' "$lib"
            return 0
        fi
    fi

    if [ -f "$dir/requirements.txt" ]; then
        lib="$(grep -vE '^[[:space:]]*(#|$)' "$dir/requirements.txt" | head -n1 | sed -E 's/[<>=!~; ].*//')"
        if [ -n "$lib" ]; then
            printf '%s' "$lib"
            return 0
        fi
    fi

    return 1
}

context7_run() {
    local target query lib lib_id cli_pkg rc=0
    target="${1:-.}"
    query="${2:-usage}"
    cli_pkg="$(_context7_cli_pkg)"

    if ! command -v npx >/dev/null 2>&1; then
        echo "npx no esta disponible (instala Node.js/npm primero)."
        return 1
    fi

    if ! _context7_node_ok; then
        echo "[warn] Node $(node --version 2>/dev/null) detectado (<20); el smoke test probablemente falle en runtime." >&2
    fi

    echo "Context7 no indexa proyectos: no hay estado local que preparar (a diferencia de graphify_run/serena_run)."
    echo "Este comando hace una llamada real resolve-library-id + get-library-docs contra mcp.context7.com."
    echo ""

    lib="$(_context7_detect_library "$target" 2>/dev/null)"
    lib="${lib:-react}"

    echo "1/2 resolve-library-id: buscando '$lib'..."
    lib_id="$(npx -y "$cli_pkg" library "$lib" --json 2>/dev/null | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)

if not data:
    sys.exit(1)

print(data[0]["id"])
' 2>/dev/null)"

    if [ -z "$lib_id" ]; then
        echo "[fail] No se pudo resolver un library id para '$lib'. Revisa conectividad / Node >= 20." >&2
        return 1
    fi
    echo "  -> $lib_id"

    echo "2/2 get-library-docs: pidiendo \"$query\" para $lib_id..."
    if npx -y "$cli_pkg" docs "$lib_id" "$query" --json 2>/dev/null | python3 -c '
import json
import sys

data = json.load(sys.stdin)
raw = json.dumps(data)
print(f"OK: recibidos {len(raw)} bytes de docs.")
'; then
        echo ""
        echo "Context7 responde correctamente end-to-end."
    else
        echo "[fail] La llamada get-library-docs fallo." >&2
        rc=1
    fi

    return "$rc"
}
