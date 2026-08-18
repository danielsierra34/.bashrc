########################################################################################## GRAPHIFY

_graphify_bin() {
    printf '%s' "${GRAPHIFY_BIN:-graphify}"
}

_graphify_pkg() {
    printf '%s' "${GRAPHIFY_UV_PACKAGE:-graphify}"
}

_graphify_workspace_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        pwd
    fi
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
- GRAPHIFY_UV_PACKAGE: package name for `uv tool install` and `uv tool upgrade`
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
    echo "Configurando integracion con Codex..."
    if command -v codex >/dev/null 2>&1; then
        "$graphify_bin" install --platform codex
    else
        echo "Codex no esta disponible; omitiendo paso de integracion."
    fi

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

    if command -v codex >/dev/null 2>&1; then
        "$graphify_bin" install --platform codex
    fi

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
    local target graphify_bin
    target="${1:-.}"
    shift || true
    graphify_bin="$(_graphify_bin)"

    if ! command -v "$graphify_bin" >/dev/null 2>&1; then
        echo "Graphify no esta instalado. Ejecuta graphify_install primero."
        return 1
    fi

    if [ -d "$target" ]; then
        (cd "$target" && "$graphify_bin" . "$@")
        return $?
    fi

    if [ "$target" = "." ]; then
        "$graphify_bin" . "$@"
        return $?
    fi

    if [ -e "$target" ]; then
        "$graphify_bin" "$target" "$@"
        return $?
    fi

    echo "No existe: $target"
    return 1
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
