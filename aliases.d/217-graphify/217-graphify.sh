########################################################################################## GRAPHIFY

# Captured at source time (not inside a function) so it resolves correctly
# regardless of where this repo was cloned -- graphify-patch/reapply.sh below
# must be found by clone location, not a hardcoded ~/bashrc path.
_GRAPHIFY_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

_graphify_bin() {
    printf '%s' "${GRAPHIFY_BIN:-graphify}"
}

_graphify_pkg() {
    printf '%s' "${GRAPHIFY_UV_PACKAGE:-graphifyy}"
}

_graphify_workspace_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        pwd
    fi
}

_graphify_platforms() {
    printf '%s\n' codex claude
}

# Reapplies the local, un-upstreamed generic-textual-fallback patch
# (graphify-patch/, see its README.md) onto whatever Graphify install is
# currently active. Every `uv tool install`/`uv tool upgrade` writes a clean
# venv, which silently wipes that patch -- so both graphify_install and
# graphify_update call this right after touching the binary. A missing
# graphify-patch/ (an older clone, or the patch deliberately removed) is not
# an error: this module must keep working without it.
_graphify_reapply_local_patch() {
    local reapply_script
    reapply_script="$_GRAPHIFY_MODULE_DIR/graphify-patch/reapply.sh"

    if [ ! -f "$reapply_script" ]; then
        return 0
    fi

    echo ""
    echo "Reaplicando el parche local de Graphify (fallback textual generico)..."
    if ! bash "$reapply_script"; then
        echo "[warn] No se pudo reaplicar $reapply_script; revisa graphify-patch/README.md" >&2
        return 1
    fi
}

_graphify_install_platforms() {
    local platform graphify_bin
    graphify_bin="$(_graphify_bin)"

    for platform in "$@"; do
        "$graphify_bin" install --platform "$platform"
    done
}

_graphify_agents_begin_marker() {
    printf '%s' '<!-- BEGIN GRAPHIFY-CODEX CUSTOM -->'
}

_graphify_agents_end_marker() {
    printf '%s' '<!-- END GRAPHIFY-CODEX CUSTOM -->'
}

_graphify_agents_custom_block() {
    cat <<'EOF'
<!-- BEGIN GRAPHIFY-CODEX CUSTOM -->

## Graphify + Codex

- WSL Debian is the execution environment for project tools.
- If Codex is running from Windows or PowerShell, switch into WSL Debian before invoking Graphify.
- Graphify is installed inside WSL Debian and should not be treated as a connector, plugin, or external integration.
- Apply the same project integration flow for Codex and Claude when Graphify is available.
- For codebase questions, consult Graphify first whenever `graphify-out/graph.json` exists.
- Do not require the user to type `/graphify` or mention Graphify explicitly.
- Prefer `graphify query "<question>"` first.
- Use `graphify explain "<concept>"` for specific concepts.
- Use `graphify path "<A>" "<B>"` for relationships.
- If a query returns `No matching nodes found`, retry with more specific real file, class, function, or component names before abandoning Graphify.
- Use `graphify-out/GRAPH_REPORT.md` for broad architectural analysis.
- Use `graphify-out/wiki/index.md` if it exists for general navigation.
- After modifying code, run `graphify update .`.
- Graphify is the first pass for locating relevant codebase areas; Codex can then inspect the source files Graphify identified.

<!-- END GRAPHIFY-CODEX CUSTOM -->
EOF
}

_graphify_upsert_agents_block() {
    local agents_file temp_file begin_marker end_marker content
    agents_file="$1"
    begin_marker="$(_graphify_agents_begin_marker)"
    end_marker="$(_graphify_agents_end_marker)"
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

    # `$(...)` recorta los saltos de linea finales, asi que esto normaliza
    # cuantas lineas en blanco quedaron colgando tras quitar el bloque
    # anterior. Sin esto, cada ejecucion de graphify_run agregaba una linea
    # en blanco nueva antes del bloque (crecimiento no acotado del archivo).
    content="$(cat "$temp_file")"
    : > "$temp_file"
    if [ -n "$content" ]; then
        printf '%s\n\n' "$content" >> "$temp_file"
    fi
    _graphify_agents_custom_block >> "$temp_file"

    mv "$temp_file" "$agents_file"
}

