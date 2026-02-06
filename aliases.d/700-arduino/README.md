# 700-arduino

Asistente para instalar Arduino CLI, configurar placas comunes y exponer dispositivos USB desde Windows/WSL.

## Funciones
- arduino_install: instala arduino-cli según el sistema, configura cores para AVR, ESP32 o ESP8266 y muestra los comandos básicos para compilar/subir.
- ardu: ejecuta ~/bin/ardu-wsl.sh para adjuntar dispositivos USB en WSL (valida que estés dentro de WSL).
- arduino_help: asistente que asume una estructura `ino/<proyecto>/<proyecto>.ino` (puedes cambiar la raíz con `ARDUINO_INO_ROOT`). Detecta automáticamente el BUSID con `usbipd list`, adjunta la placa, muestra los proyectos disponibles y te deja compilar, subir o abrir el monitor serie usando la placa ya detectada.

### Alias simples
- compilar: lista las carpetas que contienen un `.ino` cuyo nombre coincide con la carpeta (por ejemplo `proyecto/proyecto.ino`). Compila la que elijas con el FQBN guardado, el detectado automáticamente (si `arduino-cli board list` encuentra una única placa) o el que definas manualmente. También admite `compilar /ruta/al/proyecto` para saltar la selección.
- upload: usa la misma carpeta (nombre de archivo = nombre de carpeta), detecta la única placa conectada (o `ARDUINO_PORT`) y ejecuta `arduino-cli upload` sin pedirte el sketch explícitamente.

Estos alias/funciones intentan automáticamente:
1. Adjuntar la placa a WSL usando `usbipd attach --wsl --busid …` a través de `powershell.exe`. El BUSID se detecta con `usbipd list`, se cachea en `~/.arduino-helper-busid` y puedes sobreescribirlo con `export ARDUINO_USB_BUSID=2-6`.
2. Detectar el puerto `/dev/ttyUSB*` y el FQBN con `arduino-cli board list --format json`. Cuando solo hay una placa, el FQBN se guarda en `~/.arduino-helper-fqbn` para usos futuros.
- monitor: abre `arduino-cli monitor` contra la placa detectada (o `ARDUINO_PORT`) usando 115200 baudios por defecto; puedes pasar otro baudrate como primer argumento.

Las funciones internas del módulo quedaron en los alias simples, por lo que arduino_run actúa como wrapper interactivo cuando prefieres usar un menú en lugar de comandos individuales.
