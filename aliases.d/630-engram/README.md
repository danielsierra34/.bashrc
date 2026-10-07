# Engram

Memoria persistente local para agentes de codigo. Guarda decisiones,
descubrimientos, errores resueltos y contexto entre sesiones en SQLite.

## Instalacion

```bash
source ~/bashrc/aliases
engram_install
engram_check
```

El binario se instala por defecto en `~/.local/bin` y los datos en `~/.engram`.
No requiere Python, Node ni Docker.

## Integracion con agentes

La instalacion y la configuracion son pasos separados:

```bash
engram_setup_codex
engram_setup_claude
engram_setup_antigravity
```

O todo junto:

```bash
engram_setup_all
```

Reinicia Codex, Claude Code y Antigravity despues de configurarlos.

## Uso diario

```bash
engram_search "decisiones sobre autenticacion"
engram_tui
engram_stats
engram_sync
engram_doctor
```

Engram es global y persistente. Por eso `ai_install` lo instala, pero
`ai_init` no crea un directorio nuevo en cada proyecto.