_graphify_setup_project() {
    local start_dir root_dir agents_file rc
    start_dir="${1:-$PWD}"
    rc=0

    if [ -d "$start_dir" ]; then
        cd "$start_dir" || return 1
    elif [ -f "$start_dir" ]; then
        cd "$(dirname "$start_dir")" || return 1
    elif [ -n "$start_dir" ]; then
        cd "$start_dir" 2>/dev/null || return 1
    fi

    # El workspace de Graphify es "$start_dir" (ya resuelto por el cd de arriba),
    # NUNCA la raiz de Git: usar _graphify_workspace_root aqui hacia que
    # AGENTS.md/CLAUDE.md/.codex/.claude terminaran en un repositorio superior
    # en vez del proyecto pedido cuando start_dir era una subcarpeta de un repo
    # git existente (bug: graphify_run . escribia fuera del target).
    root_dir="$(pwd -P)"
    agents_file="$root_dir/AGENTS.md"

    if ! command -v graphify >/dev/null 2>&1; then
        echo "Graphify no esta instalado en esta shell."
        return 1
    fi

    # `graphify codex install` / `graphify claude install` son idempotentes por si
    # mismos (no reescriben si ya estan configurados), asi que se dejan correr
    # siempre y se delega en ellos la gestion de sus propios archivos.
    if ! ( cd "$root_dir" && graphify codex install ); then
        echo "[warn] 'graphify codex install' fallo en $root_dir; se continua con la integracion de Claude." >&2
        rc=1
    fi

    if ! ( cd "$root_dir" && graphify claude install ); then
        echo "[warn] 'graphify claude install' fallo en $root_dir." >&2
        rc=1
    fi

    _graphify_upsert_agents_block "$agents_file"

    return "$rc"
}

graphify_help() {
    cat <<'EOF'
Graphify helpers

graphify_check
graphify_install
graphify_update
graphify_uninstall
graphify_run [ruta|.]
graphify_batch <ruta> [ruta ...]
graphify_workspace <ruta> [nombre]
graphify_report_open [ruta]
graphify_graph_open [ruta]
graphify_scan_gitignore [ruta]
graphify_codex_note [mensaje]

Niveles de comandos:
- graphify_install
    Instalacion GLOBAL en esta shell de WSL Debian: Python/uv/Graphify y la
    skill global de Codex y Claude. No toca ningun proyecto especifico.
- graphify_run .
    Preparacion LOCAL de un proyecto: agrega graphify-out/ a .gitignore,
    ejecuta `graphify codex install` y `graphify claude install` (AGENTS.md,
    .codex/hooks.json, CLAUDE.md, .claude/settings.json) y termina con
    `graphify update .`. Es el comando normal dentro de cualquier repo.
- graphify update .
    Solo actualiza el grafo AST/local (graphify-out/) sin usar ninguna API de
    LLM. Es lo que usa `graphify_run` por defecto.
- graphify .
    Extraccion completa (AST + semantica). Puede requerir una API key
    (Gemini/OpenAI/Anthropic/etc.) si el proyecto tiene documentacion,
    PDFs o imagenes. Uso manual, no lo dispara `graphify_run`.

Consultas sobre el grafo (una vez que graphify-out/graph.json existe):
- graphify query "<pregunta>"
- graphify explain "<concepto>"
- graphify path "<A>" "<B>"

Ver el grafo visualmente:
- graphify_graph_open .   abre graphify-out/graph.html en el navegador
                          (usa wslview/explorer.exe/xdg-open/$BROWSER, en ese orden)
- graphify_report_open .  abre el ultimo reporte de texto en $EDITOR/less

Environment:
- GRAPHIFY_UV_PACKAGE: package name for `uv tool install` and `uv tool upgrade` (default: graphifyy)
- GRAPHIFY_BIN: binary name expected in PATH after install

Typical flow:
1. graphify_check
2. graphify_install
3. graphify_run .
4. graphify_codex_note "Analisis inicial"
EOF
}

