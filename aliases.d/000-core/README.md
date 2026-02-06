# 000-core

Utilidades esenciales para depurar proyectos locales, automatizar tareas de Git y administrar sesiones SSH.

## Funciones principales
- fastpush "mensaje": hace git add, git commit y git push en un solo paso.
- linux_version: muestra el contenido de /etc/os-release para saber la distro.
- nano_install: instala el editor nano via apt.
- ssh_zip carpeta: comprime directorios antes de transferirlos.
- python_serve: levanta un servidor HTTP simple en el puerto 8000.
- flask_run / flask_restart: ejecutan y reinician apps Flask limpiando bases locales.
- bashrc_refresh: actualiza este repositorio y recarga ~/.bashrc.
- test_all: dispara python -m unittest discover en el proyecto activo.
- watchdog / watchdog_always: usan watchmedo para correr pruebas al detectar cambios.
- port_check puerto y port_kill pid: inspeccionan puertos ocupados y cierran procesos.
- ssh_iniciar, ssh_generar nombre, ssh_activar clave: flujo completo para llaves SSH.
- tree_list / tree_install: instalan tree y listan carpetas excluyendo artefactos.

## Alias
- iadnode_connect: abre una sesión SSH preconfigurada contra el servidor Ghost.
