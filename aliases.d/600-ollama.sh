########################################################################################## OLLAMA
ollama_install(){
  sudo apt-get install zstd
  curl -fsSL https://ollama.com/install.sh | sh
}

ollama_pull () {
  # Catálogo curado (popular/útil) + descripciones.
  # Puedes ampliar/editar esta lista cuando quieras.

  if ! command -v ollama >/dev/null 2>&1; then
    echo "❌ 'ollama' no está instalado o no está en PATH."
    return 1
  fi

  # Lista de modelos (nombres tal como se usan en `ollama pull`)
  local models=(
    "gemma3:1b"
    "gemma2:2b"
    "gemma2:9b"
    "llama3.2:1b"
    "llama3.2:3b"
    "llama3.2:latest"
    "qwen2.5:7b"
    "qwen2.5:14b"
    "mistral:latest"
    "mixtral:8x7b"
    "phi3:mini"
    "phi3:medium"
    "codellama:7b"
    "starcoder2:7b"
    "deepseek-r1:7b"
    "deepseek-coder:6.7b"
  )

  # Descripciones (para qué sirve cada uno)
  # Nota: si algún nombre cambia en tu versión de Ollama, simplemente ajustas la key.
  declare -A desc=(
    ["gemma3:1b"]="Muy liviano. Ideal para aprender, hacer pruebas rápidas y experimentar prompting."
    ["gemma2:2b"]="Pequeño y práctico. Buen equilibrio para tareas generales en máquina modesta."
    ["gemma2:9b"]="Mejor calidad que los pequeños. General y bastante sólido sin irse a tamaños enormes."
    ["llama3.2:1b"]="Ultraligero. Útil para experimentos rápidos; limitado en profundidad."
    ["llama3.2:3b"]="Pequeño pero más capaz. Buen modelo general para escritorio modesto."
    ["llama3.2:latest"]="General fuerte (según disponibilidad local). Bueno para chat/razonamiento."
    ["qwen2.5:7b"]="Excelente para desarrollo y razonamiento. Muy buen “todo terreno” para programar."
    ["qwen2.5:14b"]="Mejor calidad para código/razonamiento. Recomendado si tu máquina lo aguanta."
    ["mistral:latest"]="Rápido y eficiente. Bueno para respuestas cortas/medianas y chat."
    ["mixtral:8x7b"]="Muy buen rendimiento (MoE). Excelente calidad, pero más pesado."
    ["phi3:mini"]="Modelo pequeño para tareas básicas y pruebas; rápido."
    ["phi3:medium"]="Más capaz que mini; buen balance para tareas generales."
    ["codellama:7b"]="Orientado a programación (Code). Útil si quieres foco en código."
    ["starcoder2:7b"]="Muy bueno para código (especialmente completación y patrones de programación)."
    ["deepseek-r1:7b"]="Fuerte en razonamiento (según variante). Útil para problemas lógicos."
    ["deepseek-coder:6.7b"]="Fuerte para código. Buen competidor para tareas de programación."
  )

  echo "🌐 Catálogo de modelos recomendados para descargar con Ollama"
  echo "   (Selecciona uno y lo instalo con 'ollama pull')"
  echo

  for i in "${!models[@]}"; do
    local m="${models[$i]}"
    local d="${desc[$m]:-Modelo popular (sin descripción en catálogo).}"
    printf "  [%d] %-20s — %s\n" "$((i+1))" "$m" "$d"
  done

  echo
  read -rp "👉 Selecciona un modelo para instalar (1-${#models[@]}) o Enter para cancelar: " choice
  if [ -z "${choice:-}" ]; then
    echo "ℹ️  Cancelado."
    return 0
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#models[@]} )); then
    echo "❌ Selección inválida."
    return 1
  fi

  local selected="${models[$((choice-1))]}"
  echo
  echo "⬇️  Instalando: $selected"
  ollama pull "$selected"
  echo "✅ Instalado: $selected"
}