graphify_check() {
    local missing=0 graphify_bin graphify_pkg
    graphify_bin="$(_graphify_bin)"
    graphify_pkg="$(_graphify_pkg)"

    for cmd in python3 curl uv; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '[ok] %s\n' "$cmd"
        else
            printf '[fail] %s\n' "$cmd" >&2
            missing=1
        fi
    done

    if command -v "$graphify_bin" >/dev/null 2>&1; then
        printf '[ok] %s\n' "$graphify_bin"
    else
        printf '[fail] %s (package: %s)\n' "$graphify_bin" "$graphify_pkg" >&2
        missing=1
    fi

    if command -v codex >/dev/null 2>&1; then
        printf '[ok] codex\n'
    else
        printf '[warn] codex not found; integration step will be skipped or fail later\n'
    fi

    return "$missing"
}

graphify_install() {
    set -e

    local uv_pkg graphify_bin
    uv_pkg="$(_graphify_pkg)"
    graphify_bin="$(_graphify_bin)"

    echo "======================================"
    echo " Graphify + Codex Installer"
    echo "======================================"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "Python3 no esta instalado."
        echo "Instalando Python3..."
        sudo apt update
        sudo apt install -y python3 python3-pip curl
    fi

    echo "Python:"
    python3 --version

    if ! command -v curl >/dev/null 2>&1; then
        echo "Instalando curl..."
        sudo apt update
        sudo apt install -y curl
    fi

    if ! command -v uv >/dev/null 2>&1; then
        echo "Instalando uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        echo "uv ya esta instalado."
    fi

    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

    if ! command -v uv >/dev/null 2>&1; then
        echo "No se pudo encontrar uv en PATH despues de la instalacion."
        return 1
    fi

    echo "uv:"
    uv --version

    if ! command -v "$graphify_bin" >/dev/null 2>&1; then
        echo "Instalando Graphify..."
        uv tool install "$uv_pkg"
    else
        echo "Graphify ya esta instalado."
    fi

    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v "$graphify_bin" >/dev/null 2>&1; then
        echo "No se pudo encontrar '$graphify_bin' en PATH despues de la instalacion."
        echo "Revisa si el paquete publicado en uv tool install es '$uv_pkg'."
        return 1
    fi

    echo "Graphify:"
    "$graphify_bin" --version 2>/dev/null || "$graphify_bin" --help | head -n 1

    echo ""
    echo "Configurando integracion con Codex y Claude..."
    _graphify_install_platforms codex claude

    _graphify_reapply_local_patch

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "Esta instalacion es global (Graphify + skills de Codex y Claude)."
    echo "No prepara ningun proyecto todavia."
    echo ""
    echo "Para preparar un proyecto (Codex + Claude + grafo local, sin API):"
    echo ""
    echo "    cd /ruta/del/proyecto"
    echo "    graphify_run ."
    echo ""
    echo "Si mas adelante quieres extraccion semantica completa (requiere API key):"
    echo ""
    echo "    graphify ."
    echo ""
}

graphify_update() {
    local graphify_bin graphify_pkg
    graphify_bin="$(_graphify_bin)"
    graphify_pkg="$(_graphify_pkg)"

    if ! command -v uv >/dev/null 2>&1; then
        echo "uv no esta instalado."
        return 1
    fi

    echo "Actualizando Graphify via uv..."
    uv tool upgrade "$graphify_pkg"
    hash -r

    if ! command -v "$graphify_bin" >/dev/null 2>&1; then
        echo "No se encontro '$graphify_bin' despues de actualizar."
        return 1
    fi

    _graphify_install_platforms codex claude

    _graphify_reapply_local_patch

    "$graphify_bin" --version 2>/dev/null || "$graphify_bin" --help | head -n 1
}

graphify_uninstall() {
    local graphify_pkg graphify_bin
    graphify_pkg="$(_graphify_pkg)"
    graphify_bin="$(_graphify_bin)"

    if command -v uv >/dev/null 2>&1; then
        uv tool uninstall "$graphify_pkg"
    fi

    if command -v "$graphify_bin" >/dev/null 2>&1; then
        echo "El binario '$graphify_bin' sigue accesible en PATH."
        echo "Si queda un wrapper manual, revisa ~/.local/bin."
    fi

    echo "La integracion con Codex no suele tener un uninstall automatico."
    echo "Si necesitas limpiar restos, revisa la salida de graphify --help."
}

