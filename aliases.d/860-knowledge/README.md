# 860-knowledge

Genera el scaffolding de una base de conocimiento versionable con un solo comando.

## Comandos
- `knowledge_scaffold <ruta> [nombre]`: crea la estructura base del proyecto.
- `knowledge_help`: muestra un resumen rapido del comando.

## Crea
- `original/`: entrada de archivos originales.
- `knowledge/markdown/`: version Markdown normalizada.
- `knowledge/assets/`: imagenes, diagramas y adjuntos.
- `generated/`: salidas finales versionables.
- `.codex/`: contexto y estado del trabajo.

## Flujo recomendado
1. Ejecuta `knowledge_scaffold`.
2. Carga PDFs, Word, Excel o imagenes en `original/`.
3. Normaliza contenido a Markdown dentro de `knowledge/markdown/`.
4. Versiona todo en GitHub, incluyendo los `.md` generados.
