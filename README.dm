# Bashrc Toolkit

Este directorio (`~/bashrc`) agrupa todos tus alias y funciones de shell.
Para que estén disponibles en todas tus terminales:

```bash
# ~/.bashrc
if [ -f ~/bashrc/aliases ]; then
    source ~/bashrc/aliases
fi
```

1. Edita `~/.bashrc`, pega el bloque anterior y guarda.
2. Ejecuta `source ~/.bashrc` (o abre una terminal nueva) para cargar el
   loader.

El archivo `aliases` se encarga de cargar **automáticamente** cada script
de `aliases.d/*.sh`, por lo que solo necesitas mantener este directorio
actualizado.

## Cómo ejecutar los scripts

- Cada función se invoca escribiendo su nombre como si fuera un comando:
  `fastpush "mensaje"`, `docker_c_run imagen` o `arduino_install`.
- Las entradas declaradas con `alias` se ejecutan igual que cualquier
  comando clásico: `venv_activar`, `bashrc`, etc.
- Si el script espera argumentos, revísalos en la tabla de referencia
  siguiente o abre el archivo correspondiente en `aliases.d`.

## Referencia de scripts (`aliases.d`)

| Archivo | Contexto principal | Funciones / aliases destacados |
| --- | --- | --- |
| `000-core.sh` | Utilidades base | `fastpush`, `watchdog`, `ssh_generar`, `tree_list`, alias `iadnode_connect` |
| `100-python.sh` | Gestión de Python/pyenv | `pyenv_install`, `pyenv_local`, `pyenv_venv`, `pycache_delete` |
| `110-uvicorn.sh` | Servidor ASGI | `uvicorn_run host puerto modulo` |
| `120-fastapi.sh` | Dependencias FastAPI | `fastapi_install` (usa pip/poetry según el proyecto) |
| `130-requirements.sh` | Requirements files | `requirements_install`, `requirements_generate` |
| `200-npm.sh` | Node/NPM/NPX | `npm_install paquete`, `npx_install herramienta`, listados y uninstall |
| `210-git.sh` | Configuración Git | `git_email correo`, `git_name nombre` |
| `300-docker.sh` | Docker & Compose | `docker_c_run`, `docker_c_enter`, `docker_i_build`, `docker_networks_create`, `docker_clean`, etc. |
| `400-ghost.sh` | Stack Ghost | `ghost_terminal`, `ghost_run`, `cypress_run`, `kraken_run`, helpers de configuración |
| `410-kraken.sh` | Proyecto Kraken | `kraken_install`, `kraken_run`, `kraken_reports_clear`, `chromium_listen` |
| `500-cypress.sh` | Automatización Cypress | `cypress_install`, `cypress_run_headed`, `cypress_run_headless`, utilidades `agregar_x`/`quitar_x` |
| `600-ollama.sh` | Ollama/LLM tooling | `ollama_install`, `ollama_pull`, `ollama_modelfile_generate`, además de menús interactivos para exponer el servidor y gestionar Modelfiles |
| `700-arduino.sh` | Arduino + WSL | `arduino_install`, `ardu`, `arduino_run` (incluye asistente para USB/IP) |
| `900-misc.sh` | Alias varios | `venv_iniciar`, `venv_activar`, `bitnami_reiniciar`, `bashrc`, etc. |

### Consejos rápidos

- **Buscar ayuda puntual:** abre el archivo correspondiente en tu editor
  (`aliases.d/300-docker.sh`) para ver comentarios y más ejemplos.
- **Actualizar scripts:** cualquier nuevo módulo puede guardarse como
  `NNN-nombre.sh`. El loader los importará automáticamente si tienen
  permisos de lectura.
- **Depurar:** ejecuta `source ~/bashrc/aliases` para recargar después de
  cada cambio.

Con este README tienes tanto el instructivo de enlace en `.bashrc` como
la guía para ejecutar cada script agrupado por contexto.
