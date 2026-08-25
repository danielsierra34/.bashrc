########################################################################################## INFOGRAPHIC SKILL

# Skill de autor propio (no un paquete de terceros) para generar buenos
# infografias: composicion, jerarquia visual, anti-patrones que delatan una
# infografia hecha por IA sin cuidado. El contenido real vive en
# skill/SKILL.md junto a este archivo (fuente de verdad versionada); estas
# funciones solo lo copian a los 3 directorios de skills globales que Claude
# Code, Codex y Antigravity leen realmente. No es un MCP ni una libreria: no
# hay "run" (una skill no se ejecuta, el agente la carga cuando es relevante),
# solo instalar/actualizar/verificar.
#
# Ubicaciones de skills confirmadas (mismo formato SKILL.md en los 3):
#   Claude Code:  ~/.claude/skills/<nombre>/SKILL.md      (o .claude/skills/ por proyecto)
#   Codex:        ~/.codex/skills/<nombre>/SKILL.md       (o .codex/skills/ por proyecto;
#                 detras de un feature flag: `codex --enable skills`)
#   Antigravity:  ~/.gemini/config/skills/<nombre>/SKILL.md (confirmado probando
#                 `graphify install --platform antigravity`, 217-graphify.sh)

_INFOGRAPHIC_SKILL_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

_infographic_skill_source_dir() {
    printf '%s' "$_INFOGRAPHIC_SKILL_MODULE_DIR/skill"
}

_infographic_skill_targets() {
    printf '%s\n' \
        "claude=$HOME/.claude/skills/infographic" \
        "codex=$HOME/.codex/skills/infographic" \
        "antigravity=$HOME/.gemini/config/skills/infographic"
}

infographic_skill_help() {
    cat <<'EOF'
Infographic skill helpers

infographic_skill_check
infographic_skill_install
infographic_skill_update
infographic_skill_uninstall

No hay "run": una Skill no se ejecuta, el agente (Claude Code/Codex/
Antigravity) la carga solo cuando el pedido del usuario calza con su
descripcion (infografia, one-pager, resumen visual, poster de stats, etc).

- infographic_skill_install / infographic_skill_update
    Copia skill/SKILL.md (la fuente de verdad, versionada en este repo) a
    los 3 directorios de skills globales:
      ~/.claude/skills/infographic/SKILL.md
      ~/.codex/skills/infographic/SKILL.md   (requiere 'codex --enable skills')
      ~/.gemini/config/skills/infographic/SKILL.md
    Ambos comandos hacen lo mismo (copiar la version actual); "update" existe
    solo para que el flujo se sienta igual al de graphify/serena/etc. Editar
    skill/SKILL.md en este repo y volver a correr install/update es como se
    itera el contenido de la skill.
- infographic_skill_check
    Compara cada destino contra la fuente (bytewise) y avisa si falta o esta
    desactualizado.
- infographic_skill_uninstall
    Borra los 3 directorios instalados (no toca skill/SKILL.md, la fuente).

Typical flow:
1. (editar skill/SKILL.md si hace falta)
2. infographic_skill_install
3. infographic_skill_check
EOF
}

infographic_skill_check() {
    local src_dir label path missing=0
    src_dir="$(_infographic_skill_source_dir)"

    if [ ! -f "$src_dir/SKILL.md" ]; then
        echo "[fail] no encuentro el SKILL.md fuente en $src_dir" >&2
        return 1
    fi
    printf '[ok] fuente: %s\n' "$src_dir/SKILL.md"

    while IFS='=' read -r label path; do
        if [ -f "$path/SKILL.md" ] && cmp -s "$src_dir/SKILL.md" "$path/SKILL.md"; then
            printf '[ok] %-11s sincronizado (%s)\n' "$label" "$path"
        elif [ -f "$path/SKILL.md" ]; then
            printf '[warn] %-11s desactualizado (%s) - corre infographic_skill_update\n' "$label" "$path"
            missing=1
        else
            printf '[warn] %-11s no instalado (%s) - corre infographic_skill_install\n' "$label" "$path"
            missing=1
        fi
    done < <(_infographic_skill_targets)

    return "$missing"
}

_infographic_skill_sync_one() {
    local label target_dir src_dir
    label="$1"
    target_dir="$2"
    src_dir="$(_infographic_skill_source_dir)"

    mkdir -p "$target_dir" || return 1

    if [ -f "$target_dir/SKILL.md" ] && cmp -s "$src_dir/SKILL.md" "$target_dir/SKILL.md"; then
        printf '[ok] %-11s sin cambios (%s)\n' "$label" "$target_dir"
        return 0
    fi

    cp "$src_dir/SKILL.md" "$target_dir/SKILL.md" || return 1
    printf '[ok] %-11s actualizado (%s)\n' "$label" "$target_dir"
}

infographic_skill_install() {
    local src_dir label path rc=0
    src_dir="$(_infographic_skill_source_dir)"

    if [ ! -f "$src_dir/SKILL.md" ]; then
        echo "No encuentro el SKILL.md fuente en $src_dir" >&2
        return 1
    fi

    echo "Instalando la skill 'infographic' (global) para Claude Code, Codex y Antigravity..."
    echo ""

    while IFS='=' read -r label path; do
        _infographic_skill_sync_one "$label" "$path" || rc=1
    done < <(_infographic_skill_targets)

    echo ""
    echo "Nota: en Codex, las skills estan detras de un feature flag: 'codex --enable skills'."

    return "$rc"
}

infographic_skill_update() {
    infographic_skill_install
}

infographic_skill_uninstall() {
    local label path
    while IFS='=' read -r label path; do
        if [ -d "$path" ]; then
            rm -rf "$path"
            echo "Eliminado: $path"
        else
            echo "No estaba instalado: $path"
        fi
    done < <(_infographic_skill_targets)
}
