# 200-npm

Colección de auxiliares para instalar, listar y eliminar paquetes NPM/Npx en contextos globales o locales.

## Funciones
- npm_list: muestra los paquetes globales (
pm list -g --depth=0).
- npm_install <paquete> / npm_uninstall <paquete>: gestiona paquetes globales con sudo.
- npx_list: lista dependencias locales del proyecto actual.
- npx_install <paquete> / npx_uninstall <paquete>: instala o elimina dependencias locales dentro de la carpeta actual.
