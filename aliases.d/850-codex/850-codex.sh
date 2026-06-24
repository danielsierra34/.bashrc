#!/usr/bin/env bash

_codex_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

_codex_timestamp() {
  date +%F_%H%M%S
}

_codex_write_front_matter() {
  local root
  root="$(_codex_repo_root)"
  printf '# %s\n\n' "${1:-Codex snapshot}"
  printf -- '- Date: %s\n' "$(date -Iseconds)"
  printf -- '- Repo: %s\n' "$root"
  printf -- '- Branch: %s\n' "$(git -C "$root" branch --show-current 2>/dev/null || printf 'unknown')"
  printf -- '- Commit: %s\n' "$(git -C "$root" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
}

_codex_update_state() {
  local root key value
  root="$(_codex_repo_root)"
  key="$1"
  value="$2"

  [ -f "$root/.codex/state.json" ] || return 0
  case "$key" in
    last_session|last_snapshot|objective)
      perl -0pi -e "s/(\"$key\"\\s*:\\s*\")[^\"]*(\")/\$1$value\$2/" "$root/.codex/state.json"
      ;;
  esac
}

_codex_json_escape() {
  local value
  value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\r'/}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

_codex_write_state_json() {
  local root stamp snapshot_path objective decisions pending
  root="$(_codex_repo_root)"
  stamp="$1"
  snapshot_path="$2"
  objective="$3"
  decisions="$4"
  pending="$5"

  mkdir -p "$root/.codex"
  cat > "$root/.codex/state.json" <<EOF
{
  "last_session": "$(_codex_json_escape "$stamp")",
  "last_snapshot": "$(_codex_json_escape "$snapshot_path")",
  "objective": "$(_codex_json_escape "$objective")",
  "decisions": "$(_codex_json_escape "$decisions")",
  "pending": "$(_codex_json_escape "$pending")",
  "updated_at": "$(_codex_json_escape "$(date -Iseconds)")"
}
EOF
}

_codex_write_context() {
  local root stamp snapshot_path objective decisions pending
  root="$(_codex_repo_root)"
  stamp="$1"
  snapshot_path="$2"
  objective="$3"
  decisions="$4"
  pending="$5"

  cat > "$root/.codex/context.md" <<EOF
# Contexto del repositorio

## Estado

- Objetivo actual: ${objective:-Sin definir}
- Ultima sesion: ${stamp:-}
- Ultimo snapshot: ${snapshot_path:-}

## Decisiones recientes

${decisions:-Sin decisiones registradas.}

## Pendientes

${pending:-Sin pendientes registrados.}
EOF
}

_codex_extract_section() {
  local file heading
  file="$1"
  heading="$2"

  awk -v target="^##[[:space:]]+${heading}[[:space:]]*$" '
    BEGIN { capture = 0 }
    $0 ~ target { capture = 1; next }
    capture && $0 ~ /^##[[:space:]]+/ { exit }
    capture { print }
  ' "$file" | sed '/^[[:space:]]*$/d'
}

_codex_refresh_context() {
  local summary_file stamp snapshot_path objective decisions pending
  summary_file="$1"
  stamp="$2"
  snapshot_path="$3"

  objective="$(_codex_extract_section "$summary_file" "Objetivo actual")"
  decisions="$(_codex_extract_section "$summary_file" "Decisiones recientes")"
  pending="$(_codex_extract_section "$summary_file" "Pendientes")"

  if [ -z "$objective" ]; then
    objective="$(grep -m1 -E '^[-*]?[[:space:]]*Objetivo actual:[[:space:]]*' "$summary_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')"
  fi
  if [ -z "$decisions" ]; then
    decisions="$(grep -m1 -E '^[-*]?[[:space:]]*Decisiones recientes:[[:space:]]*' "$summary_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')"
  fi
  if [ -z "$pending" ]; then
    pending="$(grep -m1 -E '^[-*]?[[:space:]]*Pendientes:[[:space:]]*' "$summary_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')"
  fi

  _codex_write_context "$stamp" "$snapshot_path" "$objective" "$decisions" "$pending"
  _codex_write_state_json "$stamp" "$snapshot_path" "$objective" "$decisions" "$pending"
}

_codex_open_text_file() {
  local path editor
  path="$1"
  editor="${EDITOR:-}"

  if [ -n "$editor" ] && command -v "$editor" >/dev/null 2>&1; then
    command "$editor" "$path"
  elif command -v less >/dev/null 2>&1; then
    less "$path"
  else
    cat "$path"
  fi
}

_codex_has_native_cli() {
  type -P codex >/dev/null 2>&1
}

_codex_windows_cli() {
  local candidate

  candidate="$(cmd.exe /c where codex 2>/dev/null | tr -d '\r' | head -n 1)"
  if [ -n "$candidate" ]; then
    printf '%s' "$candidate"
    return 0
  fi

  candidate="$(powershell.exe -NoProfile -Command "(Get-Command codex).Path" 2>/dev/null | tr -d '\r' | head -n 1)"
  if [ -n "$candidate" ]; then
    printf '%s' "$candidate"
    return 0
  fi

  return 1
}

_codex_ps_quote() {
  local value
  value="${1//\'/\'\'}"
  printf "'%s'" "$value"
}

_codex_cli_path() {
  local path
  path="$1"

  if _codex_has_native_cli; then
    printf '%s' "$path"
  else
    wslpath -w "$path"
  fi
}

_codex_run() {
  if _codex_has_native_cli; then
    command codex "$@"
  else
    local win_cd win_cli ps_command ps_args arg
    win_cd="$(_codex_cli_path "$PWD")"
    win_cli="$(_codex_windows_cli)" || return 1

    ps_command="\$ErrorActionPreference = 'Stop'; Set-Location -LiteralPath $(_codex_ps_quote "$win_cd"); & $(_codex_ps_quote "$win_cli")"
    for arg in "$@"; do
      ps_args="$ps_args $(_codex_ps_quote "$arg")"
    done

    powershell.exe -NoProfile -Command "$ps_command$ps_args"
  fi
}

codex() {
  _codex_run "$@"
}

codex_here() {
  _codex_run --cd "$(_codex_cli_path "$PWD")" "$@"
}

codex_root() {
  local root
  root="$(_codex_repo_root)"
  _codex_run --cd "$(_codex_cli_path "$root")" "$@"
}

codex_go() {
  local target
  target="${1:-.}"
  shift || true
  cd "$target" || return 1
  _codex_run --cd "$(_codex_cli_path "$PWD")" "$@"
}

codex_init() {
  local root
  root="$(_codex_repo_root)"

  mkdir -p "$root/.codex/history" "$root/.codex/notes" "$root/.codex/prompts"

  if [ ! -f "$root/.codex/context.md" ]; then
    cat > "$root/.codex/context.md" <<'EOF'
# Contexto del repositorio

## Estado

- Objetivo actual:
- Ultima sesion:
- Decisiones recientes:
- Riesgos abiertos:
EOF
  fi

  if [ ! -f "$root/.codex/session.md" ]; then
    cat > "$root/.codex/session.md" <<'EOF'
# Sesion activa

- Inicio:
- Proposito:
- Estado:
EOF
  fi

  if [ ! -f "$root/.codex/state.json" ]; then
    cat > "$root/.codex/state.json" <<'EOF'
{
  "last_session": "",
  "last_snapshot": "",
  "objective": "",
  "decisions": "",
  "pending": "",
  "updated_at": ""
}
EOF
  fi

  if [ ! -f "$root/.codex/commands.md" ]; then
    cat > "$root/.codex/commands.md" <<'EOF'
# Comandos utiles

- `codex_here`
- `codex_root`
- `codex_go`
- `codex_init`
- `codex_save`
- `codex_resume`
- `codex_status`
- `codex_note`
- `codex_ls`
- `codex_open`
- `codex_sync`
- `codex_bootstrap`
- `codex_new`
- `codex_help`
- `codex_verify`
EOF
  fi

  printf '%s\n' "$root/.codex"
}

codex_save() {
  local root stamp file title session_marker summary_source
  root="$(_codex_repo_root)"
  stamp="$(_codex_timestamp)"
  file="$root/.codex/history/$stamp.md"
  title="${1:-Codex snapshot}"
  session_marker="${CODEX_SESSION_ID:-}"
  summary_source="$(mktemp)"

  mkdir -p "$root/.codex/history"
  if [ -t 0 ]; then
    printf -- '- Completar aqui el resumen de la sesion.\n' > "$summary_source"
  else
    cat > "$summary_source"
  fi

  {
    _codex_write_front_matter "$title"
    if [ -n "$session_marker" ]; then
      printf -- '- Session: %s\n' "$session_marker"
    fi
    printf '\n## Resumen\n\n'
    cat "$summary_source"
    printf '\n'
  } > "$file"

  printf '%s' "$file" > "$root/.codex/.last_snapshot"
  _codex_update_state last_snapshot "$stamp"
  _codex_refresh_context "$summary_source" "$stamp" "$file"
  rm -f "$summary_source"
  printf '%s\n' "$file"
}

codex_resume() {
  local root
  root="$(_codex_repo_root)"
  _codex_run resume --last --cd "$(_codex_cli_path "$root")" "$@"
}

codex_chat() {
  local root stamp session_file chat_file title summary_file raw_log transcript_cmd line objective decisions pending snapshot_path transcript_text win_cli ps_command
  root="$(_codex_repo_root)"
  stamp="$(_codex_timestamp)"
  title="${1:-Codex chat}"
  session_file="$root/.codex/history/$stamp.session.md"
  chat_file="$root/.codex/history/$stamp.md"
  summary_file="$(mktemp)"
  raw_log="$(mktemp)"

  mkdir -p "$root/.codex/history"
  {
    _codex_write_front_matter "$title"
    printf '\n## Inicio\n\n'
    printf -- '- Comando: codex --cd %s\n' "$root"
    printf -- '- Session marker: pending\n'
    printf '\n## Prompt\n\n'
    if [ -n "$1" ]; then
      printf '%s\n' "$1"
    else
      printf 'Sesion interactiva sin prompt inicial.\n'
    fi
    printf '\n'
  } > "$session_file"

  _codex_update_state last_session "$stamp"
  printf '%s\n' "$session_file"

  if _codex_has_native_cli; then
    transcript_cmd=(codex --cd "$(_codex_cli_path "$root")" --no-alt-screen)
  else
    win_cli="$(_codex_windows_cli)" || {
      printf 'No encuentro codex nativo ni el binario de Windows. Ejecuta codex_install o instala Codex primero.\n' >&2
      rm -f "$summary_file" "$raw_log"
      return 1
    }
    ps_command="\$ErrorActionPreference = 'Stop'; Set-Location -LiteralPath $(_codex_ps_quote "$(_codex_cli_path "$root")"); & $(_codex_ps_quote "$win_cli") --cd $(_codex_ps_quote "$(_codex_cli_path "$root")") --no-alt-screen"
    transcript_cmd=(powershell.exe -NoProfile -Command "$ps_command")
  fi

  script -q -f -c "$(printf '%q ' "${transcript_cmd[@]}")" "$raw_log"

  {
    printf 'Resumen final para %s\n' "$title"
    printf 'Usa exactamente estas secciones:\n'
    printf '## Objetivo actual\n'
    printf '## Decisiones recientes\n'
    printf '## Pendientes\n'
    printf 'Deja una linea vacia para terminar.\n'
    printf '\n'
  } >&2

  if [ -t 0 ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && break
      printf '%s\n' "$line" >> "$summary_file"
    done
  else
    cat > "$summary_file"
  fi

  {
    printf '\n## Resumen final\n\n'
    if [ -s "$summary_file" ]; then
      cat "$summary_file"
    else
      printf -- '- Sin resumen final.\n'
    fi
    printf '\n'
  } >> "$session_file"

  snapshot_path="$(codex_save "$title" < "$summary_file")"
  transcript_text="$(perl -0pe 's/\r/\n/g; s/\e\[[0-9;]*[A-Za-z]//g; s/\e\][^\a]*(\a|\e\\)//g' "$raw_log")"
  {
    _codex_write_front_matter "$title"
    printf '\n## Session\n\n'
    printf -- '- Session file: %s\n' "$session_file"
    printf -- '- Snapshot file: %s\n' "$snapshot_path"
    printf '\n## Transcript\n\n'
    printf '```text\n'
    printf '%s\n' "$transcript_text"
    printf '```\n'
    printf '\n## Resumen final\n\n'
    if [ -s "$summary_file" ]; then
      cat "$summary_file"
    else
      printf -- '- Sin resumen final.\n'
    fi
    printf '\n'
  } > "$chat_file"

  printf '%s\n' "$chat_file"
  rm -f "$summary_file" "$raw_log"
}

codex_status() {
  local root history_count last_snapshot
  root="$(_codex_repo_root)"
  history_count="$(find "$root/.codex/history" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  last_snapshot="$(find "$root/.codex/history" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | tail -n 1)"

  printf 'repo: %s\n' "$root"
  printf 'codex_dir: %s\n' "$root/.codex"
  printf 'history_files: %s\n' "${history_count:-0}"
  printf 'last_snapshot: %s\n' "${last_snapshot:-none}"
}

codex_note() {
  local root stamp file title
  root="$(_codex_repo_root)"
  stamp="$(_codex_timestamp)"
  file="$root/.codex/notes/$stamp.md"
  title="${1:-Nota Codex}"

  mkdir -p "$root/.codex/notes"
  {
    printf '# %s\n\n' "$title"
    printf -- '- Date: %s\n' "$(date -Iseconds)"
    printf -- '- Repo: %s\n' "$root"
    printf '\n## Contenido\n\n'
    if [ -t 0 ]; then
      printf -- '- Escribe aqui la nota.\n'
    else
      cat
    fi
    printf '\n'
  } > "$file"

  printf '%s\n' "$file"
}

codex_ls() {
  local root latest_snapshot latest_session latest_note file
  root="$(_codex_repo_root)"

  latest_snapshot="$(find "$root/.codex/history" -maxdepth 1 -type f -name '*.md' ! -name '*.session.md' 2>/dev/null | sort | tail -n 1)"
  latest_session="$(find "$root/.codex/history" -maxdepth 1 -type f -name '*.session.md' 2>/dev/null | sort | tail -n 1)"
  latest_note="$(find "$root/.codex/notes" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | tail -n 1)"

  printf 'repo: %s\n' "$root"
  printf 'codex_dir: %s\n' "$root/.codex"
  printf '\n[history]\n'
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    printf '%s\n' "${file#"$root"/}"
  done < <(find "$root/.codex/history" -maxdepth 1 -type f 2>/dev/null | sort)
  printf '\n[notes]\n'
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    printf '%s\n' "${file#"$root"/}"
  done < <(find "$root/.codex/notes" -maxdepth 1 -type f 2>/dev/null | sort)
  printf '\n[latest]\n'
  printf 'snapshot: %s\n' "${latest_snapshot:-none}"
  printf 'session: %s\n' "${latest_session:-none}"
  printf 'note: %s\n' "${latest_note:-none}"
}

codex_open() {
  local root target path
  root="$(_codex_repo_root)"
  target="${1:-context}"

  case "$target" in
    context|ctx)
      path="$root/.codex/context.md"
      ;;
    state)
      path="$root/.codex/state.json"
      ;;
    session)
      path="$(find "$root/.codex/history" -maxdepth 1 -type f -name '*.session.md' 2>/dev/null | sort | tail -n 1)"
      ;;
    latest|snapshot)
      path="$(find "$root/.codex/history" -maxdepth 1 -type f -name '*.md' ! -name '*.session.md' 2>/dev/null | sort | tail -n 1)"
      ;;
    note|notes)
      path="$(find "$root/.codex/notes" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort | tail -n 1)"
      ;;
    *)
      path="$target"
      ;;
  esac

  if [ -z "$path" ] || [ ! -e "$path" ]; then
    printf 'No existe: %s\n' "$path" >&2
    return 1
  fi

  _codex_open_text_file "$path"
}

