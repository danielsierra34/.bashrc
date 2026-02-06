# 100-python

Automatiza la instalación de pyenv, la creación de entornos y la configuración de proyectos Python.

## Funciones principales
- pyenv_install: instala pyenv y agrega los bloques necesarios en ~/.bashrc.
- pyenv_local <version>: instala (si hace falta) y fija la versión local de Python con pyenv.
- pyenv_version: muestra la versión activa que expone pyenv.
- pyenv_venv <nombre>: crea un entorno virtual con pyenv en .<nombre>.
- pyenv_activate_venv <nombre>: activa el entorno generado con pyenv_venv.
- pyenv_gitignore: genera un .gitignore completo orientado a proyectos Python.
- pyenv_create_settings: crea .vscode/settings.json con auto-format y organize imports.

## Limpieza
- pycache_delete: elimina __pycache__ y binarios compilados en el árbol actual.
- pytestcache_delete: borra .pytest_cache y otros artefactos de pruebas.
