########################################################################################## FASTAPI

fastapi_install() {
    if [ -z "$VIRTUAL_ENV" ]; then
        echo "⚠️ No hay ningún entorno virtual activado."
        echo "👉 Primero activa tu venv con: source .venv/bin/activate"
        return 1
    fi

    echo "📦 Instalando FastAPI y Uvicorn en $VIRTUAL_ENV..."
    pip install --upgrade pip
    pip install fastapi uvicorn

    echo "🎉 FastAPI y Uvicorn instalados correctamente"
}