graphify_run() {
    local target graphify_bin prep_target rc
    target="${1:-.}"
    shift || true
    graphify_bin="$(_graphify_bin)"
    rc=0

    if ! command -v "$graphify_bin" >/dev/null 2>&1; then
        echo "Graphify no esta instalado. Ejecuta graphify_install primero."
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

    # El workspace de Graphify es SIEMPRE el target pedido, resuelto a ruta
    # absoluta/canonica - nunca la raiz de Git. git rev-parse --show-toplevel
    # (via _graphify_workspace_root) puede apuntar a un repositorio superior
    # cuando prep_target es una subcarpeta de un repo existente, y usarlo aqui
    # era el bug: AGENTS.md/CLAUDE.md/.codex/.claude/.gitignore terminaban
    # fuera del target indicado por el usuario.
    prep_target="$(cd "$prep_target" 2>/dev/null && pwd -P)"
    if [ -z "$prep_target" ]; then
        echo "No pude resolver la ruta: $target"
        return 1
    fi

    # cada paso avisa si falla pero no bloquea los siguientes: el .gitignore,
    # la integracion de Codex/Claude y la actualizacion del grafo son
    # independientes entre si.
    graphify_scan_gitignore "$prep_target" || rc=1
    _graphify_setup_project "$prep_target" || rc=1

    ( cd "$prep_target" && "$graphify_bin" update . "$@" ) || rc=1

    return "$rc"
}

graphify_batch() {
    local path rc=0

    if [ "$#" -eq 0 ]; then
        set -- .
    fi

    for path in "$@"; do
        echo "==> $path"
        graphify_run "$path" || rc=1
    done

    return "$rc"
}

graphify_workspace() {
    local target_dir workspace_name
    target_dir="${1:-}"
    workspace_name="${2:-}"

    if [ -z "$target_dir" ]; then
        echo "Uso: graphify_workspace <ruta> [nombre]"
        return 1
    fi

    if [ -e "$target_dir" ] && [ ! -d "$target_dir" ]; then
        echo "La ruta existe y no es un directorio: $target_dir"
        return 1
    fi

    mkdir -p "$target_dir" || return 1
    cd "$target_dir" || return 1

    workspace_name="${workspace_name:-$(basename "$PWD")}"

    mkdir -p input output reports notes .graphify

    cat > README.md <<EOF
# ${workspace_name}

Workspace para analizar proyectos con Graphify.

## Estructura

- input/: material de entrada
- output/: salidas de Graphify
- reports/: reportes generados
- notes/: notas del analisis
- .graphify/: configuracion local
EOF

    cat > .gitignore <<'EOF'
output/
reports/
.graphify/
EOF

    if command -v graphify >/dev/null 2>&1; then
        if ! _graphify_setup_project "$PWD"; then
            echo "Graphify no pudo completar toda la integracion local; el workspace ya quedo creado."
        fi
    else
        echo "Graphify no esta disponible; se creo el workspace pero no la integracion local con Codex/Claude."
    fi

    printf '%s\n' "$PWD"
}

_graphify_report_path() {
    local root report
    root="${1:-$(_graphify_workspace_root)}"

    if [ -d "$root/reports" ]; then
        report="$(find "$root/reports" -maxdepth 1 -type f 2>/dev/null | sort | tail -n 1)"
    fi

    if [ -z "${report:-}" ] && [ -d "$root/output" ]; then
        report="$(find "$root/output" -maxdepth 1 -type f 2>/dev/null | sort | tail -n 1)"
    fi

    if [ -z "${report:-}" ]; then
        report="$(find "$root" -maxdepth 1 -type f \( -name '*.md' -o -name '*.txt' -o -name '*.json' -o -name '*.html' \) 2>/dev/null | sort | tail -n 1)"
    fi

    if [ -n "${report:-}" ] && [ -e "$report" ]; then
        printf '%s\n' "$report"
        return 0
    fi

    return 1
}

graphify_report_open() {
    local root report
    root="${1:-$(_graphify_workspace_root)}"
    report="$(_graphify_report_path "$root")"

    if [ -z "${report:-}" ] || [ ! -e "$report" ]; then
        echo "No encontre reportes para abrir en $root"
        return 1
    fi

    if [ -n "${EDITOR:-}" ] && command -v "$EDITOR" >/dev/null 2>&1; then
        "$EDITOR" "$report"
    elif command -v less >/dev/null 2>&1; then
        less "$report"
    else
        cat "$report"
    fi
}

