# 216-codex-plugins

Herramientas para manejar marketplaces e instalar plugins de Codex desde Bash.

## Funciones
- `codex_plugin_marketplace_add_source <fuente>`: agrega un marketplace local o remoto.
- `codex_plugin_marketplace_list_sources`: lista los marketplaces configurados.
- `codex_plugin_marketplace_upgrade_sources [marketplace-name]`: refresca marketplaces.
- `codex_plugin_marketplace_remove_source <marketplace-name>`: elimina un marketplace.
- `codex_plugin_install_named "Plugin Name"`: instala un plugin por nombre.
- `codex_plugin_install_system <system-key>`: instala un plugin usando una clave corta.
- `codex_plugin_install_systems <system-key> [system-key ...]`: instala varios plugins.
- `codex_plugin_list_installed`: lista plugins instalados.
- `codex_plugin_list_available`: lista plugins disponibles con JSON.
- `codex_plugin_remove_installed <plugin[@marketplace]>`: elimina un plugin instalado.
- `codex_plugin_systems`: muestra las claves soportadas.
- `codex_plugin_bootstrap`: valida que `codex` exista y muestra los marketplaces visibles.

## Flujo recomendado
1. Agregar un marketplace con `codex_plugin_marketplace_add_source`.
2. Verificarlo con `codex_plugin_marketplace_list_sources`.
3. Instalar uno o varios plugins con `codex_plugin_install_system`.
4. Revisar lo instalado con `codex_plugin_list_installed`.

## Notas
- La instalacion de plugins usa el CLI oficial de Codex.
- Los nombres de sistema son alias cortos que se traducen a los nombres visibles en el catalogo.
