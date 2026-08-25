########################################################################################## PLAYWRIGHT

# Playwright MCP (microsoft/playwright-mcp): servidor MCP que controla un
# browser real (Chromium/Chrome/Firefox/WebKit) via accessibility snapshots -
# navegar, hacer click, llenar formularios, capturas, etc. Como Context7 (219),
# NO indexa tu codigo ni genera estado por proyecto: playwright_run es un
# smoke test (levanta un browser real y navega a una URL), no una preparacion
# de proyecto.
#
# Requiere Node.js >= 20 (verificado: el propio paquete se niega a arrancar en
# 18.x con "Playwright requires Node.js 20 or higher").
#
# Gotcha real encontrado en este entorno (WSL Debian): el canal de browser por
# defecto de @playwright/mcp es "chrome" (Google Chrome real), que NO estaba
# instalado aqui (falla con "Chromium distribution 'chrome' is not found at
# /opt/google/chrome/chrome"). Por eso este modulo fuerza --browser chromium
# por defecto (PLAYWRIGHT_MCP_BROWSER lo puede sobreescribir) - y aun con
# --browser chromium, el binario exacto ("chrome-for-testing", version
# pineada por el paquete) puede no estar cacheado: hay que instalarlo con
# `npx @playwright/mcp install-browser chrome-for-testing` (NO es lo mismo
# que `npx playwright install chromium`, que instala una version distinta).

_playwright_pkg() {
    printf '%s' "${PLAYWRIGHT_MCP_PACKAGE:-@playwright/mcp@latest}"
}

_playwright_browser() {
    printf '%s' "${PLAYWRIGHT_MCP_BROWSER:-chromium}"
}

_playwright_node_major() {
    command -v node >/dev/null 2>&1 || return 1
    node -e 'process.stdout.write(String(process.versions.node.split(".")[0]))' 2>/dev/null
}

_playwright_node_ok() {
    local major
    major="$(_playwright_node_major)"
    [ -n "$major" ] && [ "$major" -ge 20 ] 2>/dev/null
}

# Instala el binario de browser que el --browser configurado realmente
# necesita. Solo se valido el mapeo chromium -> chrome-for-testing; para
# otros valores se intenta el nombre tal cual (puede no ser exacto, pero
# `install-browser` reenvia a `playwright install` y avisa con claridad si
# el nombre no es valido).
_playwright_install_browser() {
    local browser install_target pkg
    browser="$(_playwright_browser)"
    pkg="$(_playwright_pkg)"
    install_target="$browser"
    if [ "$browser" = "chromium" ]; then
        install_target="chrome-for-testing"
    fi

    echo "Instalando el binario de browser requerido ($install_target)..."
    npx -y "$pkg" install-browser "$install_target"
}

# Antigravity no tiene comando de setup dedicado (igual que Serena/Context7):
# parcheo manual del mismo archivo, forma LOCAL (command+args, no serverUrl -
# Playwright controla un browser en esta maquina, no puede ser un servicio
# remoto como Context7).
_playwright_antigravity_config_path() {
    printf '%s' "${PLAYWRIGHT_ANTIGRAVITY_CONFIG:-$HOME/.gemini/antigravity/mcp_config.json}"
}

