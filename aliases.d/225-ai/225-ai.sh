########################################################################################## AI (umbrella)

# Comandos "todo en uno" sobre los 8 modulos de herramientas de IA de este
# repo (217-graphify .. 224-pymupdf): uno para instalar TODO globalmente, y
# otro para inicializar UN proyecto localmente.
#
# El split global/local no es simetrico entre los 8 - por diseno, no por
# descuido:
#   - graphify y serena SI generan estado persistente por proyecto
#     (graphify-out/, .serena/) -> tienen un paso local real.
#   - context7, playwright, pptxgenjs, python-docx, pymupdf son globales por
#     naturaleza (MCP sin estado de proyecto, o librerias via NODE_PATH/
#     PYTHONPATH) y sus *_run son smoke tests, no inicializacion - correrlos
#     "por proyecto" pegaria llamadas de red / abriria un browser real sin
#     que el usuario lo pidiera. Por eso ai_init NO los toca.
#   - infographic-skill es una Skill global; no tiene concepto de "proyecto".
#
# Caveat real (visto probando esto en el propio repo bashrc): `serena_install`
# esta pensado como paso global, pero `serena init` puede detectar por su
# cuenta que el cwd desde donde se corre ai_install es un proyecto real y
# auto-crear .serena/project.yml ahi como efecto secundario. Si te importa
# evitarlo, corre ai_install desde $HOME, no desde dentro de un repo con
# codigo fuente.
#
# Este archivo no depende del orden de carga: para cuando el usuario LLAMA a
# estas funciones (no cuando se cargan), el loader (aliases) ya sourceo los
# 8 modulos completos sin importar en que orden aparezcan en aliases.d/.

_AI_INSTALL_FUNCS=(
    graphify_install
    serena_install
    context7_install
    playwright_install
    pptxgenjs_install
    infographic_skill_install
    pythondocx_install
    pymupdf_install
)

ai_help() {
    cat <<'EOF'
AI helpers - mapa de las 8 herramientas de IA de este repo

=== Puesta en marcha ===

  ai_install            instala las 8 herramientas, globalmente, una vez
  ai_init [ruta|.]       prepara UN proyecto (solo graphify + serena, ver abajo)

  Flujo tipico:
    1. ai_install
    2. cd /ruta/del/proyecto && ai_init .

=== Como se USAN una vez instaladas (la parte que importa) ===

Hay 3 formas distintas de "usar" estas herramientas - no todas se invocan
igual. Por eso `<algo>_run` en cada modulo es casi siempre un SMOKE TEST
(prueba que funciona), no la forma real de usar la herramienta dia a dia:

  A) MCP (graphify, serena, context7, playwright): una vez registrados, el
     AGENTE (Claude Code/Codex/Antigravity) los llama solo, cuando el pedido
     del usuario calza. Vos no tipeas comandos MCP a mano - le pedis la tarea
     en lenguaje natural y el agente decide usar la herramienta.
  B) Skill (infographic-skill): igual que MCP, se activa sola cuando el
     agente reconoce el pedido (ver su descripcion en skill/SKILL.md).
  C) Librerias puras (pptxgenjs, python-docx, pymupdf): no se "activan"
     solas - le pedis al agente que escriba y corra un script que las use
     (import docx / require('pptxgenjs') / import pymupdf). Estan
     disponibles sin setup extra por NODE_PATH/PYTHONPATH ya exportados.

=== Las 8, una por una ===

--- graphify (217) --- MCP + skill --- mapa/arquitectura del codebase
  Que hace: grafo de comunidades, god nodes, relaciones cross-file.
  Como se activa: automatico, el agente corre `graphify query "..."` antes
    de explorar codigo a ciegas (regla ya en CLAUDE.md de este repo).
  Gestion: graphify_check / graphify_install / graphify_run [ruta|.] /
    graphify_update / graphify_uninstall
  Detalle completo: graphify_help

--- serena (218) --- MCP --- navegacion semantica via LSP
  Que hace: ir a definicion, encontrar referencias reales, refactor seguro
    a nivel de simbolo (no texto).
  Como se activa: automatico una vez registrado; en Antigravity hay que
    pedir "activate the current project" en el primer chat de cada proyecto.
  Gestion: serena_check / serena_install / serena_run [ruta|.] /
    serena_update / serena_uninstall / serena_mcp_status
  Detalle completo: serena_help

