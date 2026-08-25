########################################################################################## PPTXGENJS

# PptxGenJS: libreria de Node para generar archivos .pptx (PowerPoint)
# programaticamente. A diferencia de Serena/Context7/Playwright (218-220), NO
# es un servidor MCP - no hay "claude mcp add" ni registro en Codex/Claude/
# Antigravity, porque no es algo a lo que un cliente MCP "se conecte": es una
# libreria que Claude Code/Codex usan escribiendo y corriendo scripts .js
# directamente (require('pptxgenjs') / import PptxGenJS from 'pptxgenjs').
#
# La instalacion vive en un directorio propio (PPTXGENJS_HOME, default
# ~/.pptxgenjs) con su propio package.json/node_modules, y este modulo
# exporta NODE_PATH apuntando ahi al cargarse - asi CUALQUIER script node que
# corras en esta shell puede hacer require('pptxgenjs') sin instalar nada por
# proyecto ni usar rutas relativas. Node ya usa NODE_PATH como ruta de
# resolucion de respaldo (solo si el modulo no esta en node_modules local),
# asi que esto no interfiere con proyectos que ya tengan su propia
# dependencia instalada.

_pptxgenjs_home() {
    printf '%s' "${PPTXGENJS_HOME:-$HOME/.pptxgenjs}"
}

export NODE_PATH="$(_pptxgenjs_home)/node_modules${NODE_PATH:+:$NODE_PATH}"

pptxgenjs_help() {
    cat <<'EOF'
PptxGenJS helpers

pptxgenjs_check
pptxgenjs_install
pptxgenjs_update
pptxgenjs_uninstall
pptxgenjs_run

Niveles de comandos:
- pptxgenjs_install
    Instala pptxgenjs (npm) en un directorio propio (PPTXGENJS_HOME, default
    ~/.pptxgenjs), separado de cualquier proyecto. NO registra nada en
    Codex/Claude/Antigravity - no es un servidor MCP, es una libreria: se usa
    escribiendo scripts .js/.ts que hacen require('pptxgenjs').
- pptxgenjs_run
    No hay proyecto que preparar (como con Context7/Playwright). Genera un
    .pptx real de prueba (texto + forma) en un directorio temporal, valida
    que el archivo resultante sea un ZIP/OOXML valido de tamano razonable, y
    lo borra. Confirma que require('pptxgenjs') y la generacion funcionan de
    punta a punta.

Como usarla en scripts (una vez instalada, en cualquier script node de esta
shell, sin imports especiales):

    const PptxGenJS = require('pptxgenjs');
    const pres = new PptxGenJS();
    const slide = pres.addSlide();
    slide.addText('Hola', { x: 1, y: 1, fontSize: 24 });
    pres.writeFile({ fileName: 'salida.pptx' });

Environment:
- PPTXGENJS_HOME: directorio de instalacion (default: ~/.pptxgenjs)

Typical flow:
1. pptxgenjs_check
2. pptxgenjs_install
3. pptxgenjs_run
EOF
}

pptxgenjs_check() {
    local missing=0 home version
    home="$(_pptxgenjs_home)"

    for cmd in node npm; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf '[ok] %s\n' "$cmd"
        else
            printf '[fail] %s\n' "$cmd" >&2
            missing=1
        fi
    done

    if command -v node >/dev/null 2>&1; then
        # Leer version por ruta absoluta al package.json instalado, no por
        # `require('pptxgenjs/package.json')`: ese subpath falla (package
        # "exports" no lo expone) aunque `require('pptxgenjs')` normal si
        # funcione - confirmado probando ambos.
        version="$(node -e "try { process.stdout.write(require('$home/node_modules/pptxgenjs/package.json').version) } catch (e) { process.exit(1) }" 2>/dev/null)"
        if [ -n "$version" ]; then
            printf '[ok] pptxgenjs %s instalado en %s\n' "$version" "$home"
        else
            printf '[fail] pptxgenjs no encontrado en %s; corre pptxgenjs_install\n' "$home" >&2
            missing=1
        fi

        if NODE_PATH="$home/node_modules${NODE_PATH:+:$NODE_PATH}" node -e "require.resolve('pptxgenjs')" >/dev/null 2>&1; then
            printf '[ok] require("pptxgenjs") resuelve via NODE_PATH\n'
        else
            printf '[warn] require("pptxgenjs") no resuelve via NODE_PATH en esta shell; abre una shell nueva o vuelve a hacer source del modulo\n'
        fi
    fi

    return "$missing"
}