_playwright_configure_antigravity() {
    local config_path pkg browser extra_args
    config_path="$(_playwright_antigravity_config_path)"
    pkg="$(_playwright_pkg)"
    browser="$(_playwright_browser)"
    extra_args="${PLAYWRIGHT_MCP_ARGS:-}"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "[warn] python3 no encontrado; no se pudo configurar Antigravity en $config_path" >&2
        return 1
    fi

    mkdir -p "$(dirname "$config_path")" || return 1

    PLAYWRIGHT_AG_CONFIG_PATH="$config_path" \
    PLAYWRIGHT_AG_PKG="$pkg" \
    PLAYWRIGHT_AG_BROWSER="$browser" \
    PLAYWRIGHT_AG_EXTRA_ARGS="$extra_args" \
    python3 <<'PY'
import json
import os
import sys

path = os.environ["PLAYWRIGHT_AG_CONFIG_PATH"]
pkg = os.environ["PLAYWRIGHT_AG_PKG"]
browser = os.environ["PLAYWRIGHT_AG_BROWSER"]
extra_args = os.environ.get("PLAYWRIGHT_AG_EXTRA_ARGS", "").split()

args = [pkg, "--browser", browser] + extra_args
desired = {"command": "npx", "args": args}

data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        print(f"[warn] {path} no es JSON valido ({exc}); no se modifica.", file=sys.stderr)
        sys.exit(1)

servers = data.setdefault("mcpServers", {})

if servers.get("playwright") == desired:
    print(f"Sin cambios: {path}")
    sys.exit(0)

servers["playwright"] = desired

tmp_path = path + ".tmp"
with open(tmp_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp_path, path)

print(f"Actualizado: {path}")
PY
}

