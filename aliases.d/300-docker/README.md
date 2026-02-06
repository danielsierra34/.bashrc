# 300-docker

Utilidades para gestionar redes, contenedores e imágenes Docker durante el desarrollo.

## Redes
- docker_networks: lista redes disponibles.
- docker_networks_create <nombre>: crea redes bridge si no existen.
- docker_networks_delete <nombre|all>: elimina redes vacías o todas las definidas por el usuario.

## Contenedores
- docker_c: muestra contenedores (docker ps -a).
- docker_c_run[...]: variantes para ejecutar contenedores simples, persistentes o dentro de una red personalizada.
- docker_c_start|stop|restart <id|all>: controla estados de múltiples contenedores.
- docker_c_delete <id|all>: elimina contenedores detenidos.
- docker_c_logs <id>: sigue logs en vivo.
- docker_c_enter <id>: abre una shell dentro del contenedor.

## Imágenes y Compose
- docker_i: lista imágenes locales.
- docker_i_build <nombre>: construye usando la carpeta actual.
- docker_i_delete[ _forced ] <id|all>: limpia imágenes (con o sin --force).
- docker_i_compose[ _forced ]: wrappers para docker compose up con/sin recrear recursos.
- docker_i_pull <imagen>: descarga imágenes remotas.

## Limpieza general
- docker_restart: fuerza docker compose build --no-cache y docker compose up.
- docker_install: instala Docker Engine mediante apt (ver script para detalles).
- docker_clean: elimina contenedores parados, imágenes dangling y redes huérfanas.
