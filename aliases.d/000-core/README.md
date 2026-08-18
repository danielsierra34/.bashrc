# 000-core

Utilidades esenciales para depurar proyectos locales, automatizar tareas de Git y administrar sesiones SSH.

## Funciones principales
- fastpush "mensaje": hace git add, git commit y git push en un solo paso.
- linux_version: muestra el contenido de /etc/os-release para saber la distro.
- nano_install: instala el editor nano via apt.
- ssh_zip carpeta: comprime directorios antes de transferirlos.
- python_serve: levanta un servidor HTTP simple en el puerto 8000.
- flask_run / flask_restart: ejecutan y reinician apps Flask limpiando bases locales.
- bashrc_refresh: `bashrc_refresh remote` hace git pull + recarga, `bashrc_refresh local` solo vuelve a ejecutar `~/.bashrc`.
- test_all: dispara python -m unittest discover en el proyecto activo.
- watchdog / watchdog_always: usan watchmedo para correr pruebas al detectar cambios.
- port_check puerto y port_kill pid: inspeccionan puertos ocupados y cierran procesos.
- port_free puerto [--yes]: detecta procesos en escucha y los termina con confirmacion.
- ssh_iniciar, ssh_generar nombre, ssh_activar clave: flujo completo para llaves SSH.
- tree_list / tree_install: instalan tree y listan carpetas excluyendo artefactos.
- repo_sanity: resume rama, remoto, suciedad del arbol y presencia de .codex.
- env_doctor: comprueba binarios base del toolkit y reporta faltantes.

## Alias
- iadnode_connect: abre una sesión SSH preconfigurada contra el servidor Ghost.