playwright_help() {
    cat <<'EOF'
Playwright MCP helpers

playwright_check
playwright_install
playwright_update
playwright_uninstall
playwright_run [url]

Niveles de comandos:
- playwright_install
    Instalacion GLOBAL: no hay binario persistente (corre via
    `npx @playwright/mcp@latest`), pero SI hay que descargar el binario del
    browser una vez (`install-browser`). Luego registra el servidor MCP UNA
    sola vez para cada cliente disponible:
      - Claude Code: `claude mcp add --scope user playwright -- npx ...`
        (requiere `claude` en PATH)
      - Codex:       `codex mcp add playwright -- npx ...`
        (requiere `codex` en PATH)
      - Antigravity: parcheo manual de ~/.gemini/antigravity/mcp_config.json
        (mismo archivo que Serena/Context7, entrada separada, forma LOCAL
        command+args porque el browser corre en esta maquina)
    Cada cliente se omite de forma independiente si su CLI no esta disponible.
- playwright_run [url]
    Playwright MCP NO indexa proyectos (no hay nada por-repo que preparar,
    a diferencia de Graphify/Serena). Este comando hace un smoke test real:
    levanta un browser headless real (aislado, sin dejar rastro en tu cwd) y
    navega a la URL dada (default https://example.com), confirmando que todo
    el pipeline (Node, browser instalado, MCP) funciona de punta a punta.

Environment:
- PLAYWRIGHT_MCP_PACKAGE: paquete/version (default: @playwright/mcp@latest)
- PLAYWRIGHT_MCP_BROWSER: chromium|chrome|firefox|webkit|msedge
    (default: chromium - el canal "chrome" real no esta instalado en WSL
    Debian por defecto; chromium si funciona out-of-the-box tras el install)
- PLAYWRIGHT_MCP_ARGS: flags extra separados por espacio, ej.
    "--isolated --viewport-size 1280x720" (ver `npx @playwright/mcp --help`
    para la lista completa: --headless, --device, --proxy-server, etc.)
- PLAYWRIGHT_ANTIGRAVITY_CONFIG: ruta del mcp_config.json de Antigravity

Typical flow:
1. playwright_check
2. playwright_install
3. playwright_run
EOF
}

playwright_check() {
    local missing=0 node_major browser cache_glob
    for cmd in node npm npx; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '[ok] %s\n' "$cmd"
        else
            printf '[fail] %s\n' "$cmd" >&2
            missing=1
        fi
    done

    if command -v node >/dev/null 2>&1; then
        node_major="$(_playwright_node_major)"
        if [ -n "$node_major" ] && [ "$node_major" -ge 20 ] 2>/dev/null; then
            printf '[ok] node >= 20 (%s)\n' "$(node --version)"
        else
            printf '[fail] node %s es muy viejo; Playwright exige Node >= 20 explicitamente. Si usas nvm: nvm install 20 && nvm alias default 20\n' "$(node --version 2>/dev/null)" >&2
            missing=1
        fi
    fi

    # El nombre real de la carpeta en cache (p.ej. "chromium-1237") no se
    # corresponde 1:1 con el nombre del canal pasado a `install-browser`
    # (p.ej. "chrome-for-testing" termina en una carpeta "chromium-<rev>") y
    # cambia de version entre releases del paquete - por eso este chequeo es
    # deliberadamente laxo (solo "hay algo de chromium cacheado", no "es
    # exactamente la version que este paquete necesita"). Verificado
    # probando: un glob exacto por nombre de canal daba falso negativo con un
    # browser ya instalado y funcionando.
    browser="$(_playwright_browser)"
    if [ "$browser" = "chromium" ]; then
        cache_glob="$HOME/.cache/ms-playwright/chromium-"*
        # shellcheck disable=SC2086
        if compgen -G "$cache_glob" >/dev/null 2>&1; then
            printf '[ok] hay un build de chromium cacheado en ~/.cache/ms-playwright (no garantiza que sea la version exacta que este paquete necesita)\n'
        else
            printf '[warn] no hay ningun build de chromium cacheado; playwright_install lo descarga (o corre "npx -y %s install-browser chrome-for-testing")\n' "$(_playwright_pkg)"
        fi
    else
        printf '[info] browser configurado: %s - la cache no se puede verificar de forma confiable para canales distintos de chromium; playwright_install lo intenta igual\n' "$browser"
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

playwright_install() {
    local pkg browser extra_args_str
    pkg="$(_playwright_pkg)"
    browser="$(_playwright_browser)"
    extra_args_str="${PLAYWRIGHT_MCP_ARGS:-}"

    echo "======================================"
    echo " Playwright MCP Installer"
    echo "======================================"

    if ! command -v npx >/dev/null 2>&1; then
        echo "npx no esta disponible (viene con Node.js/npm)."
        echo "Si usas nvm: nvm install 20"
        return 1
    fi

    if ! _playwright_node_ok; then
        echo "[warn] Node $(node --version 2>/dev/null) detectado (<20)." >&2
        echo "[warn] Playwright se niega a arrancar en Node < 20." >&2
        echo "[warn] Si usas nvm: nvm install 20 && nvm alias default 20, luego reintenta." >&2
        return 1
    fi

    echo ""
    if ! _playwright_install_browser; then
        echo "[warn] La descarga del browser fallo; playwright_run y el registro MCP pueden no funcionar hasta resolverlo." >&2
    fi

    echo ""
    if command -v claude >/dev/null 2>&1; then
        echo "Registrando Playwright como servidor MCP global para Claude Code..."
        if [ -n "$extra_args_str" ]; then
            # shellcheck disable=SC2086
            claude mcp add --scope user playwright -- npx "$pkg" --browser "$browser" $extra_args_str \
                || echo "[warn] 'claude mcp add playwright' fallo; revisa 'claude mcp list' manualmente." >&2
        else
            claude mcp add --scope user playwright -- npx "$pkg" --browser "$browser" \
                || echo "[warn] 'claude mcp add playwright' fallo; revisa 'claude mcp list' manualmente." >&2
        fi
    else
        echo "[warn] 'claude' CLI no encontrado; se omite el registro MCP con Claude Code." >&2
    fi

    echo ""
    if command -v codex >/dev/null 2>&1; then
        echo "Registrando Playwright como servidor MCP global para Codex..."
        if [ -n "$extra_args_str" ]; then
            # shellcheck disable=SC2086
            codex mcp add playwright -- npx "$pkg" --browser "$browser" $extra_args_str \
                || echo "[warn] 'codex mcp add playwright' fallo; revisa la config de Codex manualmente." >&2
        else
            codex mcp add playwright -- npx "$pkg" --browser "$browser" \
                || echo "[warn] 'codex mcp add playwright' fallo; revisa la config de Codex manualmente." >&2
        fi
    else
        echo "[warn] 'codex' CLI no encontrado; se omite el registro MCP con Codex." >&2
    fi

    echo ""
    echo "Configurando Antigravity (sin comando dedicado; parcheo manual del MCP config)..."
    _playwright_configure_antigravity || echo "[warn] No se pudo configurar Antigravity automaticamente." >&2

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "Esta instalacion es global (registro MCP en Claude Code, Codex y Antigravity)."
    echo "No hay ningun proyecto que preparar: Playwright MCP no indexa codigo."
    echo ""
    echo "Para probar que controla un browser real de verdad:"
    echo ""
    echo "    playwright_run"
    echo ""
}

playwright_update() {
    local pkg browser extra_args_str
    pkg="$(_playwright_pkg)"
    browser="$(_playwright_browser)"
    extra_args_str="${PLAYWRIGHT_MCP_ARGS:-}"

    if ! command -v npx >/dev/null 2>&1; then
        echo "npx no esta disponible."
        return 1
    fi

    # Igual que Context7: no hay binario persistente que actualizar (npx con
    # "@latest" siempre resuelve la ultima version publicada en cada corrida).
    # "update" reinstala el browser pineado por esa ultima version (puede
    # cambiar entre releases) y reaplica el registro MCP en los 3 clientes.
    echo "Playwright MCP se ejecuta via npx (sin instalacion persistente)."
    echo "Reinstalando el browser por si la version mas reciente pineo un build distinto..."
    _playwright_install_browser || echo "[warn] La descarga del browser fallo." >&2

    echo ""
    echo "Reaplicando registro MCP..."

    if command -v claude >/dev/null 2>&1; then
        if [ -n "$extra_args_str" ]; then
            # shellcheck disable=SC2086
            claude mcp add --scope user playwright -- npx "$pkg" --browser "$browser" $extra_args_str \
                || echo "[warn] 'claude mcp add playwright' fallo al reaplicar." >&2
        else
            claude mcp add --scope user playwright -- npx "$pkg" --browser "$browser" \
                || echo "[warn] 'claude mcp add playwright' fallo al reaplicar." >&2
        fi
    else
        echo "[warn] 'claude' CLI no encontrado; no se reaplico el registro de Claude Code." >&2
    fi

    if command -v codex >/dev/null 2>&1; then
        if [ -n "$extra_args_str" ]; then
            # shellcheck disable=SC2086
            codex mcp add playwright -- npx "$pkg" --browser "$browser" $extra_args_str \
                || echo "[warn] 'codex mcp add playwright' fallo al reaplicar." >&2
        else
            codex mcp add playwright -- npx "$pkg" --browser "$browser" \
                || echo "[warn] 'codex mcp add playwright' fallo al reaplicar." >&2
        fi
    else
        echo "[warn] 'codex' CLI no encontrado; no se reaplico el registro de Codex." >&2
    fi

    _playwright_configure_antigravity || echo "[warn] No se pudo reaplicar la config de Antigravity." >&2
}

playwright_uninstall() {
    echo "Playwright MCP no tiene instalacion persistente (corre via npx bajo demanda);"
    echo "no hay binario del paquete que desinstalar."
    echo ""
    echo "El registro MCP no se elimina automaticamente en ningun cliente."
    echo "Si quieres limpiarlo:"
    echo "  Claude Code:  claude mcp remove playwright"
    echo "  Codex:        revisa la config de Codex (mcp remove playwright si existe)"
    echo "  Antigravity:  quita el bloque \"playwright\" de mcpServers en ~/.gemini/antigravity/mcp_config.json"
    echo ""
    echo "Los binarios de browser en ~/.cache/ms-playwright/ tampoco se borran automaticamente."
    echo "Para liberar espacio: rm -rf ~/.cache/ms-playwright"
}

# Smoke test real: habla el protocolo MCP (JSON-RPC por stdio) directamente
# contra el servidor, sin pasar por ningun cliente. Levanta un browser
# headless aislado (--isolated, sin perfil persistente) y con --output-dir
# apuntando a un directorio temporal propio para no ensuciar el cwd del
# usuario con carpetas .playwright-mcp/ (encontrado probando este mismo
# comando: sin --output-dir explicito, escribe ahi donde se lo invoque).
playwright_run() {
    local url pkg browser rc out_dir
    url="${1:-https://example.com}"
    pkg="$(_playwright_pkg)"
    browser="$(_playwright_browser)"

    if ! command -v npx >/dev/null 2>&1; then
        echo "npx no esta disponible (instala Node.js/npm primero)."
        return 1
    fi

    if ! _playwright_node_ok; then
        echo "[warn] Node $(node --version 2>/dev/null) detectado (<20); Playwright se niega a arrancar en versiones viejas." >&2
    fi

    echo "Playwright MCP no indexa proyectos: no hay estado local que preparar."
    echo "Este comando levanta un browser headless real y navega a: $url"
    echo ""

    out_dir="$(mktemp -d)"

    PLAYWRIGHT_SMOKE_PKG="$pkg" \
    PLAYWRIGHT_SMOKE_BROWSER="$browser" \
    PLAYWRIGHT_SMOKE_URL="$url" \
    PLAYWRIGHT_SMOKE_ARGS="${PLAYWRIGHT_MCP_ARGS:-}" \
    PLAYWRIGHT_SMOKE_OUTDIR="$out_dir" \
    python3 <<'PY'
import json
import os
import subprocess
import sys
import time

pkg = os.environ["PLAYWRIGHT_SMOKE_PKG"]
browser = os.environ["PLAYWRIGHT_SMOKE_BROWSER"]
url = os.environ["PLAYWRIGHT_SMOKE_URL"]
out_dir = os.environ["PLAYWRIGHT_SMOKE_OUTDIR"]
extra = os.environ.get("PLAYWRIGHT_SMOKE_ARGS", "").split()

cmd = [
    "npx", "-y", pkg,
    "--headless", "--isolated",
    "--browser", browser,
    "--output-dir", out_dir,
] + extra

proc = subprocess.Popen(
    cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    text=True, bufsize=1,
)


def send(msg):
    proc.stdin.write(json.dumps(msg) + "\n")
    proc.stdin.flush()


send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
    "protocolVersion": "2024-11-05", "capabilities": {},
    "clientInfo": {"name": "playwright_run-smoke-test", "version": "1.0"}}})
