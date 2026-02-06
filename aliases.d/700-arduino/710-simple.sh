# Simple Arduino assistant commands (compilar, upload, monitor)

_ardu_simple_need_cli() {
  command -v arduino-cli >/dev/null && return 0
  echo "❌ arduino-cli no está instalado. Ejecuta arduino_install primero." >&2
  return 1
}

_ardu_simple_list_dirs() {
  local root
  root="${1:-$PWD}"
  find "$root" -type f -name 'script.ino' -print0 2>/dev/null |
    while IFS= read -r -d '' file; do dirname "$file"; done | sort -u
}

_ardu_simple_pick_from_list() {
  local prompt="$1"; shift || true
  local items=()
  while IFS= read -r line; do
    [ -n "$line" ] && items+=("$line")
  done
  local total=${#items[@]}
  [ "$total" -eq 0 ] && return 1
  if [ "$total" -eq 1 ]; then
    printf '%s\n' "${items[0]}"
    return 0
  fi
  local i
  for ((i=0; i<total; i++)); do
    printf '%2d) %s\n' $((i+1)) "${items[i]}"
  done
  local selection
  read -rp "$prompt " selection
  if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "$total" ]; then
    printf '%s\n' "${items[selection-1]}"
    return 0
  fi
  echo "❌ Selección inválida" >&2
  return 1
}

_ardu_simple_choose_dir() {
  local dirs
  dirs="$(_ardu_simple_list_dirs "$PWD")"
  [ -z "$dirs" ] && { echo "❌ No encontré carpetas con .ino" >&2; return 1; }
  _ardu_simple_pick_from_list "Elige carpeta:" <<<"$dirs"
}

_ardu_simple_fqbn_file="$HOME/.arduino-helper-fqbn"

_ardu_simple_auto_fqbn() {
  command -v python3 >/dev/null || return 1
  local detected
  detected="$(arduino-cli board list --format json 2>/dev/null | python3 - <<'PY'
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
ports = None
if isinstance(data, dict) and "ports" in data:
    ports = data["ports"]
elif isinstance(data, list):
    ports = data
else:
    ports = []
fqbns = []
for port in ports:
    boards = port.get("matching_boards") or port.get("boards") or []
    for board in boards:
        fqbn = board.get("fqbn")
        if fqbn:
            fqbns.append(fqbn)
unique = sorted(set(fqbns))
if len(unique) == 1:
    print(unique[0])
PY
)"
  [ -n "$detected" ] && printf '%s\n' "$detected"
}

_ardu_simple_fqbn() {
  if [ -n "$ARDUINO_FQBN" ]; then
    printf '%s\n' "$ARDUINO_FQBN"
    return 0
  fi
  if [ -f "$_ardu_simple_fqbn_file" ]; then
    read -r saved < "$_ardu_simple_fqbn_file"
    if [ -n "$saved" ]; then
      printf '%s\n' "$saved"
      return 0
    fi
  fi
  local auto
  auto="$(_ardu_simple_auto_fqbn)"
  if [ -n "$auto" ]; then
    printf '%s\n' "$auto" > "$_ardu_simple_fqbn_file"
    printf '%s\n' "$auto"
    return 0
  fi
  read -rp "FQBN (ej. esp8266:esp8266:nodemcuv2): " fqbn
  [ -z "$fqbn" ] && { echo "❌ Necesito un FQBN" >&2; return 1; }
  printf '%s\n' "$fqbn" > "$_ardu_simple_fqbn_file"
  printf '%s\n' "$fqbn"
}

_ardu_simple_single_port() {
  local ports
  ports=$(ls /dev/ttyACM* /dev/ttyUSB* 2>/dev/null | tr '\n' ' ')
  [ -z "$ports" ] && { echo "❌ No veo ninguna placa en /dev/ttyACM* o /dev/ttyUSB*" >&2; return 1; }
  set -- $ports
  if [ "$#" -gt 1 ]; then
    echo "❌ Encontré varias placas: $ports" >&2
    echo "👉 Desconecta las que no usarás o especifica ARDUINO_PORT." >&2
    return 1
  fi
  printf '%s\n' "$1"
}

_ardu_simple_port() {
  if [ -n "$ARDUINO_PORT" ]; then
    printf '%s\n' "$ARDUINO_PORT"
    return 0
  fi
  _ardu_simple_single_port
}

_ardu_simple_resolve_folder() {
  local target folder
  target="$1"
  if [ -n "$target" ]; then
    if [ -d "$target" ]; then
      folder="$target"
    elif [ -f "$target" ]; then
      folder="$(dirname "$target")"
    else
      echo "❌ No existe $target" >&2
      return 1
    fi
  else
    folder="$(_ardu_simple_choose_dir)" || return 1
  fi
  folder="$(realpath -s "$folder")"
  if [ ! -f "$folder/script.ino" ]; then
    echo "❌ Esperaba encontrar script.ino dentro de $folder" >&2
    return 1
  fi
  printf '%s\n' "$folder"
}

compilar() {
  _ardu_simple_need_cli || return 1
  local folder fqbn
  folder="$(_ardu_simple_resolve_folder "$1")" || return 1
  fqbn="$(_ardu_simple_fqbn)" || return 1
  echo "⚙️ Compilando $folder con $fqbn..."
  arduino-cli compile --fqbn "$fqbn" "$folder"
}

upload() {
  _ardu_simple_need_cli || return 1
  local folder fqbn port ino
  folder="$(_ardu_simple_resolve_folder "$1")" || return 1
  ino="$folder/script.ino"
  fqbn="$(_ardu_simple_fqbn)" || return 1
  port="$(_ardu_simple_port)" || return 1
  echo "⬆️ Subiendo $ino a $port..."
  arduino-cli upload --fqbn "$fqbn" -p "$port" "$folder"
}

monitor() {
  _ardu_simple_need_cli || return 1
  local port baud
  port="$(_ardu_simple_port)" || return 1
  baud="${1:-115200}"
  echo "📡 Monitor conectando a $port @ ${baud}bps"
  arduino-cli monitor -p "$port" -c baudrate="$baud"
}
