# graphify-patch

Copia de respaldo de un parche aplicado directamente a la instalación local de
Graphify (no a este repo `bashrc`), para que sobreviva a un `uv tool upgrade
graphifyy` / `graphify_update`.

## Qué hace el parche

Antes, `classify_file()` en `detect.py` devolvia `None` para cualquier
extension que no estuviera en una lista fija (`.cml`, `.puml`, `.mmd`,
`.graphql`, `.feature`, `.customdsl`, etc.), y esos archivos quedaban
completamente invisibles para el grafo (ni en `manifest.json` ni en
`graph.json`, aunque fueran texto plano legible).

El parche agrega un **fallback textual generico**, gateado por un sniff
binario/texto (no por una whitelist mas grande):

- `detect.py`: `_looks_like_text()` + `_is_unrecognized_extension()`, y en
  `classify_file()` un ultimo paso — si la extension no esta en ningun
  set conocido (`CODE_EXTENSIONS`, `DOC_EXTENSIONS`, etc.) pero el archivo
  sniffea como texto, se clasifica como `FileType.CODE`.
- `extract.py`: `_get_extractor()` usa el mismo sniff como ultimo recurso y
  devuelve `extract_generic_text` en vez de `None`.
- `extractors/generic_text.py` (nuevo): extractor sin gramatica — nodo de
  archivo + un nodo por identificador tipo PascalCase/ALLCAPS, con aristas
  `contains` y `references` (para sintaxis tipo `A --> B`).

Ninguna extension ya reconocida (`.py`, `.md`, `.json`, `.yaml`, ...) cambia
de comportamiento — el fallback solo se activa para extensiones ausentes de
todos los sets de `detect.py`.

## Por que archivos completos y no un `.patch`

`detect.py` y `extract.py` son archivos grandes (miles de lineas) que
Graphify reescribe enteros en cada release. Un diff unificado se rompe con
cualquier cambio de contexto entre versiones; copiar el archivo completo tal
como quedo tras el parche es lo unico que garantiza reaplicarlo sin conflictos
de merge. El costo es que un `uv tool upgrade` legitimo (con mejoras reales de
Graphify) se pierde si reaplicas ciegamente — revisa el diff contra la version
nueva antes de sobrescribir si te importa no perder cambios upstream.

## Reaplicar tras un upgrade

```bash
bash ~/bashrc/aliases.d/217-graphify/graphify-patch/reapply.sh
```

Copia los 3 archivos de vuelta a la instalacion de `uv tool` y corre
`python -m py_compile` para confirmar que compilan.

## Version en la que se aplico

- Graphify 0.9.46 (`uv tool list` -> `graphifyy v0.9.46`)
- Instalado via `uv tool install graphifyy` en
  `~/.local/share/uv/tools/graphifyy/`
