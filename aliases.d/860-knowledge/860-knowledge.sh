#!/usr/bin/env bash

_knowledge_write_if_missing() {
  local file_path
  file_path="$1"
  shift || true

  if [ -e "$file_path" ]; then
    cat >/dev/null
    return 0
  fi

  mkdir -p "$(dirname "$file_path")"
  cat > "$file_path"
}

knowledge_help() {
  cat <<'EOF'
knowledge_scaffold <ruta> [nombre]

Creates a versionable knowledge workspace with:
- original/
- knowledge/markdown/
- knowledge/assets/
- generated/docs/
- generated/spreadsheets/
- generated/images/
- generated/infographics/
- .codex/
- README.md
- AI_CONTEXT.md
- .gitignore
EOF
}

knowledge_scaffold() {
  local target_path project_name objective codex_ready
  target_path="${1:-}"
  shift || true
  project_name="${*:-}"

  if [ -z "$target_path" ]; then
    printf 'Uso: knowledge_scaffold <ruta> [nombre]\n' >&2
    return 1
  fi

  if [ -e "$target_path" ] && [ ! -d "$target_path" ]; then
    printf 'La ruta existe y no es un directorio: %s\n' "$target_path" >&2
    return 1
  fi

  mkdir -p "$target_path" || return 1
  cd "$target_path" || return 1

  project_name="${project_name:-$(basename "$PWD")}"
  objective="Base de conocimiento versionable para ${project_name}"

  mkdir -p \
    original/inbox \
    knowledge/markdown \
    knowledge/assets \
    generated/docs \
    generated/spreadsheets \
    generated/images \
    generated/infographics \
    scripts

  _knowledge_write_if_missing README.md <<EOF
# ${project_name}

Repositorio de base de conocimiento versionable.

## Estructura

- original/: fuentes originales recibidas.
- knowledge/markdown/: conversiones y normalizacion a Markdown.
- knowledge/assets/: imagenes, diagramas y adjuntos extraidos.
- generated/: entregables producidos desde la base de conocimiento.
- .codex/: contexto, historial y estado de trabajo.
EOF

  _knowledge_write_if_missing AI_CONTEXT.md <<EOF
# AI Context

## Project

- Name: ${project_name}
- Objective: ${objective}

## Workflow

1. Place incoming files in original/inbox.
2. Convert or extract content into knowledge/markdown.
3. Save images and references in knowledge/assets.
4. Generate final deliverables in generated/.
5. Keep the repository as the source of truth.
EOF

  _knowledge_write_if_missing .gitignore <<'EOF'
# Local and temporary files
.DS_Store
Thumbs.db
*.swp
*.tmp
*.bak
.codex/.last_snapshot
EOF

  _knowledge_write_if_missing original/README.md <<'EOF'
# original

Store original source files here:
- PDFs
- Word documents
- Excel workbooks
- images
- infographics

This folder is the raw intake area. Keep file names stable and traceable.
EOF

  _knowledge_write_if_missing knowledge/README.md <<'EOF'
# knowledge

Normalized, reusable knowledge lives here.

- markdown/: canonical Markdown versions
- assets/: extracted diagrams, screenshots, and referenced images
EOF

  _knowledge_write_if_missing generated/README.md <<'EOF'
# generated

Versioned outputs produced from the knowledge base.

- docs/: PDF and Word deliverables
- spreadsheets/: Excel outputs
- images/: rendered visual assets
- infographics/: final infographic exports
EOF

  if type -t codex_bootstrap >/dev/null 2>&1; then
    codex_bootstrap "$objective" >/dev/null
    codex_ready=1
  else
    mkdir -p .codex/history .codex/notes .codex/prompts
    _knowledge_write_if_missing .codex/context.md <<EOF
# Contexto del repositorio

## Estado

- Objetivo actual: ${objective}
- Ultima sesion:
- Ultimo snapshot:

## Decisiones recientes

Sin decisiones registradas.

## Pendientes

Sin pendientes registrados.
EOF
    _knowledge_write_if_missing .codex/state.json <<'EOF'
{
  "last_session": "",
  "last_snapshot": "",
  "objective": "",
  "decisions": "",
  "pending": "",
  "updated_at": ""
}
EOF
    _knowledge_write_if_missing .codex/commands.md <<'EOF'
# Comandos utiles

- knowledge_scaffold
- knowledge_help
EOF
    codex_ready=0
  fi

  printf '%s\n' "$PWD"
  if [ "$codex_ready" -eq 0 ]; then
    printf '%s\n' 'codex bootstrap is available after loading the codex module' >&2
  fi
}