ollama_modelfile_generate () {
  # Nota: no uso "set -euo pipefail" para que si hay error lo veas y no muera en silencio

  _mf_print_hr() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'; }
  _mf_title() { _mf_print_hr; echo "🦙 Ollama Modelfile Generator (sin whiptail)"; _mf_print_hr; }
  _mf_pause() { read -r -p "Enter para continuar..." _; }

  # options: array of "value|description" (name by reference) -> returns value in REPLY
  _mf_menu_vd() {
    local prompt="$1"
    local arr_name="$2"
    local -n _opts="$arr_name"

    echo
    echo "$prompt"
    local i=1
    for opt in "${_opts[@]}"; do
      local v="${opt%%|*}"
      local d="${opt#*|}"
      printf "  %2d) %-8s  %s\n" "$i" "$v" "$d"
      i=$((i+1))
    done

    while true; do
      read -r -p "Selecciona (1-${#_opts[@]}): " ans
      if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans>=1 && ans<=${#_opts[@]} )); then
        local chosen="${_opts[$((ans-1))]}"
        REPLY="${chosen%%|*}"
        return 0
      fi
      echo "❌ Opción inválida."
    done
  }

  # ===== Directories (HOME) =====
  local ROOT_DIR MF_DIR
  ROOT_DIR="$HOME/ollama"
  MF_DIR="$ROOT_DIR/modelfiles"
  mkdir -p "$MF_DIR" || { echo "❌ No pude crear $MF_DIR"; return 1; }

  _mf_title
  echo "📁 Carpeta destino: $MF_DIR"
  echo "ℹ️  El Modelfile queda con FROM __BASE_MODEL__ (luego lo reemplazas por el modelo real)."
  _mf_pause

  # ===== Tipo / SYSTEM =====
  local TYPE SYSTEM_TEXT
  local -a TYPE_OPTS=(
    "chat|Conversación general y asistencia cotidiana"
    "dev|Desarrollo/arquitectura: decisiones técnicas y buenas prácticas"
    "code|Código preciso y determinista (menos creatividad, más exactitud)"
    "llm|Análisis académico y estudio de LLMs"
    "reason|Razonamiento estructurado paso a paso"
    "docs|Redacción técnica/profesional con estructura"
    "promptlab|Experimentación y pruebas de prompts"
  )
  _mf_menu_vd "TIPO → Define el “rol” del modelo (SYSTEM). Esto es como decirle quién es y cómo debe responder." TYPE_OPTS
  TYPE="$REPLY"

  case "$TYPE" in
    chat) SYSTEM_TEXT=$'Asistente general, claro y conciso.\nResponde en español.' ;;
    dev) SYSTEM_TEXT=$'Asistente de desarrollo.\nSoluciones ejecutables, patrones y buenas prácticas.' ;;
    code) SYSTEM_TEXT=$'Asistente de programación.\nCódigo correcto, minimal y determinista.' ;;
    llm) SYSTEM_TEXT=$'Asistente académico para estudiar y analizar LLMs.' ;;
    reason) SYSTEM_TEXT=$'Asistente de razonamiento paso a paso y análisis lógico.' ;;
    docs) SYSTEM_TEXT=$'Redactor técnico y académico, claro y estructurado.' ;;
    promptlab) SYSTEM_TEXT=$'Asistente para experimentar, evaluar y depurar prompts.' ;;
    *) SYSTEM_TEXT=$'Asistente general.' ;;
  esac

  # ===== Parámetros =====
  local TEMP TOP_P TOP_K NUM_CTX NUM_PRED REP_PEN REP_LAST_N PEN_NL

  # temperature
  local -a TEMP_OPTS=(
    "0.2|Ultra estable: ideal para código, reglas, parsing y salidas repetibles"
    "0.35|Equilibrado: buena precisión sin rigidez (uso general recomendado)"
    "0.6|Exploratorio: mejor para conversación y redacción con variedad"
    "0.8|Creativo: brainstorming/estilo; mayor riesgo de desviarse"
  )
  _mf_menu_vd "temperature → Controla QUÉ TANTO se “arriesga” el modelo al elegir la siguiente palabra. Bajo = más predecible y exacto. Alto = más variado y creativo." TEMP_OPTS
  TEMP="$REPLY"

  # top_p
  local -a TOP_P_OPTS=(
    "0.7|Muy conservador: recorta fuerte opciones raras"
    "0.8|Conservador: control alto con algo de variedad"
    "0.9|Balanceado: núcleo típico (recomendado)"
    "0.95|Diverso: más libertad, menos foco"
    "1.0|Sin recorte: deja pasar todo (controla con temperature)"
  )
  _mf_menu_vd "top_p → Define el “TAMAÑO del menú” de opciones por probabilidad. El modelo considera solo las palabras más probables hasta sumar p (ej. 0.9). Bajo = menos rarezas. Alto = más diversidad." TOP_P_OPTS
  TOP_P="$REPLY"

  # top_k
  local -a TOP_K_OPTS=(
    "0|Desactivado: control solo por top_p (suave)"
    "40|Estándar: buen control sin rigidez"
    "50|Equilibrado: más variedad manteniendo precisión"
    "100|Abierto: permite tokens raros y creativos"
  )
  _mf_menu_vd "top_k → Otro límite al “menú”: en vez de probabilidad, corta por ranking. Solo permite los K tokens más probables. K bajo = más control. K alto = más opciones. 0 = no usar este corte." TOP_K_OPTS
  TOP_K="$REPLY"

  # num_ctx
  local -a NUM_CTX_OPTS=(
    "2048|Contexto corto: rápido/ligero"
    "4096|Contexto normal: recomendado para la mayoría de flujos"
    "8192|Contexto largo: documentos extensos (más RAM/VRAM)"
  )
  _mf_menu_vd "num_ctx → La “MEMORIA” máxima en una respuesta. Es cuántos tokens caben sumando: SYSTEM + tu prompt + historial + lo que estás preguntando. Más contexto = recuerda más, pero consume más recursos." NUM_CTX_OPTS
  NUM_CTX="$REPLY"

  # num_predict
  local -a NUM_PRED_OPTS=(
    "256|Salida corta: respuestas puntuales"
    "512|Salida media: balance entre detalle y foco"
    "1024|Salida larga: explicaciones extensas (riesgo de relleno)"
  )
  _mf_menu_vd "num_predict → LÍMITE de longitud de la respuesta. Es el máximo de tokens que el modelo puede generar. Útil para evitar respuestas eternas o para permitir respuestas largas." NUM_PRED_OPTS
  NUM_PRED="$REPLY"

  # repeat_penalty
  local -a REP_PEN_OPTS=(
    "1.0|Sin penalización: puede repetir si se atasca"
    "1.10|Penalización suave: reduce muletillas (recomendado)"
    "1.20|Penalización fuerte: evita loops, menos natural"
  )
  _mf_menu_vd "repeat_penalty → “ANTI-REPETICIÓN”. Cuando el modelo intenta repetir tokens recientes, esta penalización lo empuja a variar. Más alto = menos repetición (pero puede sonar menos natural)." REP_PEN_OPTS
  REP_PEN="$REPLY"

  # repeat_last_n
  local -a REP_LAST_N_OPTS=(
    "64|Ventana corta: impacto mínimo"
    "128|Ventana media: balance ideal"
    "256|Ventana larga: evita repetición lejana"
  )
  _mf_menu_vd "repeat_last_n → Define QUÉ TANTO texto hacia atrás se revisa para aplicar repeat_penalty. Ventana pequeña = solo evita repeticiones inmediatas. Ventana grande = evita repetir cosas dichas hace más rato." REP_LAST_N_OPTS
  REP_LAST_N="$REPLY"

  # penalize_newline
  local -a PEN_NL_OPTS=(
    "false|Permite formato rico: markdown, listas y código"
    "true|Texto compacto: menos saltos de línea"
  )
  _mf_menu_vd "penalize_newline → Controla la TENDENCIA a usar saltos de línea. Si lo penalizas, responde más “en párrafo”. Si no, facilita listas, markdown y bloques de código." PEN_NL_OPTS
  PEN_NL="$REPLY"

  # ===== Nombre (único input escrito) =====
  echo
  local NAME
  read -r -p "Nombre del Modelfile (único campo que se escribe) [my-${TYPE}]: " NAME
  NAME="${NAME:-my-${TYPE}}"
  NAME="$(echo "$NAME" | tr -cd 'a-zA-Z0-9._-')"
  [[ -z "$NAME" ]] && { echo "❌ Nombre inválido."; return 1; }

  local FILE="$MF_DIR/Modelfile.${NAME}"
  if [[ -e "$FILE" ]]; then
    echo "⚠️ Ya existe: $FILE"
    read -r -p "¿Sobrescribir? (y/N): " yn
    [[ "${yn,,}" == "y" ]] || { echo "Cancelado."; return 1; }
  fi

  cat > "$FILE" <<EOF
