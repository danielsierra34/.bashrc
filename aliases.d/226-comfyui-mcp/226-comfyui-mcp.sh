########################################################################################## COMFYUI (Comfy Cloud MCP)

# Comfy Cloud MCP: genera imagenes/video/audio via ComfyUI corriendo en la
# nube de comfy.org - NO ComfyUI local. Se eligio este camino a proposito:
# esta maquina no tiene GPU dedicada (Intel Iris Xe integrada, sin CUDA;
# verificado con Get-CimInstance Win32_VideoController) y no habia ninguna
# instancia de ComfyUI corriendo (ni en WSL ni en Windows, puerto 8188
# libre). Comfy Cloud es 100% remoto: no hay paquete que instalar, ni
# binario, ni descarga de modelos de varios GB - es un endpoint MCP HTTP
# (https://cloud.comfy.org/mcp) al que los clientes se conectan directo.
#
# Verificado con una llamada real: el endpoint responde (HTTP 401 sin auth,
# con mensaje claro pidiendo header X-API-Key o Authorization: Bearer) - asi
# que _check/_run de este modulo hacen una prueba de alcance real, no
# simulada, pero SIN poder probar llamadas autenticadas (generar una imagen)
# porque este modulo no tiene tu API key ni corre el flujo OAuth interactivo
# por vos.
#
# Auth: OAuth (clientes interactivos, via `/mcp` en Claude Code o
# `codex mcp login`) o API key (headless/CI, header X-API-Key, se consigue
# en platform.comfy.org/profile/api-keys, empieza con "comfyui-").
# Free tier: herramientas de busqueda (search_templates/search_models/
# search_nodes) gratis con cuenta; generar (run_template/submit_workflow)
# requiere suscripcion, salvo 5 corridas gratis para probar.

_comfyui_url() {
    printf '%s' "${COMFYUI_MCP_URL:-https://cloud.comfy.org/mcp}"
}

_comfyui_antigravity_config_path() {
    printf '%s' "${COMFYUI_ANTIGRAVITY_CONFIG:-$HOME/.gemini/antigravity/mcp_config.json}"
}

# Mismo patron que context7/serena/playwright (218-220): merge seguro de
# JSON via python3, preserva cualquier otra entrada de mcpServers. Forma
# "serverUrl"+"headers" (remoto), igual que context7 - no "command"+"args"
# porque no hay nada local que correr.
_comfyui_configure_antigravity() {
    local config_path url
    config_path="$(_comfyui_antigravity_config_path)"
    url="$(_comfyui_url)"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "[warn] python3 no encontrado; no se pudo configurar Antigravity en $config_path" >&2
        return 1
    fi

    mkdir -p "$(dirname "$config_path")" || return 1

    COMFYUI_AG_CONFIG_PATH="$config_path" COMFYUI_AG_URL="$url" COMFYUI_AG_API_KEY="${COMFY_API_KEY:-}" python3 <<'PY'
import json
import os
import sys

path = os.environ["COMFYUI_AG_CONFIG_PATH"]
url = os.environ["COMFYUI_AG_URL"]
api_key = os.environ.get("COMFYUI_AG_API_KEY", "")

desired = {"serverUrl": url}
if api_key:
    desired["headers"] = {"X-API-Key": api_key}

data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        print(f"[warn] {path} no es JSON valido ({exc}); no se modifica.", file=sys.stderr)
        sys.exit(1)

servers = data.setdefault("mcpServers", {})

if servers.get("comfy-cloud") == desired:
    print(f"Sin cambios: {path}")
    sys.exit(0)

servers["comfy-cloud"] = desired

tmp_path = path + ".tmp"
with open(tmp_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp_path, path)

print(f"Actualizado: {path}")
PY
}

