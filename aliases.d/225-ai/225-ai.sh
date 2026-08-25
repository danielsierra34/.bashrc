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
AI helpers (umbrella sobre los 8 modulos de herramientas de IA)

ai_install
ai_init [ruta|.]

- ai_install
    Corre, en orden, el *_install de los 8 modulos (graphify, serena,
    context7, playwright, pptxgenjs, infographic-skill, python-docx,
    pymupdf). Cada uno se ejecuta aunque el anterior haya fallado (mismo
    criterio que cada modulo individual: avisa y continua). Termina con un
    resumen OK/FAIL por herramienta.
- ai_init [ruta|.]
    Prepara UN proyecto localmente. Solo toca graphify_run y serena_run -
    son los unicos 2 de los 8 que generan estado persistente por proyecto
    (graphify-out/, .serena/). Los otros 6 son globales por naturaleza (ver
    el comentario al inicio de este archivo) y no se tocan aqui para no
    disparar llamadas de red o abrir un browser real como efecto secundario
    de "inicializar un proyecto".

Typical flow:
1. ai_install                        (una vez, deja todo listo globalmente)
2. cd /ruta/del/proyecto && ai_init .   (por cada proyecto)
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
