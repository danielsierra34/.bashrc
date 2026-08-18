########################################################################################## GRAPHIFY

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
    local agents_file temp_file begin_marker end_marker
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

    {
        printf '\n'
        _graphify_agents_custom_block
    } >> "$temp_file"

    mv "$temp_file" "$agents_file"
}

_graphify_setup_project_codex() {
    local start_dir root_dir agents_file begin_marker
    start_dir="${1:-$PWD}"

    if [ -d "$start_dir" ]; then
        cd "$start_dir" || return 1
    elif [ -f "$start_dir" ]; then
        cd "$(dirname "$start_dir")" || return 1
    elif [ -n "$start_dir" ]; then
        cd "$start_dir" 2>/dev/null || return 1
    fi

    root_dir="$(_graphify_workspace_root)"
    agents_file="$root_dir/AGENTS.md"
    begin_marker="$(_graphify_agents_begin_marker)"

    if [ -f "$agents_file" ] && grep -Fq "$begin_marker" "$agents_file"; then
        return 0
    fi

    if ! command -v graphify >/dev/null 2>&1; then
        echo "Graphify no esta instalado en esta shell."
        return 1
    fi

    (
        cd "$root_dir" || exit 1
        graphify codex install
    ) || return 1

    (
        cd "$root_dir" || exit 1
        graphify claude install
    ) || return 1

    _graphify_upsert_agents_block "$agents_file"
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
graphify_scan_gitignore [ruta]
graphify_codex_note [mensaje]

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

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "Para analizar el proyecto actual:"
    echo ""
    echo "    graphify ."
    echo ""
    echo "Desde Codex puedes usar:"
    echo ""
    echo "    \$graphify ."
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
    local target graphify_bin prep_target
    target="${1:-.}"
    shift || true
    graphify_bin="$(_graphify_bin)"

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

    _graphify_setup_project_codex "$prep_target" || return 1
    "$graphify_bin" update "$target" "$@"
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
        if ! _graphify_setup_project_codex "$PWD"; then
            echo "Graphify no pudo completar la integracion local; el workspace ya quedo creado."
        fi
    else
        echo "Graphify no esta disponible; se creo el workspace pero no la integracion local con Codex."
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

graphify_scan_gitignore() {
    local root file entry changed=0
    root="${1:-$(_graphify_workspace_root)}"
    file="$root/.gitignore"

    if [ ! -e "$file" ]; then
        touch "$file" || return 1
    fi

    for entry in \
        '.graphify/' \
        'output/' \
        'reports/' \
        'graphify-output/' \
        'graphify-reports/'; do
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