codex_sync() {
  local root source stamp snapshot_file
  root="$(_codex_repo_root)"
  source="${1:-}"

  if [ -z "$source" ]; then
    source="$(find "$root/.codex/history" -maxdepth 1 -type f -name '*.md' ! -name '*.session.md' 2>/dev/null | sort | tail -n 1)"
  fi
  if [ -z "$source" ] || [ ! -f "$source" ]; then
    printf 'No hay snapshot para sincronizar.\n' >&2
    return 1
  fi

  stamp="$(date +%F_%H%M%S)"
  snapshot_file="$source"
  _codex_refresh_context "$source" "$stamp" "$snapshot_file"
  printf '%s\n' "$root/.codex/context.md"
}

codex_bootstrap() {
  local root stamp objective bootstrap_snapshot
  root="$(_codex_repo_root)"
  objective="${1:-Sin definir}"
  stamp="$(_codex_timestamp)"
  bootstrap_snapshot="$root/.codex/bootstrap.md"

  codex_init >/dev/null

  {
    _codex_write_front_matter "Codex bootstrap"
    printf '\n## Objetivo inicial\n\n'
    printf '%s\n' "$objective"
    printf '\n## Estado\n\n'
    printf -- '- Repo listo para usar con Codex.\n'
    printf -- '- Ejecuta `codex_chat` para iniciar una sesion trazable.\n'
    printf '\n'
  } > "$bootstrap_snapshot"

  _codex_write_context "$stamp" "$bootstrap_snapshot" "$objective" "Sin decisiones registradas." "Sin pendientes registrados."
  _codex_write_state_json "$stamp" "$bootstrap_snapshot" "$objective" "Sin decisiones registradas." "Sin pendientes registrados."
  printf '%s\n' "$root/.codex/context.md"
}

