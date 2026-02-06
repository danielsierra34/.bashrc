# 500-cypress

Scripts auxiliares para preparar Cypress y ejecutar suites específicas.

## Funciones
- cypress_install: instala Cypress globalmente con npm.
- cypress_open: abre la app interactiva.
- cypress_run_headed <carpeta|all> <archivo|all>: ejecuta specs en modo headed según la combinación indicada.
- cypress_run_headless <carpeta|all> <archivo|all>: equivalente en modo headless.
- agregar_x / quitar_x: renombran archivos del directorio actual agregando o quitando la extensión .x (para habilitar/deshabilitar specs masivamente).
- saludar: comando de prueba que imprime un saludo.
