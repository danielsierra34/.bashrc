# Obsidian

Funciones para instalar y administrar Obsidian como aplicacion de escritorio.

En WSL Debian, Obsidian se instala globalmente en Windows usando `winget`. Esto
es lo recomendado porque WSL es el entorno de terminal y Obsidian es la
aplicacion grafica del sistema anfitrion.

## Funciones

- `obsidian_help`: muestra la ayuda del modulo.
- `obsidian_check`: comprueba si Obsidian esta instalado.
- `obsidian_install`: instala Obsidian globalmente.
- `obsidian_update`: actualiza Obsidian.
- `obsidian_uninstall`: desinstala Obsidian.
- `obsidian_open [ruta|.]`: abre Obsidian, opcionalmente con una ruta de vault.

## Uso en WSL Debian

```bash
source ~/bashrc/aliases
obsidian_check
obsidian_install
obsidian_open .
obsidian_update
```

Requiere `winget` disponible en Windows y la interoperabilidad WSL habilitada.

Variables opcionales:

- `OBSIDIAN_WINGET_ID`: identificador de winget; por defecto `Obsidian.Obsidian`.
- `OBSIDIAN_LINUX_PACKAGE`: identificador Flatpak; por defecto
  `com.obsidian.Obsidian`.
