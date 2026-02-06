# 700-arduino

Asistente para instalar Arduino CLI, configurar placas comunes y exponer dispositivos USB desde Windows/WSL.

## Funciones
- arduino_install: instala arduino-cli según el sistema, configura cores para AVR, ESP32 o ESP8266 y muestra los comandos básicos para compilar/subir.
- ardu: ejecuta ~/bin/ardu-wsl.sh para adjuntar dispositivos USB en WSL (valida que estés dentro de WSL).
- arduino_run: flujo interactivo que detecta placas, usa usbipd-win mediante PowerShell, adjunta el dispositivo al WSL y ejecuta compilación/subida/monitorización guiada.

Las funciones internas (_ok, _usb_list, _choose_board, etc.) solo se usan dentro de rduino_run y documentan cada paso del asistente.