FROM __BASE_MODEL__

SYSTEM """
${SYSTEM_TEXT}
"""

PARAMETER temperature ${TEMP}
PARAMETER top_p ${TOP_P}
PARAMETER top_k ${TOP_K}
PARAMETER num_ctx ${NUM_CTX}
PARAMETER num_predict ${NUM_PRED}
PARAMETER repeat_penalty ${REP_PEN}
PARAMETER repeat_last_n ${REP_LAST_N}
PARAMETER penalize_newline ${PEN_NL}
EOF

  echo
  _mf_print_hr
  echo "✅ Modelfile creado correctamente:"
  echo "   $FILE"
  _mf_print_hr
}

ollama_model_generate () {
  # ---- Config ----
  local MF_DIR="$HOME/ollama/modelfiles"
  local TMP_DIR="${TMPDIR:-/tmp}"
  local BASE_MODEL="" MF_PATH="" NEW_NAME=""
  local -a MODELS=() FILES=()

  _omc_hr() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'; }
  _omc_title() { _omc_hr; echo "🦙 Ollama Model Creator (base + Modelfile)"; _omc_hr; }
  _omc_die() { echo "❌ $*"; return 1; }

  # Menú genérico: recibe prompt + array name, retorna REPLY=elemento elegido
  _omc_menu() {
    local prompt="$1"
    local arr_name="$2"
    local -n _opts="$arr_name"
    echo
    echo "$prompt"
    local i=1
    for opt in "${_opts[@]}"; do
      printf "  %2d) %s\n" "$i" "$opt"
      i=$((i+1))
    done
    while true; do
      read -r -p "Selecciona (1-${#_opts[@]}): " ans
      if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans>=1 && ans<=${#_opts[@]} )); then
        REPLY="${_opts[$((ans-1))]}"
        return 0
      fi
      echo "❌ Opción inválida."
    done
  }

  # ---- Checks ----
  command -v ollama >/dev/null 2>&1 || _omc_die "No encuentro 'ollama' en PATH."
  [[ -d "$MF_DIR" ]] || _omc_die "No existe la carpeta de Modelfiles: $MF_DIR"

  _omc_title

  # ---- Cargar modelos locales ----
  # `ollama list` imprime cabecera + columnas; tomamos la primera columna (NAME)
  mapfile -t MODELS < <(ollama list 2>/dev/null | awk 'NR>1 && $1!="" {print $1}')
  (( ${#MODELS[@]} > 0 )) || _omc_die "No hay modelos locales. Primero haz: ollama pull <modelo>"

  _omc_menu "Elige el MODELO BASE (ya descargado):" MODELS
  BASE_MODEL="$REPLY"

  # ---- Cargar Modelfiles disponibles ----
  # Mostramos solo el nombre de archivo para el menú
  mapfile -t FILES < <(find "$MF_DIR" -maxdepth 1 -type f -name 'Modelfile.*' -printf '%f\n' | sort)
  (( ${#FILES[@]} > 0 )) || _omc_die "No encuentro Modelfiles en $MF_DIR (esperaba Modelfile.*)"

  _omc_menu "Elige el Modelfile (en $MF_DIR):" FILES
  MF_PATH="$MF_DIR/$REPLY"

  # ---- Nombre del modelo final ----
  echo
  read -r -p "Nombre del NUEVO modelo (único input) [${REPLY#Modelfile.}]: " NEW_NAME
  NEW_NAME="${NEW_NAME:-${REPLY#Modelfile.}}"
  NEW_NAME="$(echo "$NEW_NAME" | tr -cd 'a-zA-Z0-9._:-')"
  [[ -n "$NEW_NAME" ]] || _omc_die "Nombre inválido."

  # Confirmar si ya existe
  if ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -Fxq "$NEW_NAME"; then
    echo "⚠️ Ya existe un modelo llamado: $NEW_NAME"
    read -r -p "¿Sobrescribir (recrear) ese modelo? (y/N): " yn
    [[ "${yn,,}" == "y" ]] || _omc_die "Cancelado."
  fi

  # ---- Crear un Modelfile temporal (sin tocar el original) ----
  local TMP_MF="$TMP_DIR/Modelfile.${NEW_NAME}.$$"
  # Reemplaza SOLO si existe el placeholder exacto
  if grep -q '^FROM __BASE_MODEL__' "$MF_PATH"; then
    sed "s|^FROM __BASE_MODEL__\$|FROM ${BASE_MODEL}|" "$MF_PATH" > "$TMP_MF"
  else
    # Si no hay placeholder, lo dejamos como está (por si ya tiene FROM real)
    cp "$MF_PATH" "$TMP_MF"
  fi

  echo
  _omc_hr
  echo "🧩 Combinando:"
  echo "  Base:     $BASE_MODEL"
  echo "  Modelfile: $MF_PATH"
  echo "  Nuevo:    $NEW_NAME"
  _omc_hr
  echo

  # ---- Crear modelo ----
  if ! ollama create "$NEW_NAME" -f "$TMP_MF"; then
    rm -f "$TMP_MF"
    _omc_die "Falló ollama create. Revisa que el modelo base exista y el Modelfile sea válido."
  fi

  rm -f "$TMP_MF"

  echo
  _omc_hr
  echo "✅ Modelo creado: $NEW_NAME"
  echo "▶️  Probar ahora:"
  echo "    ollama run $NEW_NAME"
  _omc_hr

  # Ejecutar opcional
  echo
  read -r -p "¿Quieres ejecutarlo ahora? (y/N): " runnow
  if [[ "${runnow,,}" == "y" ]]; then
    ollama run "$NEW_NAME"
  fi
}

ollama_assistant () {
  # -----------------------
  # Config base
  # -----------------------
  local PORT="11434"
  local DEFAULT_BASE="http://localhost:${PORT}"
  local MF_DIR="$HOME/ollama/modelfiles"
  local TMP_DIR="${TMPDIR:-/tmp}"

  # Estado "en memoria" del asistente (no persistente salvo que apliques systemd)
  local API_BASE="${OLLAMA_API_BASE:-$DEFAULT_BASE}"
  local CUR_HOST_BIND="127.0.0.1"     # sugerencia para serve (local)
  local CUR_ORIGINS="(sin tocar)"
  local CUR_MAX_LOADED="(default)"
  local CUR_NUM_PARALLEL="(default)"
  local CUR_MAX_QUEUE="(default)"
  local CUR_KEEP_ALIVE="(default)"
  local CUR_NUM_GPU="(default)"

  # -----------------------
  # Utils
  # -----------------------
  _hr() { printf '%*s\n' "${COLUMNS:-90}" '' | tr ' ' '-'; }
  _title() { _hr; echo "🦙 Ollama Server Assistant (una sola función)"; _hr; }
  _note() { echo "ℹ️  $*"; }
  _ok() { echo "✅ $*"; }
  _warn() { echo "⚠️  $*"; }
  _err() { echo "❌ $*"; }
  _pause() { read -r -p "Enter para continuar..." _; }

  _need() { command -v "$1" >/dev/null 2>&1 || { _err "Falta '$1' en PATH."; return 1; }; }

  _ip_local() {
    if command -v hostname >/dev/null 2>&1; then
      local ip
      ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
      [[ -n "$ip" ]] && { echo "$ip"; return 0; }
    fi
    ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1
  }

  # Menú simple: array de "key|title"
  _menu() {
    local prompt="$1"
    local arr_name="$2"
    local -n opts="$arr_name"
    echo
    echo "$prompt"
    local i=1
    for o in "${opts[@]}"; do
      printf "  %2d) %s\n" "$i" "${o#*|}"
      i=$((i+1))
    done
    while true; do
      read -r -p "Selecciona (1-${#opts[@]}): " ans
      if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans>=1 && ans<=${#opts[@]} )); then
        REPLY="${opts[$((ans-1))]%%|*}"
        return 0
      fi
      _err "Opción inválida."
    done
  }

  _set_api_base() {
    echo
    _note "API_BASE es la URL donde vive el servidor HTTP de Ollama."
    _note "Ejemplos:"
    echo "  - Local:  http://localhost:${PORT}"
    echo "  - Remoto: http://192.168.1.100:${PORT}"
    echo
    read -r -p "API_BASE actual: ${API_BASE}. Nuevo (Enter para dejar igual): " nb
    if [[ -n "$nb" ]]; then
      API_BASE="$nb"
      export OLLAMA_API_BASE="$API_BASE"
      _ok "OLLAMA_API_BASE actualizado: $OLLAMA_API_BASE"
    else
      _note "Sin cambios."
    fi
  }

  _health() {
    _need curl || return 1
    if curl -sf "$API_BASE/api/tags" >/dev/null; then
      _ok "Ollama responde en $API_BASE"
      return 0
    else
      _err "Ollama NO responde en $API_BASE"
      _note "Si es local, prueba iniciar con: (opción) Iniciar servidor local/LAN"
      return 1
    fi
  }

  _show_tags() {
    _need curl || return 1
    _note "Esto consulta /api/tags, que devuelve los modelos instalados localmente en el servidor."
    curl -s "$API_BASE/api/tags" || return 1
    echo
  }

  _models_clean() {
    _need curl || return 1
    _note "Listado limpio de modelos (solo nombres) desde /api/tags."
    curl -s "$API_BASE/api/tags" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p' | sort -u
  }

  _serve_local() {
    _need ollama || return 1
    _title
    echo "🧩 INICIAR SERVIDOR LOCAL (127.0.0.1:${PORT})"
    _hr
    cat <<EOF
Concepto:
- "ollama serve" levanta el servidor HTTP integrado.
- Por defecto escucha SOLO en localhost (127.0.0.1). Eso significa:
  ✅ Solo accesible desde esta misma máquina.
  ✅ Más seguro por defecto.
  ❌ No lo puede consumir otra máquina de tu red.

Qué hace esta opción:
- Ejecuta Ollama con OLLAMA_HOST=127.0.0.1 (escucha solo local).
- Si el puerto ya está ocupado, normalmente es porque Ollama YA está corriendo
  como servicio (muy común en Linux).
EOF
    echo
    _pause
    OLLAMA_HOST="127.0.0.1" ollama serve 2>&1 | awk '
      /address already in use/ { print "⚠️  Puerto ocupado: probablemente Ollama ya está corriendo (o algo usa 11434)."; exit 0 }
      { print }
    '
  }

  _serve_lan() {
    _need ollama || return 1
    _title
    echo "🌐 INICIAR SERVIDOR EN RED (0.0.0.0:${PORT})"
    _hr
    cat <<EOF
Concepto:
- Poner OLLAMA_HOST=0.0.0.0 hace que Ollama escuche en TODAS las interfaces de red.
- Esto permite:
  ✅ Acceso desde otra máquina en tu LAN (ej: tu laptop, un servidor, un contenedor).
  ✅ Integración con apps externas (web, notebooks, etc.) desde otra IP.
- Pero también implica:
  ⚠️ Riesgo: cualquiera con acceso a tu red podría pegarle al endpoint.
  ✅ Recomendación: abrir el puerto SOLO a tu red local (UFW) o usar VPN / reverse proxy con auth.

Tip:
- Después de levantarlo, prueba desde otra máquina:
  curl http://<TU_IP>:11434/api/tags
EOF
    echo
    _pause
    _warn "Exponiendo a red. Considera firewall."
    OLLAMA_HOST="0.0.0.0" ollama serve 2>&1 | awk '
      /address already in use/ { print "⚠️  Puerto ocupado: probablemente Ollama ya está corriendo (o algo usa 11434)."; exit 0 }
      { print }
    '
  }

  _test_from_other_machine_instructions() {
    local ip; ip="$(_ip_local)"
    _title
    echo "🧪 PROBAR ACCESO DESDE OTRA MÁQUINA"
    _hr
    cat <<EOF
Paso a paso (LAN):
1) Asegúrate de que Ollama esté escuchando en 0.0.0.0 (opción 'Iniciar servidor en red').
2) Ubica la IP local de ESTA máquina (servidor):
   - Detectada: ${ip:-"(no detectada)"}
3) Desde la OTRA máquina, ejecuta:
   curl http://${ip:-<TU_IP>}:${PORT}/api/tags

Interpretación:
- Si responde con JSON y lista de modelos -> ✅ OK
- Si no responde -> revisa:
  - firewall/ufw
  - que realmente esté en 0.0.0.0
  - que ambas máquinas estén en la misma red
EOF
    _pause
  }

  _generate_http() {
    _need curl || return 1
    _title
    echo "✍️ GENERAR TEXTO VÍA HTTP (/api/generate)"
    _hr
    cat <<EOF
Concepto:
- /api/generate es una forma de usar Ollama como "microservicio" desde scripts.
- En vez de 'ollama run', tú mandas un JSON por HTTP con:
  - model: nombre del modelo (ej. llama3.1:8b o tu modelo personalizado)
  - prompt: tu pregunta
  - stream: false (para que devuelva todo de una)

Útil para:
- Automatizaciones (resúmenes, templates, transformaciones)
- Integraciones (web apps, pipelines, cron jobs)
EOF
    echo
    _pause

    # Elegir modelo desde API
    local model
    model="$(_models_clean | head -n 1)"
    echo
    _note "Modelo sugerido (primer modelo del servidor): ${model:-"(no encontrado)"}"
    read -r -p "Modelo a usar (Enter para '${model}'): " m2
    model="${m2:-$model}"
    [[ -n "$model" ]] || { _err "No hay modelo. Revisa /api/tags."; _pause; return 1; }

    echo
    read -r -p "Prompt: " prompt
    [[ -n "$prompt" ]] || { _err "Prompt vacío."; _pause; return 1; }

    local prompt_json="${prompt//\\/\\\\}"
    prompt_json="${prompt_json//\"/\\\"}"

    local payload
    payload="$(cat <<EOF
{
  "model": "$model",
  "prompt": "$prompt_json",
  "stream": false
}
EOF
)"
    echo
    _note "Enviando solicitud a $API_BASE/api/generate ..."
    local out
    out="$(curl -s "$API_BASE/api/generate" -d "$payload")" || { _err "Falló curl"; _pause; return 1; }
    echo
    _hr
    echo "Respuesta (solo texto):"
    _hr
    echo "$out" | sed -n 's/.*"response":"\([^"]*\)".*/\1/p' | sed 's/\\n/\n/g; s/\\"/"/g; s/\\\\/\\/g'
    echo
    _pause
  }

  _systemd_apply_dropin() {
    _need systemctl || return 1
    _title
    echo "🧩 SYSTEMD DROP-IN (Linux) — Configuración persistente"
    _hr
    cat <<EOF
Concepto:
- En Linux, Ollama frecuentemente corre como servicio (ollama.service).
- Si quieres que SIEMPRE arranque con parámetros de servidor (ej. escuchar en 0.0.0.0),
  se recomienda un "drop-in" en systemd.
- Un drop-in es un archivo adicional que modifica variables sin editar el servicio original.

Qué variables tocar (las del texto que compartiste):
- OLLAMA_HOST=0.0.0.0        -> escuchar en todas las interfaces (LAN)
- OLLAMA_ORIGINS=*           -> permite CORS desde cualquier origen (útil web; en prod restringir)
- OLLAMA_MAX_LOADED_MODELS=1 -> cuántos modelos mantiene en memoria al mismo tiempo
- OLLAMA_NUM_PARALLEL=1      -> peticiones simultáneas procesadas
- OLLAMA_MAX_QUEUE=512       -> tamaño de la cola de espera
- OLLAMA_KEEP_ALIVE=600      -> segundos que el modelo se mantiene cargado tras una petición
- OLLAMA_NUM_GPU=1           -> número de GPUs permitidas

IMPORTANTE:
- Exponer 0.0.0.0 sin firewall es riesgoso.
- Para LAN, lo ideal: firewall UFW permitiendo solo tu rango (ej. 192.168.0.0/16).
EOF
    echo
    _pause

    read -r -p "¿Quieres crear/aplicar el drop-in recomendado (requiere sudo)? (y/N): " yn
    [[ "${yn,,}" == "y" ]] || { _note "Cancelado."; _pause; return 0; }

    local dropin_dir="/etc/systemd/system/ollama.service.d"
    local dropin_file="$dropin_dir/10-ollama-lan.conf"

    sudo mkdir -p "$dropin_dir" || { _err "No pude crear $dropin_dir"; _pause; return 1; }

    sudo tee "$dropin_file" >/dev/null <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_ORIGINS=*"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_MAX_QUEUE=512"
Environment="OLLAMA_KEEP_ALIVE=600"
Environment="OLLAMA_NUM_GPU=1"
EOF

    _ok "Drop-in creado: $dropin_file"
    _note "Reiniciando servicio para aplicar cambios..."
    sudo systemctl daemon-reload
    sudo systemctl restart ollama.service
    sudo systemctl status ollama.service --no-pager -l | sed -n '1,14p'
    _pause
  }

  _systemd_edit() {
    _need systemctl || return 1
    _title
    echo "📝 EDITAR SYSTEMD (systemctl edit ollama.service)"
    _hr
    cat <<EOF
Esto abre el editor de systemd para que puedas crear un drop-in manualmente.

Tip:
- Pega el bloque bajo [Service] justo después del comentario:
  '### Anything between here and the comment below will become the contents of the drop-in file.'

Ejemplo (LAN + CORS + límites):
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_ORIGINS=*"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_MAX_QUEUE=512"
Environment="OLLAMA_KEEP_ALIVE=600"
Environment="OLLAMA_NUM_GPU=1"

Luego:
  sudo systemctl restart ollama.service
EOF
    _pause
    sudo systemctl edit ollama.service
    _pause
  }

  _ufw_allow_lan() {
    _need ufw || return 1
    _title
    echo "🧱 FIREWALL UFW — Abrir 11434 SOLO para LAN"
    _hr
    cat <<EOF
Concepto (muy importante):
- Si expones Ollama con OLLAMA_HOST=0.0.0.0, el puerto 11434 queda accesible en red.
- Lo seguro es permitir SOLO tu red local (LAN) y bloquear el resto.

Ejemplos de rangos típicos:
- 192.168.0.0/16
- 10.0.0.0/8
- 172.16.0.0/12

Esta opción crea una regla:
  ufw allow from <CIDR> to any port 11434 proto tcp
EOF
    echo
    read -r -p "Ingresa CIDR permitido (ej 192.168.0.0/16): " cidr
    [[ -n "$cidr" ]] || { _err "CIDR vacío."; _pause; return 1; }
    sudo ufw allow from "$cidr" to any port "$PORT" proto tcp
    _ok "Regla aplicada. Verifica con: sudo ufw status numbered"
    _pause
  }

  _ufw_deny_port() {
    _need ufw || return 1
    _title
    echo "🧱 FIREWALL UFW — Denegar 11434 (global)"
    _hr
    cat <<EOF
Concepto:
- Si abriste el puerto por accidente o quieres cerrarlo, puedes denegar 11434/tcp.
- Ojo: si tienes reglas allow específicas, UFW aplica por orden. Esto es una acción “fuerte”.

Comando:
  sudo ufw deny 11434/tcp
EOF
    _pause
    read -r -p "¿Aplicar deny global a 11434/tcp? (y/N): " yn
    [[ "${yn,,}" == "y" ]] || { _note "Cancelado."; _pause; return 0; }
    sudo ufw deny "$PORT"/tcp
    _ok "Puerto denegado. Verifica con: sudo ufw status numbered"
    _pause
  }

  _show_workspace_info() {
    _title
    echo "📁 WORKSPACE: Modelfiles y conceptos"
    _hr
    cat <<EOF
Tu carpeta de trabajo (workspace) para Modelfiles:
  ${MF_DIR}

Ahí guardas:
- Modelfiles (personalizaciones / recetas)
- scripts de Bash
- todo lo que versionas en Git

Ollama guarda internamente modelos y metadata en:
  ~/.ollama
(esa carpeta no se edita manualmente)

Consejo práctico:
- Versiona ~/ollama/modelfiles en Git.
- En otra máquina, solo necesitas:
    ollama pull <modelo_base>
    ollama create <nuevo> -f <Modelfile>
EOF
    echo
    if [[ -d "$MF_DIR" ]]; then
      _note "Modelfiles detectados:"
      find "$MF_DIR" -maxdepth 1 -type f -name 'Modelfile.*' -printf '  - %f\n' | sort
    else
      _warn "No existe $MF_DIR (créala o genera Modelfiles primero)."
    fi
    _pause
  }

  _show_env_cheatsheet() {
    _title
    echo "🧾 VARIABLES DE ENTORNO (cheat sheet) — qué son y para qué sirven"
    _hr
    cat <<'EOF'
Estas variables se usan para configurar el servidor HTTP de Ollama, especialmente cuando lo expones en red
o quieres controlar consumo de recursos.

1) OLLAMA_HOST
   - Qué controla: en qué IP/Interfaz escucha el servidor.
   - Ejemplos:
     * 127.0.0.1  -> solo local (seguro por defecto)
     * 0.0.0.0    -> todas las interfaces (LAN/containers) ⚠️ requiere firewall
   - Cuándo usar 0.0.0.0:
     * cuando quieras consumir Ollama desde otra máquina o contenedor

2) OLLAMA_ORIGINS
   - Qué controla: desde qué "origin" se aceptan solicitudes (CORS) para apps web.
   - Valor:
     * * -> acepta cualquier origen (fácil para pruebas, menos seguro)
   - Recomendación:
     * en producción, restringir al dominio exacto de tu app web

3) OLLAMA_MAX_LOADED_MODELS
   - Qué controla: cuántos modelos puede mantener cargados al mismo tiempo en RAM/VRAM.
   - Idea:
     * si tienes poca memoria, pon 1 para evitar que se carguen varios y reviente la RAM
   - Trade-off:
     * más bajo -> menos memoria, pero puede recargar modelos más seguido

4) OLLAMA_NUM_PARALLEL
   - Qué controla: cuántas solicitudes puede procesar en paralelo (concurrencia real).
   - Trade-off:
     * más alto -> más throughput, pero más presión de CPU/GPU y memoria

5) OLLAMA_MAX_QUEUE
   - Qué controla: cuántas solicitudes se pueden encolar esperando.
   - Útil:
     * cuando tienes clientes múltiples y prefieres cola en vez de fallar rápido
   - Riesgo:
     * cola demasiado grande -> latencias largas, usuarios “esperando” mucho

6) OLLAMA_KEEP_ALIVE
   - Qué controla: cuánto tiempo (segundos) el modelo permanece cargado tras terminar una petición.
   - Ejemplo:
     * 600 -> 10 minutos “caliente”
   - Trade-off:
     * alto -> respuestas futuras más rápidas
     * bajo -> menos memoria retenida

