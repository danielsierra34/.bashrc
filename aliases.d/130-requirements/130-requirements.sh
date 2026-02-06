########################################################################################## REQUIREMENTS

requirements_install() {
    REQ_FILE=${1:-"requirements.txt"}  # Usa requirements.txt por defecto si no se pasa nada

    echo "📦 Instalando dependencias desde $REQ_FILE..."
    pip install --upgrade pip
    pip install -r "$REQ_FILE"
    echo "✅ Dependencias instaladas desde $REQ_FILE."
}

requirements_generate() {
    echo "📄 Generando requirements.txt..."
    pip freeze > requirements.txt
    echo "✅ requirements.txt actualizado."
}


