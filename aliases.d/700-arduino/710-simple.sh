# Simple Arduino assistant commands (compilar, upload, monitor)

_ardu_simple_need_cli() {
  command -v arduino-cli >/dev/null && return 0
  echo "❌ arduino-cli no está instalado. Ejecuta arduino_install primero." >&2
  return 1
}

_ardu_simple_list_dirs() {
  local root="${1:-$PWD}"
  command -v python3 >/dev/null 2>&1 || {
    echo "❌ python3 es necesario para listar proyectos Arduino." >&2
    return 1
  }
  python3 - <<'PY' "$root"
import os, sys
root = sys.argv[1]
seen = set()
for dirpath, _, files in os.walk(root):
    base = os.path.basename(dirpath.rstrip(os.sep))
    if not base:
        continue
    sketch = f"{base}.ino"
    if sketch in files:
        seen.add(os.path.realpath(dirpath))
for path in sorted(seen):
    print(path)
PY
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
  if [ -t 0 ]; then
    read -rp "$prompt " selection
  else
    if [ -e /dev/tty ]; then
      read -rp "$prompt " selection < /dev/tty
    else
      echo "❌ No hay TTY disponible para leer la selección." >&2
      return 1
    fi
  fi
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
  [ -z "$dirs" ] && { echo "❌ No encontré carpetas cuyo .ino coincida con el nombre de la carpeta." >&2; return 1; }
  _ardu_simple_pick_from_list "Elige carpeta:" <<<"$dirs"
}

_ardu_help_choose_project() {
  local root="${1:-$PWD}"
  local dirs
  dirs="$(_ardu_simple_list_dirs "$root")"
  [ -z "$dirs" ] && { echo "❌ No encontré proyectos .ino dentro de $root" >&2; return 1; }
  echo "Proyectos disponibles en $root:"
  _ardu_simple_pick_from_list "Elige proyecto:" <<<"$dirs"
}

_ardu_simple_fqbn_file="$HOME/.arduino-helper-fqbn"
_ardu_simple_busid_file="$HOME/.arduino-helper-busid"

_ardu_simple_valid_fqbn() {
  local value="$1"
  case "$value" in
    *:*:*) return 0 ;;
    *) return 1 ;;
  esac
}

_ardu_simple_valid_busid() {
  [[ "$1" =~ ^[0-9]+-[0-9]+$ ]]
}

_ardu_simple_usbipd_exe() {
  local candidate
  if [ -n "${USBIPD_EXE:-}" ]; then
    candidate="$USBIPD_EXE"
    if [[ "$candidate" =~ ^[A-Za-z]:\\ ]]; then
      if command -v wslpath >/dev/null 2>&1; then
        local converted
        converted="$(wslpath "$candidate" 2>/dev/null)" && candidate="$converted"
      fi
    fi
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi
  for candidate in "/mnt/c/Program Files/usbipd-win/usbipd.exe" "/mnt/c/Program Files (x86)/usbipd-win/usbipd.exe"; do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  if command -v usbipd >/dev/null 2>&1; then
    command -v usbipd
    return 0
  fi
  return 1
}

_ardu_simple_usbipd_list() {
  local exe
  if exe="$(_ardu_simple_usbipd_exe)"; then
    "$exe" list
    return $?
  fi
  command -v powershell.exe >/dev/null 2>&1 || return 1
  powershell.exe -NoProfile -Command "usbipd list"
}

_ardu_simple_usbipd_attach() {
  local exe
  if exe="$(_ardu_simple_usbipd_exe)"; then
    "$exe" attach --wsl --busid "$1"
    return $?
  fi
  command -v powershell.exe >/dev/null 2>&1 || return 1
  powershell.exe -NoProfile -Command "usbipd attach --wsl --busid $1"
}

_ardu_simple_auto_fqbn() {
  command -v python3 >/dev/null || return 1
  _ardu_simple_ensure_usb_attached >/dev/null 2>&1 || true
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
    if _ardu_simple_valid_fqbn "$ARDUINO_FQBN"; then
      printf '%s\n' "$ARDUINO_FQBN"
      return 0
    else
      echo "⚠️  ARDUINO_FQBN='$ARDUINO_FQBN' no parece un FQBN válido (ej. vendor:arch:board)." >&2
    fi
  fi
  if [ -f "$_ardu_simple_fqbn_file" ]; then
    read -r saved < "$_ardu_simple_fqbn_file"
    if [ -n "$saved" ]; then
      if _ardu_simple_valid_fqbn "$saved"; then
        printf '%s\n' "$saved"
        return 0
      else
        echo "⚠️  Ignorando FQBN guardado inválido: $saved" >&2
        rm -f "$_ardu_simple_fqbn_file"
      fi
    fi
  fi
  local auto
  auto="$(_ardu_simple_auto_fqbn)"
  if [ -n "$auto" ]; then
    if ! _ardu_simple_valid_fqbn "$auto"; then
      echo "⚠️  La detección automática devolvió '$auto', que no es un FQBN completo. Intentaré preguntar manualmente." >&2
    else
      printf '%s\n' "$auto" > "$_ardu_simple_fqbn_file"
      printf '%s\n' "$auto"
      return 0
    fi
  fi
  read -rp "FQBN (ej. esp8266:esp8266:nodemcuv2): " fqbn
  if ! _ardu_simple_valid_fqbn "$fqbn"; then
    echo "❌ '$fqbn' no es un FQBN válido. Debe tener el formato vendor:arch:board." >&2
    return 1
  fi
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
  _ardu_simple_ensure_usb_attached || return 1
  _ardu_simple_single_port
}

