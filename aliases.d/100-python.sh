########################################################################################## PYTHON
pyenv_install() {
    echo "🔧 Actualizando paquetes..."
    sudo apt update -y

    echo "📦 Instalando dependencias..."
    sudo apt install -y make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncurses5-dev libncursesw5-dev xz-utils tk-dev \
        libffi-dev liblzma-dev git

    echo "⬇️ Instalando pyenv..."
    curl https://pyenv.run | bash

    echo "⚙️ Configurando variables en ~/.bashrc..."
    if ! grep -q 'pyenv init' ~/.bashrc; then
        cat <<'EOF' >> ~/.bashrc

# >>> pyenv configuration >>>
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# <<< pyenv configuration <<<
EOF
    fi

    echo "🔄 Recargando configuración..."
    source ~/.bashrc

    echo "✅ Instalación completada. Versión de pyenv:"
    pyenv --version
}

pyenv_local() {
  local version=$1
  if [ -z "$version" ]; then
    echo "❌ Debes pasar una versión. Ejemplo: set_pyenv_local 3.11.9"
    return 1
  fi

  # Verificar si ya está instalada
  if ! pyenv versions --bare | grep -q "^${version}\$"; then
    echo "🔍 Python $version no está instalado. Instalando..."
    pyenv install "$version"
  else
    echo "✅ Python $version ya está instalado."
  fi

  # Configurar como local
  pyenv local "$version"
  echo "📌 Se configuró Python $version como versión local en $(pwd)"
}

pyenv_version() {
  if ! command -v pyenv >/dev/null 2>&1; then
    echo "❌ pyenv no está instalado o no está en el PATH."
    return 1
  fi

  echo "🐍 Versión activa de Python con pyenv:"
  pyenv exec python -V
}

pyenv_venv() {
    if [ -z "$1" ]; then
        echo "❌ Debes pasar el nombre del environment como parámetro"
        echo "👉 Ejemplo: make_env myproject"
        return 1
    fi

    ENV_NAME="$1"
    ENV_DIR=".$ENV_NAME"

    echo "🚀 Creando environment en $ENV_DIR ..."
    pyenv exec python -m venv "$ENV_DIR"

    echo "✅ Environment creado: $ENV_DIR"
    echo "👉 Actívalo con: source $ENV_DIR/bin/activate"
}

pyenv_activate_venv() {
    if [ -z "$1" ]; then
        echo "❌ Debes pasar el nombre del environment como parámetro"
        echo "👉 Ejemplo: activate_env venv"
        return 1
    fi

    ENV_NAME="$1"
    ENV_DIR=".$ENV_NAME"

    if [ ! -d "$ENV_DIR" ]; then
        echo "❌ El environment $ENV_DIR no existe."
        echo "👉 Primero créalo con: make_env $ENV_NAME"
        return 1
    fi

    echo "⚡ Activando environment: $ENV_DIR ..."
    source "$ENV_DIR/bin/activate"
}

pyenv_gitignore() {
  local file=".gitignore"

  cat > "$file" <<EOF
# ========================
# Archivos Python compilados
# ========================
*.pyc
*.pyo
*.pyd
__pycache__/

# ========================
# Entornos virtuales
# ========================
.env
.venv/
env/
venv/
ENV/

# ========================
# Bases de datos
# ========================
*.db
*.sqlite3

# ========================
# Archivos de pruebas
# ========================
.coverage
coverage.xml
*.cover
*.py,cover
.pytest_cache/
htmlcov/
.tox/
.nox/

# ========================
# Distribución / empaquetado
# ========================
build/
dist/
*.egg-info/
.eggs/

# ========================
# Logs
# ========================
*.log

# ========================
# IDEs / Editores
# ========================
.vscode/
.idea/

# ========================
# Archivos del sistema
# ========================
.DS_Store
Thumbs.db

# ========================
# Imágenes y binarios
# ========================
*.png
*.jpg
*.jpeg
*.gif
*.svg
*.ico

# ========================
# Otros
# ========================
*.bak
*.tmp
EOF

  echo "✅ Archivo $file sobrescrito en $(pwd)"
}

pyenv_create_settings() {
    CONFIG_DIR=".vscode"
    CONFIG_FILE="$CONFIG_DIR/settings.json"

    # Crear carpeta .vscode si no existe
    mkdir -p "$CONFIG_DIR"

    # Crear archivo settings.json con la configuración
    cat > "$CONFIG_FILE" <<EOL
{
    "[python]": {
        "editor.codeActionsOnSave": {
            "source.organizeImports": "explicit",
            "source.fixAll": "explicit"
        }
    },
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "charliermarsh.ruff"
}
EOL

    echo "✅ Archivo de configuración creado en $CONFIG_FILE"
}

pycache_delete(){
    find . -type d -name "__pycache__" -exec rm -r {} +
}

pytestcache_delete(){
    find . -type d -name ".pytest_cache" -exec rm -r {} +
}

