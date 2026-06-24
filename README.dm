# Bashrc Toolkit

Coleccion modular de alias y funciones para tu terminal Bash. Cada grupo vive en su propia carpeta dentro de `aliases.d/` e incluye un README con la descripcion de comandos disponibles.

## Instalacion rapida
1. Clona o copia este directorio en `~/bashrc`.
2. Agrega el loader a `~/.bashrc`:
   ```bash
   if [ -f ~/bashrc/aliases ]; then
       source ~/bashrc/aliases
   fi
   ```
3. Recarga la shell con `source ~/.bashrc` o abre una nueva terminal.

> Consejo: si usas Git para versionar este toolkit, manten `~/bashrc` como repositorio independiente y haz `git pull` periodicamente.

## Estructura de carpetas
- `aliases`: script que recorre recursivamente `aliases.d/**/*.sh` y los carga.
- `aliases.d/000-core/`: utilidades generales (git, Flask, arbolado, llaves SSH, watchers, etc.).
- `aliases.d/100-python/`: instalacion/configuracion de pyenv, virtualenvs y limpieza de caches.
- `aliases.d/110-uvicorn/`: wrapper para ejecutar Uvicorn indicando host, puerto y workers.
- `aliases.d/120-fastapi/`: instala FastAPI + Uvicorn dentro del entorno virtual activo.
- `aliases.d/130-requirements/`: genera o instala archivos `requirements*.txt`.
- `aliases.d/200-npm/`: helpers para npm/npx (listar, instalar o desinstalar paquetes).
- `aliases.d/210-git/`: comandos rapidos para definir `user.name` y `user.email`.
- `aliases.d/300-docker/`: gestion de redes, contenedores, imagenes y limpiezas de Docker.
- `aliases.d/400-ghost/`: scripts especificos para Ghost + pipelines de pruebas end-to-end.
- `aliases.d/410-kraken/`: instalacion y ejecucion de `kraken-node` y Chromedriver.
- `aliases.d/500-cypress/`: instalacion y ejecucion de suites Cypress (headed/headless).
- `aliases.d/600-ollama/`: instalacion de Ollama, descarga guiada de modelos y creacion de Modelfiles personalizados.
- `aliases.d/700-arduino/`: asistente para Arduino CLI y conexion de placas USB desde WSL.
- `aliases.d/850-codex/`: wrappers para `codex` con contexto local, historial y arranque de workspaces.
- `aliases.d/860-knowledge/`: scaffolding para bases de conocimiento versionables en Markdown.
- `aliases.d/900-misc/`: alias miscelaneos (venv, Bitnami, recarga de bashrc).
- `list_funcs.py`: script que imprime el inventario de funciones/alias detectados en cada modulo.

Cada carpeta tiene un `README.md` con mas detalles del modulo correspondiente.

## Como usar los alias y funciones
- Funciones: se llaman como cualquier comando (`fastpush "mensaje"`, `docker_c_run 80 8080 imagen contenedor`).
- Alias: basta escribir su nombre (`venv_activar`, `iadnode_connect`, `bashrc`).
- Recarga manual: cuando edites algun archivo en `aliases.d`, ejecuta `source ~/bashrc/aliases`.

## Codex CLI

El modulo `850-codex` te deja usar Codex como una herramienta de trabajo persistente dentro del repo:

```bash
source ~/bashrc/aliases
codex_new ~/work/proyecto "Migrar a arquitectura modular"
cd ~/work/proyecto
codex_chat "Ajustar flujo inicial"
codex_save "cierre de sesion"
codex_ls
codex_open context
codex_sync
```

Comandos clave:
- `codex_new <ruta> [objetivo]`: crea un workspace nuevo y lo prepara.
- `codex_bootstrap [objetivo]`: inicializa `.codex/` y deja un baseline listo.
- `codex_chat [titulo]`: abre una sesion trazable y guarda resumen final.
- `codex_save [titulo]`: guarda un snapshot de resumen.
- `codex_ls`: lista historial, notas y artefactos recientes.
- `codex_open [context|state|latest|session|ruta]`: abre el archivo local que necesites.
- `codex_sync [snapshot]`: regenera `context.md` y `state.json` desde un snapshot.

Flujo recomendado:
1. `codex_new` para crear el espacio de trabajo.
2. `codex_chat` para trabajar con trazabilidad.
3. `codex_save` al cerrar una sesion intermedia.
4. `codex_ls` y `codex_open` para revisar estado.
5. `codex_sync` si necesitas reconstruir el contexto desde historial.

## Scripts auxiliares
- `python list_funcs.py`: lista funciones y alias detectados por archivo.
- Cualquier modulo nuevo puede copiar la estructura actual (directorio + README + script `.sh`). Basta con guardarlo como `NNN-nombre/nombre.sh`; el loader lo encontrara automaticamente.