_ardu_simple_busid() {
  local busid
  if [ -n "$ARDUINO_USB_BUSID" ]; then
    if _ardu_simple_valid_busid "$ARDUINO_USB_BUSID"; then
      echo "$ARDUINO_USB_BUSID"
      return 0
    else
      echo "⚠️  ARDUINO_USB_BUSID='$ARDUINO_USB_BUSID' no tiene formato válido (ej. 2-6)." >&2
    fi
  fi
  if [ -f "$_ardu_simple_busid_file" ]; then
    read -r busid < "$_ardu_simple_busid_file"
    if _ardu_simple_valid_busid "$busid"; then
      echo "$busid"
      return 0
    fi
  fi
  local usbipd_output
  usbipd_output="$(_ardu_simple_usbipd_list 2>/dev/null | tr -d '\r')"
  if [ -n "$usbipd_output" ]; then
    busid="$(printf '%s\n' "$usbipd_output" | awk '
      BEGIN {IGNORECASE=1}
      /^BUSID/ {next}
      NF < 3 {next}
      /USB-SERIAL|CP210|CH340|Arduino/ {print $1; exit}
    ')"
    if _ardu_simple_valid_busid "$busid"; then
      printf '%s\n' "$busid" > "$_ardu_simple_busid_file"
      echo "$busid"
      return 0
    fi
    echo "⚠️  No pude deducir el BUSID a partir de 'usbipd list'. Salida:" >&2
    printf '%s\n' "$usbipd_output"
  else
    echo "⚠️  No obtuve salida de 'usbipd list'. ¿Está usbipd instalado en Windows?" >&2
  fi
  while true; do
    if [ -t 0 ]; then
      read -rp "Ingresa el BUSID a adjuntar (ej. 2-6): " busid
    elif [ -e /dev/tty ]; then
      read -rp "Ingresa el BUSID a adjuntar (ej. 2-6): " busid < /dev/tty
    else
      echo "❌ No hay TTY para introducir el BUSID. Exporta ARDUINO_USB_BUSID=BUSID y reintenta." >&2
      return 1
    fi
    busid="${busid//[[:space:]]/}"
    if _ardu_simple_valid_busid "$busid"; then
      printf '%s\n' "$busid" > "$_ardu_simple_busid_file"
      echo "$busid"
      return 0
    fi
    echo "⚠️  '$busid' no tiene formato válido (ej. 2-6). Intenta de nuevo." >&2
  done
}

_ardu_simple_attach_usb() {
  local busid
  busid="$(_ardu_simple_busid)" || return 1
  _ardu_simple_usbipd_attach "$busid" >/dev/null 2>&1 && return 0
  echo "⚠️  usbipd attach falló; prueba ejecutar en PowerShell (Admin):" >&2
  echo "    usbipd bind --busid $busid --force" >&2
  echo "    usbipd attach --wsl --busid $busid" >&2
  return 1
}

_ardu_simple_ensure_usb_attached() {
  ls /dev/ttyACM* /dev/ttyUSB* >/dev/null 2>&1 && return 0
  _ardu_simple_attach_usb || return 1
  sleep 1
  ls /dev/ttyACM* /dev/ttyUSB* >/dev/null 2>&1 || { echo "❌ No se detectó el puerto serial tras intentar usbipd attach." >&2; return 1; }
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
  local basename sketch
  basename="$(basename "$folder")"
  sketch="$folder/$basename.ino"
  if [ ! -f "$sketch" ]; then
    echo "❌ Esperaba encontrar $basename.ino dentro de $folder" >&2
    echo "👉 Asegúrate de que el archivo .ino tenga el mismo nombre que la carpeta." >&2
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
  fqbn="$(_ardu_simple_fqbn)" || return 1
  port="$(_ardu_simple_port)" || return 1
  ino="$folder/$(basename "$folder").ino"
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