# Intenta abrir una ruta/URL con el navegador por defecto. Prueba, en orden,
# las herramientas tipicas de WSL (wslview del paquete wslu), el puente
# nativo hacia el shell de Windows (explorer.exe, via wslpath) y por ultimo
# las alternativas de Linux (xdg-open, $BROWSER) para el caso de correr
# fuera de WSL o con WSLg configurado.
_graphify_open_url() {
    local target winpath
    target="$1"

    if command -v wslview >/dev/null 2>&1; then
        wslview "$target" >/dev/null 2>&1 && return 0
    fi

    if command -v explorer.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
        winpath="$(wslpath -w "$target" 2>/dev/null)"
        if [ -n "$winpath" ]; then
            explorer.exe "$winpath" >/dev/null 2>&1
            return 0
        fi
    fi

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$target" >/dev/null 2>&1 && return 0
    fi

    if [ -n "${BROWSER:-}" ] && command -v "$BROWSER" >/dev/null 2>&1; then
        "$BROWSER" "$target" >/dev/null 2>&1 && return 0
    fi

    return 1
}

graphify_graph_open() {
    local root html
    root="${1:-$(_graphify_workspace_root)}"
    html="$root/graphify-out/graph.html"

    if [ ! -e "$html" ]; then
        echo "No encontre $html."
        echo "Ejecuta 'graphify_run .' o 'graphify update .' primero para generarlo."
        return 1
    fi

    if _graphify_open_url "$html"; then
        echo "Abriendo en el navegador: $html"
    else
        echo "No pude abrir un navegador automaticamente."
        echo "Abrilo manualmente: $html"
        return 1
    fi
}

graphify_scan_gitignore() {
    local root file entry changed=0 tracked
    root="${1:-$(_graphify_workspace_root)}"
    file="$root/.gitignore"

    if [ ! -e "$file" ]; then
        touch "$file" || return 1
    fi

    # graphify-out/ es la carpeta real que usa Graphify (graph.json, graph.html,
    # GRAPH_REPORT.md, cache, manifest, analysis, labels, snapshots). Es local
    # y regenerable, por eso se ignora siempre. Las demas entradas se conservan
    # por compatibilidad con configuraciones previas.
    for entry in \
        '.graphify/' \
        'output/' \
        'reports/' \
        'graphify-output/' \
        'graphify-reports/' \
        'graphify-out/'; do
        if ! grep -Fxq "$entry" "$file"; then
            printf '%s\n' "$entry" >> "$file"
            changed=1
        fi
    done

    if [ "$changed" -eq 1 ]; then
        echo "Actualizado: $file"
    else
        echo "Sin cambios: $file"
    fi

    # .gitignore no afecta archivos que Git ya rastreaba antes de ignorarlos.
    if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        tracked="$(git -C "$root" ls-files -- 'graphify-out' 2>/dev/null)"
        if [ -n "$tracked" ]; then
            echo "[warn] Hay archivos de graphify-out/ ya versionados en Git (el .gitignore no los deja de rastrear)." >&2
            echo "[warn] Revisa manualmente si quieres dejar de versionarlos: git rm -r --cached graphify-out/" >&2
        fi
    fi
}

graphify_codex_note() {
    local message root note_dir note_file stamp report
    message="${1:-Analisis Graphify}"
    root="$(_graphify_workspace_root)"
    stamp="$(date +%F_%H%M%S)"
    note_dir="$root/.codex/notes"
    note_file="$note_dir/${stamp}-graphify.md"

    mkdir -p "$note_dir" || return 1

    report="$(_graphify_report_path "$root" 2>/dev/null || true)"

    {
        printf '# %s\n\n' "$message"
        printf -- '- Date: %s\n' "$(date -Iseconds)"
        printf -- '- Repo: %s\n' "$root"
        printf '\n## Summary\n\n'
        printf -- '- Graphify analysis executed or prepared.\n'
        if [ -n "$report" ]; then
            printf -- '- Report: %s\n' "$report"
        fi
        printf '\n## Notes\n\n'
        printf -- '- Ajusta este resumen segun la salida real de Graphify.\n'
    } > "$note_file"

    printf '%s\n' "$note_file"
}
