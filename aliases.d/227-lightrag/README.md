# 227-lightrag

Herramientas para montar y usar LightRAG como corpus de estudio local.

## Funciones

### `lightrag_install`
Instala LightRAG globalmente con `uv tool install`. La variante recomendada
es `lightrag-hku[api]` porque trae el servidor, la WebUI y la API.

### `lightrag_workspace <ruta> [workspace]`
Prepara una carpeta como workspace de documentos y escribe las
instrucciones para Codex, Claude y Antigravity:

- crea `inputs/` para apuntes, PDFs y otros archivos fuente
- crea `rag_storage/` para el indice y el grafo persistente
- agrega un `.gitignore` minimo para no versionar el storage local
- escribe `.env.example` con la configuracion base
- escribe el bloque de `AGENTS.md` para guiar al agente antes y despues
  de trabajar con el corpus
- escribe el mismo bloque en `CLAUDE.md`
- escribe reglas de Antigravity en `.agents/rules/lightrag.md` y
  `.agents/workflows/lightrag.md`

### `lightrag_serve <ruta> [puerto] [workspace]`
Arranca `lightrag-server` desde un workspace concreto.

### `lightrag_query <ruta> "pregunta" [mode]`
Hace una consulta HTTP al servidor ya levantado.

### `lightrag_status <ruta> [puerto]`
Consulta `/health` para saber si el servidor responde.

### `lightrag_open <ruta> [puerto]`
Abre la WebUI en el navegador.

### `lightrag_ingest <fuente> [ruta|.]`
Copia documentos compatibles desde una carpeta o archivo fuente hacia
`inputs/` del workspace.

### `lightrag_seed [nombre]`
Crea una plantilla inicial de estudio usando el directorio actual como
workspace. Agrega `notes/` y archivos base para un corpus nuevo de curso.

### `lightrag_refresh <ruta|.] [fuente] [puerto]`
Repite la preparacion del workspace, ingiere material nuevo si le pasas una
fuente y ejecuta un hook opcional de refresco si defines
`LIGHTRAG_REFRESH_CMD`.

### `lightrag_run <ruta|.] [fuente] [nombre] [port]`
Flujo de una sola llamada para preparar el workspace, cargar una fuente
opcional y dejar instrucciones de agente listas. Es la funcion principal
si quieres arrancar un nuevo proyecto documental sin acordarte de los
pasos intermedios.

## Variables opcionales

- `LIGHTRAG_UV_PACKAGE`: paquete a instalar con `uv` (default: `lightrag-hku[api]`)
- `LIGHTRAG_BIN`: binario CLI esperado en `PATH` (default: `lightrag-server`)
- `LIGHTRAG_HOST`: host de escucha para `lightrag-server` (default: `127.0.0.1`)
- `LIGHTRAG_PORT`: puerto por defecto (default: `9621`)
- `LIGHTRAG_API_KEY`: API key opcional para `/health` y `/query`
- `LIGHTRAG_REFRESH_CMD`: comando opcional para reindexar o refrescar el
  backend cuando cambie el corpus

## Cuándo usarlo

Usa este módulo cuando tu carpeta sea un corpus de:

- apuntes
- PDFs
- guías
- manuales
- material de estudio mixto

No reemplaza Graphify en codebases. Complementa ese flujo cuando el
contenido principal no es código.
