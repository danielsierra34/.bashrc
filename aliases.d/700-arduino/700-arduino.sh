arduino_install() {

  echo "========================================="
  echo " 🤖 Arduino + VSCode + IA Setup Assistant"
  echo "========================================="

  # Detect OS
  OS="$(uname -s)"

  echo "🖥️ Sistema detectado: $OS"

  # 1. Instalar Arduino CLI
  if ! command -v arduino-cli &> /dev/null; then
    echo "📦 Instalando Arduino CLI..."

    if [[ "$OS" == "Linux" ]]; then
      curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
      sudo mv bin/arduino-cli /usr/local/bin/

    elif [[ "$OS" == "Darwin" ]]; then
      brew install arduino-cli

    else
      echo "⚠️ OS no soportado automáticamente."
      echo "Instala Arduino CLI manualmente."
      return 1
    fi

  else
    echo "✅ Arduino CLI ya instalado."
  fi


  # 2. Inicializar config
  echo "⚙️ Inicializando configuración..."

  if [ ! -f "$HOME/.arduino15/arduino-cli.yaml" ]; then
    arduino-cli config init
  else
    echo "✅ Configuración ya existe."
  fi


  # 3. Update index
  echo "🔄 Actualizando índice..."
  arduino-cli core update-index


  # 4. Menú placas
  echo ""
  echo "📟 Selecciona tu placa:"
  echo "1) Arduino UNO / Nano"
  echo "2) ESP32"
  echo "3) ESP8266 / NodeMCU"
  echo ""

  read -p "👉 Opción: " board


  case $board in

    1)
      echo "📥 Instalando AVR Core..."
      arduino-cli core install arduino:avr
      FQBN="arduino:avr:uno"
      ;;

    2)
      echo "📥 Instalando ESP32 Core..."

      arduino-cli config set board_manager.additional_urls \
      https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json

      arduino-cli core update-index
      arduino-cli core install esp32:esp32

      FQBN="esp32:esp32:esp32"
      ;;

    3)
      echo "📥 Instalando ESP8266 Core..."

      arduino-cli config set board_manager.additional_urls \
      https://arduino.esp8266.com/stable/package_esp8266com_index.json

      arduino-cli core update-index
      arduino-cli core install esp8266:esp8266

      FQBN="esp8266:esp8266:nodemcuv2"
      ;;

    *)
      echo "❌ Opción inválida"
      return 1
      ;;
  esac


  # 5. Detectar puerto
  echo ""
  echo "🔌 Buscando placa conectada..."

  arduino-cli board list


  echo ""
  echo "========================================="
  echo " ✅ Instalación completada"
  echo "========================================="
  echo ""
  echo "📌 FQBN configurado:"
  echo "   $FQBN"
  echo ""
  echo "👉 Para compilar:"
  echo "   arduino-cli compile --fqbn $FQBN ."
  echo ""
  echo "👉 Para subir:"
  echo "   arduino-cli upload -p COMX --fqbn $FQBN ."
  echo ""
  echo "👉 Para monitor:"
  echo "   arduino-cli monitor -p COMX -c baudrate=115200"
  echo ""
  echo "🤖 Ya puedes usar Codex como copiloto."
  echo "========================================="
}

# ===============================
# Arduino WSL Assistant
# ===============================
ardu() {
  local assistant="$HOME/bin/ardu-wsl.sh"

  if [[ ! -x "$assistant" ]]; then
    echo "❌ No se encuentra el asistente en $assistant"
    echo "👉 Asegúrate de que exista y tenga permisos de ejecución"
    return 1
  fi

  # Asegurar que estamos en WSL
  if ! grep -qi microsoft /proc/version; then
    echo "❌ Esta función está pensada para ejecutarse dentro de WSL"
    return 1
  fi

  # Ejecutar el asistente
  "$assistant"
}

