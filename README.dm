# Bashrc Toolkit

Colección modular de alias y funciones para tu terminal Bash. Cada grupo vive en su propia carpeta dentro de `aliases.d/` e incluye un README con la descripción de comandos disponibles.

## Instalación rápida
1. **Clona o copia** este directorio en `~/bashrc` (puedes usar cualquier ruta siempre que ajustes los paths).
2. **Agrega el loader** a `~/.bashrc`:
   ```bash
   if [ -f ~/bashrc/aliases ]; then
       source ~/bashrc/aliases
   fi
   ```
3. **Recarga** la shell con `source ~/.bashrc` o abre una nueva terminal para que todo quede disponible.

> Consejo: Si usas Git para versionar este toolkit, mantén `~/bashrc` como repositorio independiente y haz `git pull` periódicamente.

## Estructura de carpetas
- `aliases`: script que recorre recursivamente `aliases.d/**/*.sh` y los carga.
- `aliases.d/000-core/`: utilidades generales (git, Flask, arbolado, llaves SSH, watchers, etc.).
- `aliases.d/100-python/`: instalación/configuración de pyenv, virtualenvs y limpieza de cachés.
- `aliases.d/110-uvicorn/`: wrapper para ejecutar Uvicorn indicando host, puerto y workers.
- `aliases.d/120-fastapi/`: instala FastAPI + Uvicorn dentro del entorno virtual activo.
- `aliases.d/130-requirements/`: genera o instala archivos `requirements*.txt`.
- `aliases.d/200-npm/`: helpers para npm/npx (listar, instalar o desinstalar paquetes).
- `aliases.d/210-git/`: comandos rápidos para definir `user.name` y `user.email`.
- `aliases.d/300-docker/`: gestión de redes, contenedores, imágenes y limpiezas de Docker.
- `aliases.d/400-ghost/`: scripts específicos para Ghost + pipelines de pruebas end-to-end.
- `aliases.d/410-kraken/`: instalación y ejecución de `kraken-node` y Chromedriver.
- `aliases.d/500-cypress/`: instalación y ejecución de suites Cypress (headed/headless).
- `aliases.d/600-ollama/`: instalación de Ollama, descarga guiada de modelos y creación de Modelfiles personalizados.
- `aliases.d/700-arduino/`: asistente para Arduino CLI y conexión de placas USB desde WSL.
- `aliases.d/900-misc/`: alias misceláneos (venv, Bitnami, recarga de bashrc).
- `list_funcs.py`: script que imprime el inventario de funciones/alias detectados en cada módulo.

Cada carpeta tiene un `README.md` con más detalles del módulo correspondiente. Lee esos archivos para conocer argumentos, requisitos extra o advertencias.

## Cómo usar los alias y funciones
- **Funciones**: se llaman como cualquier comando (`fastpush "mensaje"`, `docker_c_run 80 8080 imagen contenedor`).
- **Alias**: basta escribir su nombre (`venv_activar`, `iadnode_connect`, `bashrc`).
- **Recarga manual**: cuando edites algún archivo en `aliases.d`, ejecuta `source ~/bashrc/aliases` para cargar los cambios sin cerrar tu sesión.

## Scripts auxiliares
- `python list_funcs.py`: lista funciones y alias detectados por archivo. Útil para hacer auditorías rápidas.
- Cualquier módulo nuevo puede copiar la estructura actual (directorio + README + script `.sh`). Basta con guardarlo como `NNN-nombre/nombre.sh`; el loader lo encontrará automáticamente.
