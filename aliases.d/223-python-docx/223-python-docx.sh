########################################################################################## PYTHON-DOCX

# python-docx: libreria de Python para generar/editar archivos .docx (Word)
# programaticamente. Igual que PptxGenJS (221), NO es un servidor MCP - es
# una libreria que Claude Code/Codex/Antigravity usan escribiendo y corriendo
# scripts .py directamente (import docx). El paquete pip se llama
# "python-docx" pero el modulo que se importa es "docx".
#
# A diferencia de PptxGenJS (donde `npm install --user`-equivalente via
# NODE_PATH basta), Debian bloquea `pip install --user` con PEP 668
# ("externally-managed-environment", verificado: falla con ese error exacto).
# Por eso este modulo usa un venv propio (PYTHON_DOCX_HOME, default
# ~/.python-docx/venv) y exporta PYTHONPATH apuntando a su site-packages -
# mismo truco conceptual que NODE_PATH para pptxgenjs: Python ya usa
# PYTHONPATH como ruta de resolucion adicional, asi que import docx funciona
# en cualquier script python3 de esta shell sin instalar nada por proyecto ni
# activar el venv a mano.

_pythondocx_home() {
    printf '%s' "${PYTHON_DOCX_HOME:-$HOME/.python-docx}"
}

_pythondocx_pyver() {
    python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null
}

# Ruta PREDECIBLE (no consultada al venv) para poder exportar PYTHONPATH al
# cargar este modulo incluso antes de que el venv exista (igual que NODE_PATH
# en pptxgenjs: un PYTHONPATH que aun no existe es inofensivo, Python lo
# ignora en la busqueda). Asume que `python3 -m venv` en pythondocx_install
# usa el mismo python3 que esta en PATH ahora mismo - si el python3 del
# sistema cambia de version despues de instalar, hay que correr
# pythondocx_install de nuevo para regenerar el venv con la version nueva.
_pythondocx_site_packages() {
    local home pyver
    home="$(_pythondocx_home)"
    pyver="$(_pythondocx_pyver)"
    [ -n "$pyver" ] || return 1
    printf '%s' "$home/venv/lib/python$pyver/site-packages"
}

_PYTHONDOCX_SITE_PACKAGES_INIT="$(_pythondocx_site_packages 2>/dev/null)"
if [ -n "$_PYTHONDOCX_SITE_PACKAGES_INIT" ]; then
    export PYTHONPATH="$_PYTHONDOCX_SITE_PACKAGES_INIT${PYTHONPATH:+:$PYTHONPATH}"
fi
unset _PYTHONDOCX_SITE_PACKAGES_INIT

pythondocx_help() {
    cat <<'EOF'
python-docx helpers

pythondocx_check
pythondocx_install
pythondocx_update
pythondocx_uninstall
pythondocx_run

Niveles de comandos:
- pythondocx_install
    Crea un venv propio (PYTHON_DOCX_HOME, default ~/.python-docx/venv,
    separado de cualquier proyecto) e instala python-docx ahi con pip
    (pip install --user directo NO funciona en Debian: PEP 668 lo bloquea
    con "externally-managed-environment"). NO registra nada en Codex/Claude/
    Antigravity - no es un servidor MCP, es una libreria: se usa escribiendo
    scripts .py que hacen "import docx" (el nombre del paquete pip es
    "python-docx", pero el modulo importado es "docx").
- pythondocx_run
    No hay proyecto que preparar (como con PptxGenJS/Context7/Playwright).
    Genera un .docx real de prueba (titulo + parrafo + tabla) en un
    directorio temporal, valida que el archivo resultante sea un ZIP/OOXML
    valido de tamano razonable, y lo borra.

Como usarla en scripts (una vez instalada, en cualquier script python3 de
esta shell, sin imports especiales):

    from docx import Document
    doc = Document()
    doc.add_heading('Hola', level=1)
    doc.add_paragraph('Texto de ejemplo.')
    doc.save('salida.docx')

Environment:
- PYTHON_DOCX_HOME: directorio de instalacion (default: ~/.python-docx)

Typical flow:
1. pythondocx_check
2. pythondocx_install
3. pythondocx_run
EOF
}

