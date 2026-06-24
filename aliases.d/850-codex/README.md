# 850-codex

Wrappers para abrir `codex` desde cualquier carpeta, inicializar contexto local por repo y guardar snapshots en `.codex/`.

## Funciones principales
- `codex_here`: abre `codex` en el directorio actual.
- `codex_root`: abre `codex` en la raiz del repo Git o en `pwd` si no hay repo.
- `codex_go <ruta> [args...]`: entra a una carpeta y ejecuta `codex` ahi.
- `codex_init`: crea la estructura `.codex/` del repo.
- `codex_save [titulo]`: guarda un snapshot Markdown en `.codex/history/` y sincroniza `context.md` y `state.json`.
- `codex_resume [args...]`: retoma la sesion mas reciente con `codex resume --last`.
- `codex_chat [titulo]`: abre una sesion interactiva y guarda la transcripcion completa como Markdown en `.codex/history/`.
- `codex_status`: muestra la ruta del repo y el estado del contexto local.
- `codex_note [titulo]`: crea una nota nueva en `.codex/notes/`.
- `codex_ls`: lista historial, notas y artefactos recientes del repositorio actual.
- `codex_open [context|state|latest|session|ruta]`: abre archivos clave del contexto local.
- `codex_sync [snapshot]`: rehace `context.md` y `state.json` desde un snapshot existente.
- `codex_bootstrap [objetivo]`: inicializa el repo con un estado base listo para Codex.
- `codex_new <ruta> [objetivo]`: crea una carpeta nueva y la arranca con `codex_bootstrap`.
- `codex_help`: muestra una ayuda breve con el flujo principal.
- `codex_verify`: valida que el puente a `codex` y la estructura `.codex/` esten listos.
- `codex_install`: instala Codex con `npm` si aun no existe en el PATH.

## Convencion de uso
- `bashrc` funciona como biblioteca global.
- cada repo conserva su estado bajo `.codex/`.
- `codex` sigue siendo la interfaz CLI interactiva.
- `codex_chat` es el wrapper recomendado cuando quieres dejar huella en el historial local.
- `codex_chat` escribe un `.md` con la transcripcion del chat dentro de `.codex/history/`.
- `codex_save` sigue guardando snapshots de contexto y refrescando `context.md` y `state.json`.
- `codex_save` tambien usa esa misma logica de sincronizacion cuando lo llamas directo.
- `codex_ls` te da un inventario rapido del contenido de `.codex/`.
- `codex_open` abre `context.md`, `state.json` o el ultimo artefacto sin que tengas que navegar la ruta a mano.
- `codex_sync` te permite regenerar el estado local sin volver a abrir una sesion.
- `codex_bootstrap` deja un baseline limpio para empezar a trabajar de inmediato.
- `codex_new` es el atajo para crear y preparar un nuevo espacio de trabajo en un paso.
- `codex_install` instala `@openai/codex` globalmente cuando falta el binario.

## Uso diario

Arranque rapido:
```bash
source ~/bashrc/aliases
codex_new ~/work/proyecto "Implementar flujo inicial"
```

Sesion de trabajo:
```bash
cd ~/work/proyecto
codex_chat "Ajustar contexto de negocio"
```

Revision rapida:
```bash
codex_ls
codex_open context
codex_open latest
codex_open state
```

Recuperacion de contexto:
```bash
codex_sync
codex_resume
```

Creacion manual de estado base:
```bash
codex_bootstrap "Objetivo del workspace"
```

## Cheat Sheet

```bash
source ~/bashrc/aliases
codex_new ~/work/proyecto "Objetivo"
cd ~/work/proyecto
codex_chat "Sesion"
codex_ls
codex_open context
codex_sync
codex_help
codex_verify
```

## Carga
- este modulo se carga automaticamente via `~/bashrc/aliases`.
- si editas el archivo, recarga con `source ~/bashrc/aliases`.
