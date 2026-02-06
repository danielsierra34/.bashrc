# 110-uvicorn

Runner simplificado para exponer aplicaciones ASGI/ FastAPI durante el desarrollo.

## Funciones
- uvicorn_run [paquete] [host] [puerto] [workers] [flag_reload]: construye "paquete.main:app" automáticamente y ejecuta Uvicorn con los parámetros indicados (o valores por defecto 127.0.0.1:8000, 1 worker y --reload).
