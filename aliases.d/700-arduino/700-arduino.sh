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

arduino_help() {
  command -v compilar >/dev/null 2>&1 || {
    echo "❌ Falta la función compilar (revisa 700-arduino/710-simple.sh)." >&2
    return 1
  }
  command -v upload >/dev/null 2>&1 || {
    echo "❌ Falta la función upload (revisa 700-arduino/710-simple.sh)." >&2
    return 1
  }
  command -v monitor >/dev/null 2>&1 || {
    echo "❌ Falta la función monitor (revisa 700-arduino/710-simple.sh)." >&2
    return 1
  }

  local ino_root="${ARDUINO_INO_ROOT:-$HOME/arduino/ino}"
  if [ ! -d "$ino_root" ]; then
    echo "❌ No existe la carpeta de proyectos: $ino_root" >&2
    echo "👉  Crea la estructura 'ino/<proyecto>/<proyecto>.ino' o exporta ARDUINO_INO_ROOT." >&2
    return 1
  fi

  local busid
  busid="$(_ardu_simple_busid)" || return 1
  _ardu_simple_ensure_usb_attached || return 1
  echo "🔌 BUSID detectado y adjuntado: $busid"

  while true; do
    echo
    echo "========= Arduino Help ========="
    echo "1) Compilar proyecto (.ino)"
    echo "2) Subir a la placa conectada"
    echo "3) Monitor serie (usa BUSID detectado)"
    echo "0) Salir"
    read -rp "Opción: " o

    case "$o" in
      1)
        local project
        project="$(_ardu_help_choose_project "$ino_root")" || continue
        compilar "$project"
        ;;
      2)
        local project
        project="$(_ardu_help_choose_project "$ino_root")" || continue
        upload "$project"
        ;;
      3)
        _ardu_simple_ensure_usb_attached || continue
        read -rp "Baudrate [115200]: " b
        b="${b:-115200}"
        monitor "$b"
        ;;
      0) return ;;
      *) echo "⚠️  Opción inválida" ;;
    esac
  done
}
