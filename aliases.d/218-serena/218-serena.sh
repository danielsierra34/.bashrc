########################################################################################## SERENA

# Serena (oraios/serena): navegacion y edicion semantica de codigo via Language
# Server Protocol, expuesta como servidor MCP. Complementa a Graphify
# (aliases.d/217-graphify): Graphify da el mapa estatico de arquitectura
# (comunidades, god nodes, reporte); Serena da navegacion EN VIVO a nivel de
# simbolo (ir a definicion, referencias reales, refactor) para los lenguajes
# donde exista language server (poco valor extra en shell puro, mucho en
# Python/TS/Java/etc., p.ej. aliases.d/217-graphify/graphify-patch/).

_SERENA_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

_serena_bin() {
    printf '%s' "${SERENA_BIN:-serena}"
}

_serena_pkg() {
    printf '%s' "${SERENA_UV_PACKAGE:-serena-agent}"
}

# Antigravity no tiene `serena setup antigravity` (a diferencia de claude-code
# y codex): solo soporta configuracion manual, agregando un bloque
# "mcpServers.serena" a su archivo de config. La ruta no la documenta Serena;
# se infiere de `graphify antigravity install` (217-graphify.sh), que ya
# escribe/sugiere ese mismo archivo para Antigravity en este entorno.
_serena_antigravity_config_path() {
    printf '%s' "${SERENA_ANTIGRAVITY_CONFIG:-$HOME/.gemini/antigravity/mcp_config.json}"
}

# Fusiona (no sobreescribe) el bloque mcpServers.serena en el JSON de
# Antigravity. Usa python3 para no depender de jq, preserva cualquier otra
# entrada existente en mcpServers y en el resto del archivo, y escribe con
# archivo temporal + os.replace (atomico), igual que el patron
# mktemp+mv que ya usa _graphify_upsert_agents_block.
_serena_configure_antigravity() {
    local config_path serena_bin
    config_path="$(_serena_antigravity_config_path)"
    serena_bin="$(_serena_bin)"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "[warn] python3 no encontrado; no se pudo configurar Antigravity en $config_path" >&2
        return 1
    fi

    mkdir -p "$(dirname "$config_path")" || return 1

    SERENA_AG_CONFIG_PATH="$config_path" SERENA_AG_BIN="$serena_bin" python3 <<'PY'
import json
import os
import sys

path = os.environ["SERENA_AG_CONFIG_PATH"]
bin_name = os.environ["SERENA_AG_BIN"]

desired = {
    "command": bin_name,
    "args": ["start-mcp-server", "--context=antigravity"],
}

data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        print(f"[warn] {path} no es JSON valido ({exc}); no se modifica.", file=sys.stderr)
        sys.exit(1)

servers = data.setdefault("mcpServers", {})

if servers.get("serena") == desired:
    print(f"Sin cambios: {path}")
    sys.exit(0)

servers["serena"] = desired

tmp_path = path + ".tmp"
with open(tmp_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp_path, path)

print(f"Actualizado: {path}")
PY
}

serena_help() {
    cat <<'EOF'
Serena helpers

serena_check
serena_install
serena_update
serena_uninstall
serena_run [ruta|.]
serena_batch <ruta> [ruta ...]
serena_mcp_status
serena_dashboard_open

Niveles de comandos:
- serena_install
    Instalacion GLOBAL en esta shell de WSL Debian: `uv tool install serena-agent`,
    `serena init` (config global en ~/.serena/serena_config.yml) y el registro
    del servidor MCP UNA sola vez para cada cliente disponible:
      - Claude Code: `serena setup claude-code` (requiere `claude` en PATH)
      - Codex:       `serena setup codex`       (requiere `codex` en PATH)
      - Antigravity: parcheo manual de ~/.gemini/antigravity/mcp_config.json
        (Serena no tiene 'setup antigravity'; hay que pedirle al agente que
        "activate the current project" en el primer chat de cada proyecto,
        porque Antigravity no pasa el working directory en su config MCP)
    Cada cliente falla o se omite de forma independiente si su CLI no esta
    disponible. Pensado como paso GLOBAL, pero ojo: `serena init` puede
    detectar por su cuenta que el cwd desde donde se corre es un proyecto
    real y auto-registrarlo (crear .serena/project.yml ahi) como efecto
    secundario - visto en la practica corriendo serena_install parado en un
    repo con codigo fuente real. Si no quieres eso, corre serena_install
    desde $HOME o un directorio sin codigo, no desde dentro de un proyecto.
- serena_run .
    Preparacion LOCAL de un proyecto: ejecuta `serena project index .`, que
    crea .serena/project.yml si no existe (detectando lenguajes) e indexa
    los simbolos via LSP en .serena/cache/. Es el comando normal dentro de
    cualquier repo, y es seguro correrlo repetidas veces: a diferencia de
    `serena project create`, `project index` NUNCA falla por "ya existe".
    Serena genera su propio .serena/.gitignore (ignora cache/ y
    project.local.yml; project.yml SI se versiona, como AGENTS.md/CLAUDE.md
    en Graphify) - este modulo no toca el .gitignore del proyecto.

Comandos manuales utiles (no los ejecuta ningun helper de aqui):
- serena start-mcp-server --project . --context ide
    Corre el servidor MCP a mano (fuera de un cliente CLI), para probarlo o
    depurarlo. --transport streamable-http --port <N> para modo HTTP.
- serena project health-check
    Diagnostico del proyecto actual (lenguajes detectados, LSP funcionando).
- serena --context <ctx> / --mode <modo>
    Contexts: claude-code, codex, ide, desktop-app, agent, grok, ...
    Modes: planning, editing, interactive, one-shot, no-memories, ...

Environment:
- SERENA_UV_PACKAGE: paquete para `uv tool install`/`uv tool upgrade` (default: serena-agent)
- SERENA_BIN: binario esperado en PATH (default: serena)

Typical flow:
1. serena_check
2. serena_install
3. serena_run .
EOF
}