pptxgenjs_install() {
    local home
    home="$(_pptxgenjs_home)"

    echo "======================================"
    echo " PptxGenJS Installer"
    echo "======================================"

    if ! command -v npm >/dev/null 2>&1; then
        echo "npm no esta instalado (viene con Node.js)."
        return 1
    fi

    mkdir -p "$home" || return 1

    if [ ! -f "$home/package.json" ]; then
        echo "Inicializando $home ..."
        # No usar `npm init -y`: deriva el nombre del paquete del nombre de
        # carpeta, y PPTXGENJS_HOME por defecto empieza con "." (~/.pptxgenjs)
        # - npm rechaza nombres de paquete que empiezan con punto. Se escribe
        # el package.json directo con un nombre valido fijo.
        cat > "$home/package.json" <<'EOF'
{
  "name": "pptxgenjs-home",
  "version": "1.0.0",
  "private": true,
  "description": "Instalacion compartida de pptxgenjs para scripts node (ver aliases.d/221-pptxgenjs)."
}
EOF
    fi

    echo "Instalando pptxgenjs en $home ..."
    ( cd "$home" && npm install pptxgenjs@latest ) || return 1

    echo ""
    echo "======================================"
    echo " Instalacion completada"
    echo "======================================"
    echo ""
    echo "pptxgenjs queda disponible via NODE_PATH en cualquier script node de esta shell"
    echo "(abre una shell nueva, o vuelve a hacer source de este modulo, si NODE_PATH"
    echo "no estaba exportado todavia):"
    echo ""
    echo "    node -e \"const p = require('pptxgenjs'); console.log(p)\""
    echo ""
    echo "Para probar que genera un .pptx real:"
    echo ""
    echo "    pptxgenjs_run"
    echo ""
}

pptxgenjs_update() {
    local home
    home="$(_pptxgenjs_home)"

    if [ ! -d "$home" ]; then
        echo "pptxgenjs no esta instalado (no existe $home). Corre pptxgenjs_install primero."
        return 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        echo "npm no esta instalado."
        return 1
    fi

    echo "Actualizando pptxgenjs en $home ..."
    ( cd "$home" && npm install pptxgenjs@latest )
}

pptxgenjs_uninstall() {
    local home
    home="$(_pptxgenjs_home)"

    if [ ! -d "$home" ]; then
        echo "No hay nada que desinstalar (no existe $home)."
        return 0
    fi

    rm -rf "$home"
    echo "Eliminado: $home"
    echo "NODE_PATH sigue apuntando ahi hasta que abras una shell nueva."
}

# Smoke test real: genera un .pptx de verdad (texto + forma) en un directorio
# temporal propio, valida que sea un ZIP/OOXML valido (firma PK + tamano
# minimo razonable - un .pptx es un zip, un archivo corrupto/truncado no
# tendria esa firma), y lo borra. No deja ningun archivo en el cwd del
# usuario.
pptxgenjs_run() {
    local home script_file rc=0

    home="$(_pptxgenjs_home)"

    if ! command -v node >/dev/null 2>&1; then
        echo "node no esta disponible."
        return 1
    fi

    if ! NODE_PATH="$home/node_modules${NODE_PATH:+:$NODE_PATH}" node -e "require.resolve('pptxgenjs')" >/dev/null 2>&1; then
        echo "pptxgenjs no esta instalado. Ejecuta pptxgenjs_install primero."
        return 1
    fi

    echo "No hay proyecto que preparar (pptxgenjs no indexa nada, es una libreria)."
    echo "Generando un .pptx real de prueba (texto + forma) en un directorio temporal..."
    echo ""

    script_file="$(mktemp --suffix=.js)"
    cat > "$script_file" <<'JS'
const fs = require('fs');
const os = require('os');
const path = require('path');
const PptxGenJS = require('pptxgenjs');

const outDir = fs.mkdtempSync(path.join(os.tmpdir(), 'pptxgenjs-smoke-'));
const outFile = path.join(outDir, 'smoke-test.pptx');

const pres = new PptxGenJS();
const slide = pres.addSlide();
slide.addText('PptxGenJS smoke test OK', { x: 1, y: 1, w: 8, h: 1, fontSize: 24, bold: true });
slide.addShape(pres.ShapeType.rect, { x: 1, y: 2.5, w: 3, h: 1, fill: { color: '2E86AB' } });

pres.writeFile({ fileName: outFile })
  .then(() => {
    const stat = fs.statSync(outFile);
    const fd = fs.openSync(outFile, 'r');
    const buf = Buffer.alloc(4);
    fs.readSync(fd, buf, 0, 4, 0);
    fs.closeSync(fd);
    const isZip = buf[0] === 0x50 && buf[1] === 0x4b; // firma ZIP "PK"

    console.log(`Archivo generado: ${outFile} (${stat.size} bytes)`);

    fs.rmSync(outDir, { recursive: true, force: true });

    if (!isZip || stat.size < 1000) {
      console.error('[fail] el archivo no parece un .pptx valido (firma ZIP o tamano incorrectos).');
      process.exit(1);
    }

    console.log('OK: PptxGenJS genero un .pptx real y valido.');
  })
  .catch((err) => {
    console.error('[fail]', err && err.message ? err.message : err);
    fs.rmSync(outDir, { recursive: true, force: true });
    process.exit(1);
  });
JS

    NODE_PATH="$home/node_modules${NODE_PATH:+:$NODE_PATH}" node "$script_file"
    rc=$?
    rm -f "$script_file"

    return "$rc"
}
