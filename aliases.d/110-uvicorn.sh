########################################################################################## UVICORN
uvicorn_run() {
  PACKAGE=${1:-"storeapi"}       # Nombre del paquete (implícitamente usa main:app)
  HOST=${2:-"127.0.0.1"}         # Host por defecto
  PORT=${3:-8000}                # Puerto por defecto
  WORKERS=${4:-1}                # Número de workers por defecto
  RELOAD=${5:-"--reload"}        # Por defecto en modo desarrollo

  APP="$PACKAGE.main:app"        # Construcción implícita

  echo "🚀 Iniciando Uvicorn con APP=$APP en $HOST:$PORT con $WORKERS worker(s) $RELOAD"
  uvicorn $APP --host $HOST --port $PORT --workers $WORKERS $RELOAD
}