serena_check() {
    local missing=0 serena_bin serena_pkg
    serena_bin="$(_serena_bin)"
    serena_pkg="$(_serena_pkg)"

    for cmd in python3 uv; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '[ok] %s\n' "$cmd"
        else
            printf '[fail] %s\n' "$cmd" >&2
            missing=1
        fi
    done

    if command -v "$serena_bin" >/dev/null 2>&1; then
        printf '[ok] %s\n' "$serena_bin"
    else
        printf '[fail] %s (package: %s)\n' "$serena_bin" "$serena_pkg" >&2
        missing=1
    fi

    # `claude` no es requisito de Serena en si (start-mcp-server/project index
    # funcionan sin el), pero si lo es para `serena setup claude-code`, que es
    # lo que usan serena_install/serena_update para registrar el MCP server.
    if command -v claude >/dev/null 2>&1; then
        printf '[ok] claude\n'
    else
        printf '[warn] claude CLI no encontrado; "serena setup claude-code" fallara hasta que este disponible\n'
    fi

    return "$missing"
}

serena_install() {
    set -e

    local uv_pkg serena_bin
    uv_pkg="$(_serena_pkg)"
    serena_bin="$(_serena_bin)"

    echo "======================================"
    echo " Serena Installer"
    echo "======================================"

    if ! command -v uv >/dev/null 2>&1; then
        echo "uv no esta instalado."
        echo "Instalalo con graphify_install (217-graphify.sh) o manualmente:"
        echo "    curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi

    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v "$serena_bin" >/dev/null 2>&1; then
        echo "Instalando Serena..."
        uv tool install -p 3.13 "$uv_pkg"
    else
        echo "Serena ya esta instalado."
    fi

    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v "$serena_bin" >/dev/null 2>&1; then
        echo "No se pudo encontrar '$serena_bin' en PATH despues de la instalacion."
        echo "Revisa si el paquete publicado en uv tool install es '$uv_pkg'."
        return 1
    fi

    echo "Serena:"
    "$serena_bin" --version

    echo ""
    echo "Inicializando configuracion global (~/.serena/serena_config.yml)..."
    "$serena_bin" init

    echo ""
    if command -v claude >/dev/null 2>&1; then
        echo "Registrando Serena como servidor MCP global para Claude Code..."
        if ! "$serena_bin" setup claude-code; then
            echo "[warn] 'serena setup claude-code' fallo; revisa 'claude mcp list' manualmente." >&2
        fi
    else
        echo "[warn] 'claude' CLI no encontrado; se omite el registro MCP con Claude Code." >&2
        echo "[warn] Corre 'serena setup claude-code' manualmente cuando 'claude' este en PATH." >&2
    fi

    echo ""
    if command -v codex >/dev/null 2>&1; then
        echo "Registrando Serena como servidor MCP global para Codex..."
        if ! "$serena_bin" setup codex; then
            echo "[warn] 'serena setup codex' fallo; revisa la config de Codex manualmente." >&2
        fi
    else
        echo "[warn] 'codex' CLI no encontrado; se omite el registro MCP con Codex." >&2
        echo "[warn] Corre 'serena setup codex' manualmente cuando 'codex' este en PATH." >&2
    fi

    echo ""
    echo "Configurando Antigravity (Serena no tiene 'setup antigravity'; parcheo manual del MCP config)..."
    if _serena_configure_antigravity; then
        echo "[nota] Antigravity no soporta pasar el working directory en su config MCP."
        echo "[nota] En el primer chat de cada proyecto nuevo, pide: \"Activate the current project using serena's activation tool\"."
    else
        echo "[warn] No se pudo configurar Antigravity automaticamente; revisa las instrucciones manuales en la doc de Serena." >&2
    fi

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "Esta instalacion es global (Serena + registro MCP en Claude Code, Codex y Antigravity)."
    echo "No prepara ningun proyecto todavia."
    echo ""
    echo "Para preparar un proyecto (indexar simbolos via LSP):"
    echo ""
    echo "    cd /ruta/del/proyecto"
    echo "    serena_run ."
    echo ""
}

