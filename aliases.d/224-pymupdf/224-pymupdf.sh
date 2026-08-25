########################################################################################## PYMUPDF

# PyMuPDF: libreria de Python para leer, renderizar y editar PDFs (extraer
# texto/imagenes, rasterizar paginas a PNG, generar PDFs desde cero). Igual
# que python-docx (223), NO es un servidor MCP - es una libreria que Claude
# Code/Codex/Antigravity usan escribiendo y corriendo scripts .py
# directamente. El paquete pip se llama "pymupdf" y el import moderno
# tambien es "import pymupdf" (el alias viejo "import fitz" sigue andando
# pero imprime un warning de deprecacion - verificado instalando de verdad).
#
# Mismo patron que python-docx: Debian bloquea `pip install --user` con
# PEP 668 ("externally-managed-environment"), asi que este modulo usa un
# venv propio (PYMUPDF_HOME, default ~/.pymupdf/venv) y exporta PYTHONPATH
# apuntando a su site-packages para que "import pymupdf" funcione en
# cualquier script python3 de esta shell sin activar el venv a mano.

_pymupdf_home() {
    printf '%s' "${PYMUPDF_HOME:-$HOME/.pymupdf}"
}

_pymupdf_pyver() {
    python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null
}

# Ruta PREDECIBLE (no consultada al venv), igual que en 223-python-docx: deja
# exportar PYTHONPATH al cargar este modulo incluso antes de que el venv
# exista (un PYTHONPATH que aun no existe es inofensivo). Asume que
# `python3 -m venv` en pymupdf_install usa el mismo python3 que esta en PATH
# ahora - si el python3 del sistema cambia de version, corre pymupdf_install
# de nuevo para regenerar el venv.
_pymupdf_site_packages() {
    local home pyver
    home="$(_pymupdf_home)"
    pyver="$(_pymupdf_pyver)"
    [ -n "$pyver" ] || return 1
    printf '%s' "$home/venv/lib/python$pyver/site-packages"
}

_PYMUPDF_SITE_PACKAGES_INIT="$(_pymupdf_site_packages 2>/dev/null)"
if [ -n "$_PYMUPDF_SITE_PACKAGES_INIT" ]; then
    export PYTHONPATH="$_PYMUPDF_SITE_PACKAGES_INIT${PYTHONPATH:+:$PYTHONPATH}"
fi
unset _PYMUPDF_SITE_PACKAGES_INIT

pymupdf_help() {
    cat <<'EOF'
PyMuPDF helpers

pymupdf_check
pymupdf_install
pymupdf_update
pymupdf_uninstall
pymupdf_run

Niveles de comandos:
- pymupdf_install
    Crea un venv propio (PYMUPDF_HOME, default ~/.pymupdf/venv, separado de
    cualquier proyecto) e instala pymupdf ahi con pip (pip install --user
    directo NO funciona en Debian: PEP 668 lo bloquea). NO registra nada en
    Codex/Claude/Antigravity - es una libreria: se usa escribiendo scripts
    .py que hacen "import pymupdf" (el alias viejo "import fitz" sigue
    andando pero esta deprecado - preferi "import pymupdf" en scripts nuevos).
- pymupdf_run
    No hay proyecto que preparar (como con python-docx/PptxGenJS). Genera un
    PDF real de prueba con texto, lo guarda, lo vuelve a abrir, extrae el
    texto (round-trip real, no solo generacion) y renderiza la pagina a PNG
    (rasterizado - la capacidad que distingue a PyMuPDF de python-docx/
    PptxGenJS). Valida ambos archivos resultantes y los borra.

Como usarla en scripts (una vez instalada, en cualquier script python3 de
esta shell, sin imports especiales):

    import pymupdf
    doc = pymupdf.open('entrada.pdf')      # o pymupdf.open() para uno nuevo
    page = doc[0]
    text = page.get_text()                 # extraer texto
    pix = page.get_pixmap(dpi=150)         # rasterizar a imagen
    pix.save('pagina.png')

Environment:
- PYMUPDF_HOME: directorio de instalacion (default: ~/.pymupdf)

Typical flow:
1. pymupdf_check
2. pymupdf_install
3. pymupdf_run
EOF
}

pymupdf_check() {
    local missing=0 home site_pkgs version
    home="$(_pymupdf_home)"
    site_pkgs="$(_pymupdf_site_packages)"

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
    import pymupdf
    print(pymupdf.__version__)
except Exception:
    raise SystemExit(1)' 2>/dev/null)"
        if [ -n "$version" ]; then
            printf '[ok] pymupdf %s instalado en %s\n' "$version" "$home/venv"
        else
            printf '[fail] pymupdf no encontrado en el venv; corre pymupdf_install\n' >&2
            missing=1
        fi
    else
        printf '[fail] no existe el venv en %s; corre pymupdf_install\n' "$home/venv" >&2
        missing=1
    fi

    # Distingue si "import pymupdf" funciona por el PYTHONPATH que exporta
    # este modulo, o si ya resuelve de forma independiente (instalado en
    # ~/.local/lib/.../site-packages por fuera de este modulo - le paso a
    # este equipo: habia un pymupdf preexistente ahi con fecha anterior a
    # este modulo, asi que reportar "resuelve via PYTHONPATH" sin mas hubiera
    # sido enganoso).
    if PYTHONPATH= python3 -c 'import pymupdf' >/dev/null 2>&1; then
        printf '[ok] "import pymupdf" ya resuelve en el python3 del sistema de forma independiente de este venv (%s)\n' "$(PYTHONPATH= python3 -c 'import pymupdf; print(pymupdf.__file__)' 2>/dev/null)"
    elif [ -n "$site_pkgs" ] && PYTHONPATH="$site_pkgs${PYTHONPATH:+:$PYTHONPATH}" python3 -c 'import pymupdf' >/dev/null 2>&1; then
        printf '[ok] "import pymupdf" resuelve via el PYTHONPATH que exporta este modulo (venv en %s)\n' "$home/venv"
    else
        printf '[warn] "import pymupdf" no resuelve en esta shell; abre una shell nueva o vuelve a hacer source del modulo\n'
    fi

    return "$missing"
}

