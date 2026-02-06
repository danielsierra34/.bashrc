# 700-arduino

Asistente para instalar Arduino CLI, configurar placas comunes y exponer dispositivos USB desde Windows/WSL.

## Funciones
- arduino_install: instala arduino-cli según el sistema, configura cores para AVR, ESP32 o ESP8266 y muestra los comandos básicos para compilar/subir.
- ardu: ejecuta ~/bin/ardu-wsl.sh para adjuntar dispositivos USB en WSL (valida que estés dentro de WSL).
- arduino_run: menú minimalista con tres opciones (compilar, upload, monitor) que reutiliza los alias simples descritos abajo; ideal cuando ya tienes la placa conectada y solo quieres esas acciones rápidas.

### Alias simples
- compilar: lista las carpetas que contienen archivos `.ino` (buscando desde el directorio actual) y compila la que elijas con el FQBN guardado, el detectado automáticamente (si `arduino-cli board list` encuentra una única placa) o el que definas manualmente. También admite `compilar /ruta/al/proyecto` para saltar la selección.
- upload: pregunta qué archivo `.ino` quieres subir, detecta la única placa conectada (o la definida en `ARDUINO_PORT`) y ejecuta `arduino-cli upload` sobre ese sketch.
- monitor: abre `arduino-cli monitor` contra la placa detectada (o `ARDUINO_PORT`) usando 115200 baudios por defecto; puedes pasar otro baudrate como primer argumento.

Las funciones internas del módulo quedaron en los alias simples, por lo que arduino_run actúa como wrapper interactivo cuando prefieres usar un menú en lugar de comandos individuales.