arduino_run() {
  set +e

  # ========= Utilidades =========
  _ok()   { echo "✅ $*"; }
  _warn() { echo "⚠️  $*"; }
  _die()  { echo "❌ $*" >&2; return 1; }

  _is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }

  _need() {
    command -v arduino-cli >/dev/null || _die "No existe arduino-cli en WSL"
    command -v powershell.exe >/dev/null || _die "No existe powershell.exe"
    _is_wsl || _die "Esta función solo funciona en WSL"
  }

  # ========= PowerShell → usbipd =========
  _usbipd() {
    powershell.exe -NoProfile -ExecutionPolicy Bypass \
      -Command "& 'C:\Program Files\usbipd-win\usbipd.exe' $*" 2>&1 | tr -d '\r'
  }

  _usb_list() { _usbipd list; }

  _serial_busids() {
    _usb_list | awk '
      /^[0-9]+-[0-9]+/ &&
      /(CP210|CH340|USB-SERIAL|FTDI|UART|Serial)/ {print $1}'
  }

  _auto_busid() {
    local b; b="$(_serial_busids)"
    [ "$(echo "$b" | wc -l)" -eq 1 ] && echo "$b"
  }

  _choose_busid() {
    local b n
    b="$(_serial_busids)"
    [ -z "$b" ] && _die "No se detectó USB-Serial. Posible driver faltante en Windows."
    nl -w2 -s") " <<<"$b"
    read -rp "Elige BUSID: " n
    echo "$b" | sed -n "${n}p"
  }

  _attach() {
    _usbipd attach --wsl --busid "$1" >/dev/null 2>&1 && return 0
    _warn "No se pudo hacer attach automático"
    echo
    echo "👉 Ejecuta en PowerShell ADMIN (una sola vez):"
    echo "usbipd bind --busid $1 --force"
    echo "usbipd attach --wsl --busid $1"
    return 1
  }

  # ========= Puertos WSL =========
  _ports() { ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null; }

  _auto_port() {
    local p; p="$(_ports)"
    [ "$(echo "$p" | wc -l)" -eq 1 ] && echo "$p"
  }

  _choose_port() {
    local p n
    p="$(_ports)"
    [ -z "$p" ] && _die "No hay puertos seriales en WSL"
    nl -w2 -s") " <<<"$p"
    read -rp "Elige puerto: " n
    echo "$p" | sed -n "${n}p"
  }

  # ========= Placas =========
  _choose_board() {
    echo "1) ESP8266 (NodeMCU / OLED)"
    echo "2) ESP32 (ESP32U / Dev Module)"
    read -rp "Placa: " n
    case "$n" in
      1) echo "esp8266:esp8266:nodemcuv2" ;;
      2) echo "esp32:esp32:esp32" ;;
      *) _die "Opción inválida" ;;
    esac
  }

  # ========= Cores =========
  _core_from_fqbn() { echo "$1" | awk -F: '{print $1 ":" $2}'; }

  _ensure_core() {
    arduino-cli core list | awk 'NR>1{print $1}' | grep -qx "$1" && return 0
    echo "➡️  Instalando core $1 (solo la primera vez)"
    arduino-cli core update-index || return 1
    arduino-cli core install "$1" || return 1
  }

  # ========= Sketch =========
  _pick_sketch() {
    read -rp "Ruta del sketch (carpeta o .ino): " p
    p="${p/#\~/$HOME}"
    [ -e "$p" ] || _die "No existe $p"
    echo "$p"
  }

  _compile() {
    [ -f "$2" ] && arduino-cli compile --fqbn "$1" --input-file "$2" ||
                   arduino-cli compile --fqbn "$1" "$2"
  }

  _upload() {
    [ -f "$3" ] && arduino-cli upload -p "$2" --fqbn "$1" --input-file "$3" ||
                   arduino-cli upload -p "$2" --fqbn "$1" "$3"
  }

  _monitor() {
    read -rp "Baudrate (default 115200): " b
    b="${b:-115200}"
    arduino-cli monitor -p "$1" -c baudrate="$b"
  }

  # ========= MENÚ =========
  _need || return

  while true; do
    echo
    echo "========= Arduino WSL Assistant ========="
    echo "1) Listar USB (Windows)"
    echo "2) Attach USB a WSL"
    echo "3) Compilar"
    echo "4) Upload"
    echo "5) Monitor"
    echo "6) Flujo completo"
    echo "0) Salir"
    read -rp "Opción: " o

    case "$o" in
      1) _usb_list ;;
      2)
        b="$(_auto_busid)"; [ -z "$b" ] && b="$(_choose_busid)"
        _attach "$b"
        ;;
      3)
        fqbn="$(_choose_board)"
        _ensure_core "$(_core_from_fqbn "$fqbn")" || continue
        s="$(_pick_sketch)"
        _compile "$fqbn" "$s"
        ;;
      4)
        fqbn="$(_choose_board)"
        _ensure_core "$(_core_from_fqbn "$fqbn")" || continue
        p="$(_auto_port)"; [ -z "$p" ] && p="$(_choose_port)"
        s="$(_pick_sketch)"
        _upload "$fqbn" "$p" "$s"
        ;;
      5)
        p="$(_auto_port)"; [ -z "$p" ] && p="$(_choose_port)"
        _monitor "$p"
        ;;
      6)
        b="$(_auto_busid)"; [ -z "$b" ] && b="$(_choose_busid)"
        _attach "$b" || continue
        p="$(_auto_port)"; [ -z "$p" ] && p="$(_choose_port)"
        fqbn="$(_choose_board)"
        _ensure_core "$(_core_from_fqbn "$fqbn")" || continue
        s="$(_pick_sketch)"
        _compile "$fqbn" "$s" &&
        _upload "$fqbn" "$p" "$s" &&
        _monitor "$p"
        ;;
      0) return ;;
      *) _warn "Opción inválida" ;;
    esac
  done
}