7) OLLAMA_NUM_GPU
   - Qué controla: cuántas GPUs puede usar el servidor.
   - Caso típico:
     * 1 -> una sola GPU disponible
   - Nota:
     * si no tienes GPU, el modelo correrá en CPU (más lento)
EOF
    _pause
  }

  # -----------------------
  # Menú principal
  # -----------------------
  while true; do
    _title
    echo "API_BASE actual: $API_BASE"
    echo "Workspace Modelfiles: $MF_DIR"
    _hr
    echo "¿Qué quieres hacer?"
    local -a MAIN=(
      "health|✅ Verificar servidor (health check) + tips si falla"
      "tags|📦 Ver modelos instalados (GET /api/tags) — JSON completo"
      "models|📃 Listar modelos (limpio) — nombres desde /api/tags"
      "gen|✍️ Generar texto por HTTP (POST /api/generate) — sin usar 'ollama run'"
      "setbase|🔧 Cambiar API_BASE (apuntar a local o remoto)"
      "serve_local|🖥️ Iniciar servidor local (127.0.0.1) — seguro por defecto"
      "serve_lan|🌐 Iniciar servidor en red (0.0.0.0) — accesible desde LAN ⚠️"
      "test_lan|🧪 Guía para probar acceso desde otra máquina (curl a tu IP)"
      "env_help|🧾 Explicación generosa de variables (OLLAMA_HOST, ORIGINS, etc.)"
      "systemd_quick|🧩 Aplicar drop-in systemd recomendado (LAN + límites) (Linux)"
      "systemd_edit|📝 Abrir editor systemd (systemctl edit ollama.service) (Linux)"
      "ufw_allow|🧱 UFW: permitir 11434 SOLO para tu LAN (CIDR)"
      "ufw_deny|🧱 UFW: denegar 11434 global (cerrar puerto)"
      "workspace|📁 Ver info de workspace (~/ollama/modelfiles) + listado"
      "exit|Salir"
    )

    _menu "Menú principal:" MAIN
    case "$REPLY" in
      health) _health; _pause ;;
      tags) _show_tags; _pause ;;
      models) _models_clean; echo; _pause ;;
      gen) _generate_http ;;
      setbase) _set_api_base; _pause ;;
      serve_local) _serve_local ;;
      serve_lan) _serve_lan ;;
      test_lan) _test_from_other_machine_instructions ;;
      env_help) _show_env_cheatsheet ;;
      systemd_quick) _systemd_apply_dropin ;;
      systemd_edit) _systemd_edit ;;
      ufw_allow) _ufw_allow_lan ;;
      ufw_deny) _ufw_deny_port ;;
      workspace) _show_workspace_info ;;
      exit) _ok "Listo."; return 0 ;;
      *) _err "Opción desconocida."; _pause ;;
    esac
  done
}