serena_update() {
    local serena_pkg serena_bin
    serena_pkg="$(_serena_pkg)"
    serena_bin="$(_serena_bin)"

    if ! command -v uv >/dev/null 2>&1; then
        echo "uv no esta instalado."
        return 1
    fi

    echo "Actualizando Serena via uv..."
    uv tool upgrade "$serena_pkg"
    hash -r

    if ! command -v "$serena_bin" >/dev/null 2>&1; then
        echo "No se encontro '$serena_bin' despues de actualizar."
        return 1
    fi

    if command -v claude >/dev/null 2>&1; then
        "$serena_bin" setup claude-code || echo "[warn] 'serena setup claude-code' fallo al reaplicar." >&2
    else
        echo "[warn] 'claude' CLI no encontrado; no se reaplico el registro MCP de Claude Code." >&2
    fi

    if command -v codex >/dev/null 2>&1; then
        "$serena_bin" setup codex || echo "[warn] 'serena setup codex' fallo al reaplicar." >&2
    else
        echo "[warn] 'codex' CLI no encontrado; no se reaplico el registro MCP de Codex." >&2
    fi

    _serena_configure_antigravity || echo "[warn] No se pudo reaplicar la config de Antigravity." >&2

    "$serena_bin" --version
}

serena_uninstall() {
    local serena_pkg
    serena_pkg="$(_serena_pkg)"

    if command -v uv >/dev/null 2>&1; then
        uv tool uninstall "$serena_pkg"
    fi

    echo "El registro MCP no se elimina automaticamente en ningun cliente."
    echo "Si quieres limpiarlo:"
    echo "  Claude Code:  claude mcp remove serena"
    echo "  Codex:        revisa la config de Codex (equivalente a 'codex mcp remove serena' si existe)"
    echo "  Antigravity:  quita el bloque \"serena\" de mcpServers en ~/.gemini/antigravity/mcp_config.json"
    echo "Los .serena/ de cada proyecto tampoco se borran; son locales por proyecto."
}

serena_run() {
    local target serena_bin prep_target rc
    target="${1:-.}"
    shift || true
    serena_bin="$(_serena_bin)"
    rc=0

    if ! command -v "$serena_bin" >/dev/null 2>&1; then
        echo "Serena no esta instalado. Ejecuta serena_install primero."
        return 1
    fi

    if [ ! -e "$target" ] && [ "$target" != "." ]; then
        echo "No existe: $target"
        return 1
    fi

    if [ -d "$target" ]; then
        prep_target="$target"
    else
        prep_target="$(dirname "$target")"
    fi

    # El workspace de Serena es SIEMPRE el target pedido, resuelto a ruta
    # absoluta/canonica - mismo criterio que graphify_run (nunca la raiz de
    # Git), asi .serena/ termina donde el usuario pidio y no en un repo
    # superior si <ruta> es una subcarpeta de un repo existente.
    prep_target="$(cd "$prep_target" 2>/dev/null && pwd -P)"
    if [ -z "$prep_target" ]; then
        echo "No pude resolver la ruta: $target"
        return 1
    fi

    # `serena project index .` crea .serena/project.yml si no existe y
    # siempre reindexa los simbolos; a diferencia de `serena project create`,
    # nunca falla por "el proyecto ya existe", por eso es seguro para correr
    # en cada `serena_run` sin logica de deteccion propia.
    #
    # A diferencia de graphify_run, aqui NO hay paso "por cliente": el registro
    # MCP de Claude Code/Codex/Antigravity es global (serena_install) y usa
    # --project-from-cwd para autodetectar el proyecto, asi que este indice
    # sirve por igual a los tres una vez registrados.
    if ( cd "$prep_target" && "$serena_bin" project index . "$@" ); then
        # Unica excepcion: Antigravity no pasa el working directory en su
        # config MCP, asi que --project-from-cwd no le sirve. Hay que activar
        # el proyecto a mano en el primer chat de CADA proyecto (no solo al
        # instalar) - ver la nota que imprime serena_install.
        echo "[nota] Si usas Antigravity con este proyecto: en el primer chat aqui, pide \"Activate the current project using serena's activation tool\"."
    else
        rc=1
    fi

    return "$rc"
}

serena_batch() {
    local path rc=0

    if [ "$#" -eq 0 ]; then
        set -- .
    fi

    for path in "$@"; do
        echo "==> $path"
        serena_run "$path" || rc=1
    done

    return "$rc"
}

serena_mcp_status() {
    if ! command -v claude >/dev/null 2>&1; then
        echo "'claude' CLI no encontrado en PATH."
        return 1
    fi

    claude mcp list 2>/dev/null | grep -i serena || echo "Serena no aparece registrado en 'claude mcp list'."
}

serena_dashboard_open() {
    local url="http://localhost:24282/dashboard/index.html"

    echo "El dashboard solo existe mientras 'serena start-mcp-server' este corriendo."
    if command -v wslview >/dev/null 2>&1; then
        wslview "$url" >/dev/null 2>&1 && return 0
    fi
    if command -v explorer.exe >/dev/null 2>&1; then
        explorer.exe "$url" >/dev/null 2>&1 && return 0
    fi
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 && return 0
    fi

    echo "No pude abrir un navegador automaticamente. Abrilo manualmente: $url"
    return 1
}