pythondocx_check() {
    local missing=0 home site_pkgs version
    home="$(_pythondocx_home)"
    site_pkgs="$(_pythondocx_site_packages)"

    for cmd in python3 pip3; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '[ok] %s\n' "$cmd"
        else
            printf '[fail] %s\n' "$cmd" >&2
            missing=1
        fi
    done

    if [ -x "$home/venv/bin/python3" ]; then
        version="$("$home/venv/bin/python3" -c 'try:
    import docx
    print(docx.__version__)
except Exception:
    raise SystemExit(1)' 2>/dev/null)"
        if [ -n "$version" ]; then
            printf '[ok] python-docx %s instalado en %s\n' "$version" "$home/venv"
        else
            printf '[fail] python-docx no encontrado en el venv; corre pythondocx_install\n' >&2
            missing=1
        fi
    else
        printf '[fail] no existe el venv en %s; corre pythondocx_install\n' "$home/venv" >&2
        missing=1
    fi

    if [ -n "$site_pkgs" ] && PYTHONPATH="$site_pkgs${PYTHONPATH:+:$PYTHONPATH}" python3 -c 'import docx' >/dev/null 2>&1; then
        printf '[ok] "import docx" resuelve via PYTHONPATH en el python3 del sistema\n'
    else
        printf '[warn] "import docx" no resuelve via PYTHONPATH en esta shell; abre una shell nueva o vuelve a hacer source del modulo\n'
    fi

    return "$missing"
}

pythondocx_install() {
    local home
    home="$(_pythondocx_home)"

    echo "======================================"
    echo " python-docx Installer"
    echo "======================================"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 no esta instalado."
        return 1
    fi

    if [ ! -x "$home/venv/bin/python3" ]; then
        echo "Creando venv en $home/venv ..."
        python3 -m venv "$home/venv" || return 1
    fi

    echo "Instalando python-docx en el venv..."
    "$home/venv/bin/pip" install --upgrade pip >/dev/null 2>&1
    "$home/venv/bin/pip" install python-docx || return 1

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "python-docx queda disponible via PYTHONPATH en cualquier script python3 de esta shell"
    echo "(abre una shell nueva, o vuelve a hacer source de este modulo, si PYTHONPATH no estaba"
    echo "exportado todavia):"
    echo ""
    echo "    python3 -c \"import docx; print(docx.__version__)\""
    echo ""
    echo "Para probar que genera un .docx real:"
    echo ""
    echo "    pythondocx_run"
    echo ""
}

pythondocx_update() {
    local home
    home="$(_pythondocx_home)"

    if [ ! -x "$home/venv/bin/pip" ]; then
        echo "python-docx no esta instalado (no existe $home/venv). Corre pythondocx_install primero."
        return 1
    fi

    echo "Actualizando python-docx en $home/venv ..."
    "$home/venv/bin/pip" install --upgrade python-docx
}

pythondocx_uninstall() {
    local home
    home="$(_pythondocx_home)"

    if [ ! -d "$home" ]; then
        echo "No hay nada que desinstalar (no existe $home)."
        return 0
    fi

    rm -rf "$home"
    echo "Eliminado: $home"
    echo "PYTHONPATH sigue apuntando ahi hasta que abras una shell nueva."
}

# Smoke test real: genera un .docx de verdad (titulo + parrafo + tabla) en un
# directorio temporal propio, valida que sea un ZIP/OOXML valido (firma PK +
# tamano minimo razonable), y lo borra. Corre con el python3 del venv
# directamente (no depende de que PYTHONPATH este bien exportado en la shell
# que llama) para que el smoke test valide la instalacion en si, no la
# integracion con la shell actual - eso ya lo cubre pythondocx_check.
pythondocx_run() {
    local home script_file rc=0

    home="$(_pythondocx_home)"

    if [ ! -x "$home/venv/bin/python3" ]; then
        echo "python-docx no esta instalado. Ejecuta pythondocx_install primero."
        return 1
    fi

    echo "No hay proyecto que preparar (python-docx no indexa nada, es una libreria)."
    echo "Generando un .docx real de prueba (titulo + parrafo + tabla) en un directorio temporal..."
    echo ""

    script_file="$(mktemp --suffix=.py)"
    cat > "$script_file" <<'PY'
import os
import shutil
import sys
import tempfile

from docx import Document

out_dir = tempfile.mkdtemp(prefix="python-docx-smoke-")
out_file = os.path.join(out_dir, "smoke-test.docx")

doc = Document()
doc.add_heading("python-docx smoke test OK", level=1)
doc.add_paragraph("Generado por pythondocx_run.")

table = doc.add_table(rows=2, cols=2)
table.cell(0, 0).text = "A"
table.cell(0, 1).text = "B"
table.cell(1, 0).text = "1"
table.cell(1, 1).text = "2"

doc.save(out_file)

size = os.path.getsize(out_file)
with open(out_file, "rb") as f:
    sig = f.read(2)
is_zip = sig == b"PK"

print(f"Archivo generado: {out_file} ({size} bytes)")

shutil.rmtree(out_dir, ignore_errors=True)

if not is_zip or size < 1000:
    print("[fail] el archivo no parece un .docx valido (firma ZIP o tamano incorrectos).", file=sys.stderr)
    sys.exit(1)

print("OK: python-docx genero un .docx real y valido.")
PY

    "$home/venv/bin/python3" "$script_file"
    rc=$?
    rm -f "$script_file"

    return "$rc"
}