pymupdf_install() {
    local home
    home="$(_pymupdf_home)"

    echo "======================================"
    echo " PyMuPDF Installer"
    echo "======================================"

    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 no esta instalado."
        return 1
    fi

    if [ ! -x "$home/venv/bin/python3" ]; then
        echo "Creando venv en $home/venv ..."
        python3 -m venv "$home/venv" || return 1
    fi

    echo "Instalando pymupdf en el venv..."
    "$home/venv/bin/pip" install --upgrade pip >/dev/null 2>&1
    "$home/venv/bin/pip" install pymupdf || return 1

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "pymupdf queda disponible via PYTHONPATH en cualquier script python3 de esta shell"
    echo "(abre una shell nueva, o vuelve a hacer source de este modulo, si PYTHONPATH no estaba"
    echo "exportado todavia):"
    echo ""
    echo "    python3 -c \"import pymupdf; print(pymupdf.__version__)\""
    echo ""
    echo "Para probar que genera, lee y renderiza un PDF real:"
    echo ""
    echo "    pymupdf_run"
    echo ""
}

pymupdf_update() {
    local home
    home="$(_pymupdf_home)"

    if [ ! -x "$home/venv/bin/pip" ]; then
        echo "pymupdf no esta instalado (no existe $home/venv). Corre pymupdf_install primero."
        return 1
    fi

    echo "Actualizando pymupdf en $home/venv ..."
    "$home/venv/bin/pip" install --upgrade pymupdf
}

pymupdf_uninstall() {
    local home
    home="$(_pymupdf_home)"

    if [ ! -d "$home" ]; then
        echo "No hay nada que desinstalar (no existe $home)."
        return 0
    fi

    rm -rf "$home"
    echo "Eliminado: $home"
    echo "PYTHONPATH sigue apuntando ahi hasta que abras una shell nueva."
}

# Smoke test real: genera un PDF de verdad, lo guarda, lo vuelve a abrir,
# extrae el texto (confirma el ciclo completo escritura+lectura, no solo
# generacion) y renderiza la pagina a PNG (confirma rasterizado, la
# capacidad que distingue a PyMuPDF de las librerias de solo-generar como
# python-docx/PptxGenJS). Corre con el python3 del venv directamente (no
# depende de que PYTHONPATH este bien exportado en la shell que llama) y
# borra todo despues, sin dejar rastro en el cwd del usuario.
pymupdf_run() {
    local home script_file rc=0

    home="$(_pymupdf_home)"

    if [ ! -x "$home/venv/bin/python3" ]; then
        echo "pymupdf no esta instalado. Ejecuta pymupdf_install primero."
        return 1
    fi

    echo "No hay proyecto que preparar (pymupdf no indexa nada, es una libreria)."
    echo "Generando un PDF real, reabriendolo, extrayendo texto y renderizando a PNG..."
    echo ""

    script_file="$(mktemp --suffix=.py)"
    cat > "$script_file" <<'PY'
import os
import shutil
import sys
import tempfile

import pymupdf

out_dir = tempfile.mkdtemp(prefix="pymupdf-smoke-")
pdf_file = os.path.join(out_dir, "smoke-test.pdf")
png_file = os.path.join(out_dir, "smoke-test.png")

marker = "PyMuPDF smoke test OK"

doc = pymupdf.open()
page = doc.new_page()
page.insert_text((72, 72), marker, fontsize=18)
doc.save(pdf_file)
doc.close()

pdf_size = os.path.getsize(pdf_file)
with open(pdf_file, "rb") as f:
    sig = f.read(5)
is_pdf = sig == b"%PDF-"

doc2 = pymupdf.open(pdf_file)
page2 = doc2[0]
extracted = page2.get_text().strip()
pix = page2.get_pixmap(dpi=72)
pix.save(png_file)
doc2.close()

png_size = os.path.getsize(png_file)

print(f"PDF generado: {pdf_file} ({pdf_size} bytes)")
print(f"Texto extraido: {extracted!r}")
print(f"PNG renderizado: {png_file} ({png_size} bytes, {pix.width}x{pix.height})")

shutil.rmtree(out_dir, ignore_errors=True)

ok = is_pdf and pdf_size > 200 and marker in extracted and png_size > 200
if not ok:
    print("[fail] alguna verificacion fallo (firma PDF, tamano, texto extraido o PNG).", file=sys.stderr)
    sys.exit(1)

print("OK: PyMuPDF genero, releyo y renderizo un PDF real correctamente.")
PY

    "$home/venv/bin/python3" "$script_file"
    rc=$?
    rm -f "$script_file"

    return "$rc"
}
