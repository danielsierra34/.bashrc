# 600-ollama

Flujo completo para instalar Ollama, descargar modelos recomendados y crear variantes personalizadas.

## Funciones destacadas
- ollama_install: instala zstd y ejecuta el script oficial de Ollama.
- ollama_pull: menú interactivo con un catálogo curado de modelos para ejecutar ollama pull sin memorizar nombres.
- ollama_modelfile_generate: guía paso a paso para generar Modelfiles (rol, parámetros, contexto, etc.).
- ollama_model_generate: combina un modelo base local con un Modelfile existente y crea un modelo nuevo listo para ollama run.
- ollama_assistant: panel interactivo que expone/oculta el servicio Ollama, abre puertos en la LAN, muestra los modelos cargados y publica instrucciones HTTP para clientes externos.

El resto de funciones con prefijo _ son utilidades internas que soportan los menús, helpers de firewall (ufw) y plantillas HTTP. No necesitas invocarlas manualmente.