comfyui_help() {
    cat <<'EOF'
Comfy Cloud MCP helpers (ComfyUI en la nube, sin GPU local)

comfyui_check
comfyui_install
comfyui_update [api_key]
comfyui_uninstall
comfyui_run

Por que Cloud y no ComfyUI local: esta maquina no tiene GPU dedicada.
Comfy Cloud es un endpoint MCP remoto (https://cloud.comfy.org/mcp) - nada
que instalar localmente, ni siquiera un paquete npm/pip.

- comfyui_install
    Registra el MCP en Claude Code, Codex y Antigravity apuntando al
    endpoint remoto. Si COMFY_API_KEY esta configurada, la pasa como header
    X-API-Key en cada uno; si no, Claude Code/Codex quedan listos para
    autenticar por OAuth interactivo (`/mcp` en Claude Code,
    `codex mcp login comfy-cloud` en Codex) - Antigravity no tiene ese flujo
    interactivo documentado, asi que ahi SI hace falta la API key.
- comfyui_update [api_key]
    Reaplica el registro en los 3 clientes (igual que comfyui_install). Si
    le pasas la API key como parametro (comfyui_update comfyui-xxx), ademas:
      1. La exporta como COMFY_API_KEY para esta shell.
      2. La guarda en ~/.bashrc.local (creandolo si hace falta) y asegura
         que ~/.bashrc lo cargue - asi persiste sin tener que pasarla de
         nuevo en la siguiente shell. Nota: queda en tu ~/.bash_history en
         texto plano al escribir el comando; si te importa, exporta
         COMFY_API_KEY vos mismo antes y corre `comfyui_update` sin argumento.
    comfyui_install NO acepta este parametro a proposito (evita que instalar
    y actualizar tengan comportamiento distinto respecto a la key).
- comfyui_run
    Sin API key ni sesion OAuth de este modulo, no se pueden probar
    llamadas autenticadas (generar una imagen real). Este comando hace lo
    que SI se puede verificar sin credenciales: que el endpoint responde y
    exige auth correctamente (HTTP 401 con WWW-Authenticate), confirmando
    que el MCP esta vivo y accesible desde esta red.

Herramientas que expone (una vez autenticado, las usa el agente solo):
  Busqueda (gratis con cuenta): search_templates, search_models,
    search_nodes, get_template, get_node
  Generacion (requiere suscripcion o las 5 corridas gratis iniciales):
    run_template, submit_workflow, partner_generate, upload_file
  Jobs: get_job_status, wait_for_job, get_output, submit_batch
  Workflows: list_saved_workflows, save_workflow, share_workflow

Environment:
- COMFY_API_KEY: API key para uso headless (X-API-Key), formato "comfyui-...".
    Conseguila en https://platform.comfy.org/profile/api-keys
- COMFYUI_MCP_URL: endpoint del MCP (default: https://cloud.comfy.org/mcp)
- COMFYUI_ANTIGRAVITY_CONFIG: ruta del mcp_config.json de Antigravity

Typical flow:
1. comfyui_check
2. comfyui_install                    (o autenticar por OAuth despues, sin key)
   -- o, si ya tenes la API key --
2. comfyui_update comfyui-...         (la exporta, la guarda en ~/.bashrc.local, e instala)
3. comfyui_run   (solo confirma alcance; la generacion real se prueba desde el agente)
EOF
}

comfyui_check() {
    local missing=0 url http_code
    url="$(_comfyui_url)"

    if command -v curl >/dev/null 2>&1; then
        printf '[ok] curl\n'
    else
        printf '[fail] curl\n' >&2
        missing=1
    fi

    if [ -n "${COMFY_API_KEY:-}" ]; then
        printf '[ok] COMFY_API_KEY configurada\n'
    else
        printf '[warn] COMFY_API_KEY no configurada; usa OAuth interactivo en Claude Code/Codex, o configurala para Antigravity/uso headless\n'
    fi

    if command -v curl >/dev/null 2>&1; then
        http_code="$(curl -s -o /dev/null -m 8 -w '%{http_code}' "$url" 2>/dev/null)"
        if [ "$http_code" = "401" ]; then
            printf '[ok] endpoint responde (%s, exige auth como se espera): %s\n' "$http_code" "$url"
        elif [ -n "$http_code" ] && [ "$http_code" != "000" ]; then
            printf '[warn] endpoint respondio %s (no el 401 esperado sin auth); revisa manualmente: %s\n' "$http_code" "$url"
        else
            printf '[fail] no se pudo alcanzar %s (sin conexion o timeout)\n' "$url" >&2
            missing=1
        fi
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

comfyui_install() {
    local url
    url="$(_comfyui_url)"

    echo "======================================"
    echo " Comfy Cloud MCP Installer"
    echo "======================================"
    echo "Sin instalacion local: es un endpoint MCP remoto ($url)."
    echo ""

    if [ -z "${COMFY_API_KEY:-}" ]; then
        echo "[nota] COMFY_API_KEY no configurada."
        echo "[nota] Claude Code/Codex podran autenticar por OAuth despues de registrar."
        echo "[nota] Antigravity SI necesita la API key (no tiene flujo OAuth interactivo aqui):"
        echo "[nota]   consiguela en https://platform.comfy.org/profile/api-keys y reinstala."
    fi

    echo ""
    if command -v claude >/dev/null 2>&1; then
        echo "Registrando Comfy Cloud como servidor MCP para Claude Code..."
        # `claude mcp add` no actualiza un servidor que ya existe (falla con
        # "already exists" en vez de sobreescribir headers/URL) - verificado
        # probando esto en la practica: reinstalar con una API key nueva no
        # aplicaba el header hasta remover primero. Remocion silenciosa si no
        # existia (no es un error real, es el caso normal en un install limpio).
        claude mcp remove comfy-cloud -s user >/dev/null 2>&1
        if [ -n "${COMFY_API_KEY:-}" ]; then
            claude mcp add --scope user --transport http comfy-cloud "$url" -H "X-API-Key: ${COMFY_API_KEY}" \
                || echo "[warn] 'claude mcp add comfy-cloud' fallo; revisa 'claude mcp list' manualmente." >&2
        else
            claude mcp add --scope user --transport http comfy-cloud "$url" \
                || echo "[warn] 'claude mcp add comfy-cloud' fallo; revisa 'claude mcp list' manualmente." >&2
        fi
        echo "[nota] Autentica con: /mcp -> comfy-cloud -> Authenticate (dentro de Claude Code)."
    else
        echo "[warn] 'claude' CLI no encontrado; se omite el registro MCP con Claude Code." >&2
    fi

    echo ""
    if command -v codex >/dev/null 2>&1; then
        echo "Registrando Comfy Cloud como servidor MCP para Codex..."
        # Mismo criterio que Claude Code: remover primero para que un
        # re-registro (p.ej. tras agregar la API key) realmente aplique.
        codex mcp remove comfy-cloud >/dev/null 2>&1
        codex mcp add comfy-cloud --url "$url" \
            || echo "[warn] 'codex mcp add comfy-cloud' fallo; revisa la config de Codex manualmente." >&2
        echo "[nota] Autentica con: codex mcp login comfy-cloud"
        if [ -n "${COMFY_API_KEY:-}" ]; then
            echo "[nota] Para uso headless con API key, agrega a ~/.codex/config.toml:"
            echo "[nota]   [mcp_servers.comfy-cloud]"
            echo "[nota]   url = \"$url\""
            echo "[nota]   env_http_headers = { \"X-API-Key\" = \"COMFY_API_KEY\" }"
        fi
    else
        echo "[warn] 'codex' CLI no encontrado; se omite el registro MCP con Codex." >&2
    fi

    echo ""
    echo "Configurando Antigravity (sin comando dedicado; parcheo manual del MCP config)..."
    if [ -n "${COMFY_API_KEY:-}" ]; then
        _comfyui_configure_antigravity || echo "[warn] No se pudo configurar Antigravity automaticamente." >&2
    else
        echo "[warn] Sin COMFY_API_KEY, Antigravity queda sin registrar (no tiene OAuth interactivo aqui)." >&2
    fi

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "No hay ningun proyecto que preparar: Comfy Cloud es remoto y sin estado local."
    echo ""
    echo "Para confirmar que el endpoint responde (sin probar generacion real):"
    echo ""
    echo "    comfyui_run"
    echo ""
}

# Guarda COMFY_API_KEY en ~/.bashrc.local (creandolo si hace falta) y
# asegura que ~/.bashrc lo cargue. ~/.bashrc.local vive en $HOME, FUERA del
# repo git de bashrc (que esta en ~/bashrc) - no hace falta gitignore, nunca
# esta dentro del working tree del repo. Idempotente: reemplaza la linea
# existente en vez de duplicarla, y el bloque "source" en ~/.bashrc solo se
# agrega si todavia no esta.
_comfyui_persist_api_key() {
    local key="$1" local_file bashrc_file tmp_file
    local_file="$HOME/.bashrc.local"
    bashrc_file="$HOME/.bashrc"

    touch "$local_file" || return 1

    tmp_file="$(mktemp)"
    grep -v '^export COMFY_API_KEY=' "$local_file" > "$tmp_file"
    printf 'export COMFY_API_KEY="%s"\n' "$key" >> "$tmp_file"
    mv "$tmp_file" "$local_file"
    echo "Guardado en $local_file"

    if [ -f "$bashrc_file" ] && ! grep -qF '.bashrc.local' "$bashrc_file"; then
        {
            echo ""
            echo "# Secretos locales, no versionados (agregado por comfyui_update)"
            echo '[ -f ~/.bashrc.local ] && source ~/.bashrc.local'
        } >> "$bashrc_file"
        echo "Agregado a $bashrc_file: source de ~/.bashrc.local"
    fi
}

comfyui_update() {
    local api_key="${1:-}"

    if [ -n "$api_key" ]; then
        export COMFY_API_KEY="$api_key"
        _comfyui_persist_api_key "$api_key"
        echo ""
    fi

    comfyui_install
}

comfyui_uninstall() {
    echo "Comfy Cloud no tiene instalacion local que desinstalar (es un endpoint remoto)."
    echo ""
    echo "El registro MCP no se elimina automaticamente en ningun cliente."
    echo "Si quieres limpiarlo:"
    echo "  Claude Code:  claude mcp remove comfy-cloud"
    echo "  Codex:        codex mcp remove comfy-cloud (o edita ~/.codex/config.toml)"
    echo "  Antigravity:  quita el bloque \"comfy-cloud\" de mcpServers en ~/.gemini/antigravity/mcp_config.json"
}

# Smoke test HONESTO: sin API key ni sesion OAuth de este modulo, no hay
# forma de probar una llamada autenticada real (buscar un modelo, generar
# una imagen). Lo unico verificable sin credenciales es que el endpoint MCP
# esta vivo y exige auth correctamente - eso es lo que se prueba aqui.
comfyui_run() {
    local url http_code body rc=0

    url="$(_comfyui_url)"

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl no esta disponible."
        return 1
    fi

    echo "Comfy Cloud es remoto: no hay nada local que preparar."
    echo "Sin API key configurada en este modulo, no se puede probar una llamada autenticada"
    echo "(buscar un modelo, generar una imagen) - eso lo hace el agente una vez que autentiques"
    echo "por OAuth o le des tu COMFY_API_KEY."
    echo ""
    echo "Verificando que el endpoint MCP responde: $url"

    body="$(curl -s -m 10 -X POST "$url" \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"comfyui_run-smoke-test","version":"1.0"}}}' \
        -o /tmp/.comfyui_smoke_body.$$ -w '%{http_code}' 2>/dev/null)"
    http_code="$body"

    if [ "$http_code" = "401" ] && grep -q 'Authentication required' /tmp/.comfyui_smoke_body.$$ 2>/dev/null; then
        echo "OK: el endpoint respondio correctamente pidiendo autenticacion (HTTP 401)."
        cat /tmp/.comfyui_smoke_body.$$
        echo ""
    elif [ -n "${COMFY_API_KEY:-}" ] && [ "$http_code" = "200" ]; then
        echo "OK: el endpoint respondio 200 (con API key configurada)."
    else
        echo "[fail] respuesta inesperada (HTTP $http_code):" >&2
        cat /tmp/.comfyui_smoke_body.$$ >&2
        rc=1
    fi

    rm -f /tmp/.comfyui_smoke_body.$$

    return "$rc"
}