--- context7 (219) --- MCP remoto --- documentacion de librerias al dia
  Que hace: resuelve una libreria (resolve-library-id) y trae su doc
    version-especifica (get-library-docs) - evita que el agente alucine
    APIs viejas.
  Como se activa: automatico; el agente lo usa cuando escribe codigo contra
    una libreria externa.
  Gestion: context7_check / context7_install / context7_run [ruta|.] [query]
    (smoke test, no indexa nada) / context7_update / context7_uninstall
  Detalle completo: context7_help

--- playwright (220) --- MCP local --- control de browser real
  Que hace: navegar, click, llenar formularios, capturas de pantalla -
    sobre un browser real, no simulado.
  Como se activa: automatico; el agente lo usa para probar UIs o scrapear.
  Gestion: playwright_check / playwright_install / playwright_run [url]
    (smoke test) / playwright_update / playwright_uninstall
  Detalle completo: playwright_help

--- infographic-skill (222) --- Skill --- diseno de infografias
  Que hace: composicion, jerarquia visual, anti-patrones de infografias
    "hechas por IA sin cuidado".
  Como se activa: automatico cuando pedis un one-pager/infografia/resumen
    visual - sin decir la palabra "infografia" necesariamente.
  Gestion: infographic_skill_check / infographic_skill_install /
    infographic_skill_update / infographic_skill_uninstall (sin _run)
  Detalle completo: infographic_skill_help

--- pptxgenjs (221) --- libreria Node --- generar .pptx (PowerPoint)
  Como se usa: pedile al agente un script que haga
    require('pptxgenjs') / new PptxGenJS() / slide.addText(...) / writeFile()
  Gestion: pptxgenjs_check / pptxgenjs_install / pptxgenjs_run (smoke test) /
    pptxgenjs_update / pptxgenjs_uninstall
  Detalle completo: pptxgenjs_help

--- python-docx (223) --- libreria Python --- generar/editar .docx (Word)
  Como se usa: pedile al agente un script que haga
    from docx import Document / doc.add_heading(...) / doc.save(...)
  Gestion: pythondocx_check / pythondocx_install / pythondocx_run (smoke
    test) / pythondocx_update / pythondocx_uninstall
  Detalle completo: pythondocx_help

--- pymupdf (224) --- libreria Python --- leer/renderizar/generar PDF
  Como se usa: pedile al agente un script que haga
    import pymupdf / doc = pymupdf.open(...) / page.get_text() /
    page.get_pixmap(...)
  Gestion: pymupdf_check / pymupdf_install / pymupdf_run (smoke test) /
    pymupdf_update / pymupdf_uninstall
  Detalle completo: pymupdf_help

=== Diagnostico rapido ===

  Para revisar el estado de una sola herramienta: <nombre>_check
  Ejemplo: serena_check, context7_check, pymupdf_check ...
EOF
}

ai_install() {
    local fn rc=0
    declare -A results

    echo "=================================================================="
    echo " Instalando TODAS las herramientas (global)"
    echo "=================================================================="

    for fn in "${_AI_INSTALL_FUNCS[@]}"; do
        echo ""
        echo "------------------------------------------------------------------"
        echo " -> $fn"
        echo "------------------------------------------------------------------"
        if "$fn"; then
            results["$fn"]="OK"
        else
            results["$fn"]="FAIL"
            rc=1
        fi
    done

    echo ""
    echo "=================================================================="
    echo " Resumen"
    echo "=================================================================="
    for fn in "${_AI_INSTALL_FUNCS[@]}"; do
        printf '  [%s] %s\n' "${results[$fn]}" "$fn"
    done

    return "$rc"
}

ai_init() {
    local target rc=0
    target="${1:-.}"

    echo "=================================================================="
    echo " Inicializando el proyecto (local): $target"
    echo "=================================================================="

    echo ""
    echo "------------------------------------------------------------------"
    echo " -> graphify_run"
    echo "------------------------------------------------------------------"
    graphify_run "$target" || rc=1

    echo ""
    echo "------------------------------------------------------------------"
    echo " -> serena_run"
    echo "------------------------------------------------------------------"
    serena_run "$target" || rc=1

    echo ""
    echo "=================================================================="
    echo " Sin paso local (uso global, nada que inicializar por proyecto):"
    echo "=================================================================="
    echo "  - context7           MCP remoto sin estado de proyecto"
    echo "  - playwright         MCP local sin estado de proyecto"
    echo "  - pptxgenjs          libreria global via NODE_PATH"
    echo "  - python-docx        libreria global via PYTHONPATH"
    echo "  - pymupdf            libreria global via PYTHONPATH"
    echo "  - infographic-skill  skill global, no por-proyecto"

    return "$rc"
}
