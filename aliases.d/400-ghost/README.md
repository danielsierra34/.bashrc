# 400-ghost

Herramientas específicas para entornos Ghost autoalojados y sus pruebas end-to-end.

## Funciones principales
- ghost_terminal: abre una shell dentro del contenedor ghost activo.
- install_jq_in_container: instala jq dentro del contenedor Ghost para manipular configuraciones.
- replace_mail_config <ruta_config>: reescribe la sección de correo usando credenciales de Mailgun.
- ghost_run <version>: recrea el contenedor Ghost, limpia volúmenes y publica la versión indicada en http://localhost:2368.
- cypress_run <version>: ejecuta el workspace e2e/misw-4103-cypress, reorganiza pantallazos y limpia carpetas vacías.
- kraken_run: dispara las pruebas Kraken del workspace e2e/misw-4103-kraken.

Las credenciales Mailgun se definen al inicio del script; ajústalas antes de usarlo en otro entorno.