codex_new() {
  local target objective
  target="${1:-}"
  shift || true
  objective="${*:-Sin definir}"

  if [ -z "$target" ]; then
    printf 'Uso: codex_new <ruta> [objetivo]\n' >&2
    return 1
  fi

  if [ -e "$target" ] && [ ! -d "$target" ]; then
    printf 'La ruta existe y no es un directorio: %s\n' "$target" >&2
    return 1
  fi

  mkdir -p "$target" || return 1
  cd "$target" || return 1
  codex_bootstrap "$objective"
}

codex_help() {
  cat <<'EOF'
Codex CLI quick help

source ~/bashrc/aliases
codex_new ~/work/proyecto "Objetivo"
cd ~/work/proyecto
codex_chat "Sesion"
codex_save "cierre"
codex_ls
codex_open context
codex_sync

Key commands:
- codex_new: create and bootstrap a new workspace
- codex_bootstrap: initialize .codex/ in the current repo
- codex_chat: run an interactive session and store a markdown transcript
- codex_save: save a snapshot and refresh local context
- codex_ls: list history, notes, and recent artifacts
- codex_open: open context, state, latest, session, or a path
- codex_sync: rebuild context and state from a snapshot
EOF
}

codex_verify() {
  local root missing=0
  root="$(_codex_repo_root)"

  if _codex_has_native_cli || command -v cmd.exe >/dev/null 2>&1; then
    printf '[ok] codex bridge available\n'
  else
    printf '[fail] codex bridge not available\n' >&2
    missing=1
  fi

  if [ -d "$root/.codex" ]; then
    printf '[ok] .codex directory exists\n'
  else
    printf '[fail] .codex directory is missing\n' >&2
    missing=1
  fi

  for required in context.md state.json commands.md; do
    if [ -f "$root/.codex/$required" ]; then
      printf '[ok] %s\n' "$root/.codex/$required"
    else
      printf '[fail] missing %s\n' "$root/.codex/$required" >&2
      missing=1
    fi
  done

  if [ -d "$root/.codex/history" ]; then
    printf '[ok] history directory exists\n'
  else
    printf '[fail] history directory is missing\n' >&2
    missing=1
  fi

  if [ "$missing" -eq 0 ]; then
    printf 'codex workspace is ready\n'
    return 0
  fi

  printf 'codex workspace has issues\n' >&2
  return 1
}

codex_install() {
  if command -v codex >/dev/null 2>&1; then
    printf 'codex ya esta instalado en: %s\n' "$(command -v codex)"
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    printf 'Falta npm. Instala Node.js/npm primero.\n' >&2
    return 1
  fi

  npm install -g @openai/codex@latest
}