send({"jsonrpc": "2.0", "method": "notifications/initialized"})
send({"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {
    "name": "browser_navigate", "arguments": {"url": url}}})

deadline = time.time() + 30
result = None
while time.time() < deadline:
    line = proc.stdout.readline()
    if not line:
        if proc.poll() is not None:
            break
        continue
    line = line.strip()
    if not line.startswith("{"):
        continue
    try:
        d = json.loads(line)
    except Exception:
        continue
    if d.get("id") == 2:
        result = d
        break

try:
    send({"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "browser_close", "arguments": {}}})
except Exception:
    pass
time.sleep(0.3)
proc.terminate()
try:
    proc.wait(timeout=5)
except Exception:
    proc.kill()

if result is None:
    print("[fail] No hubo respuesta del servidor MCP a tiempo.", file=sys.stderr)
    try:
        err = proc.stderr.read()
    except Exception:
        err = ""
    if err:
        print(err[-1500:], file=sys.stderr)
    sys.exit(1)

content = result.get("result", {}).get("content", [])
text = content[0]["text"] if content else json.dumps(result)

if result.get("result", {}).get("isError"):
    print(f"[fail] {text}", file=sys.stderr)
    sys.exit(1)

print("OK: navegacion real completada.")
print(text)
PY
    rc=$?

    rm -rf "$out_dir"

    return "$rc"
}
