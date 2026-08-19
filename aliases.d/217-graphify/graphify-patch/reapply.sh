#!/usr/bin/env bash
# Reaplica el fallback textual generico sobre la instalacion actual de
# Graphify (uv tool install graphifyy). Ver README.md en este directorio.
set -e

_patch_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
_tool_dir="$(uv tool dir 2>/dev/null)/graphifyy"
_py_ver="$(basename "$(find "$_tool_dir/lib" -maxdepth 1 -type d -name 'python*' 2>/dev/null | head -n 1)")"
_pkg_dir="$_tool_dir/lib/$_py_ver/site-packages/graphify"

if [ -z "$_py_ver" ] || [ ! -d "$_pkg_dir" ]; then
    echo "No encontre la instalacion de graphifyy en $_tool_dir. ¿Esta instalado con 'uv tool install graphifyy'?"
    exit 1
fi

echo "Aplicando parche sobre: $_pkg_dir"
mkdir -p "$_pkg_dir/extractors"
cp "$_patch_dir/detect.py" "$_pkg_dir/detect.py"
cp "$_patch_dir/extract.py" "$_pkg_dir/extract.py"
cp "$_patch_dir/extractors/generic_text.py" "$_pkg_dir/extractors/generic_text.py"

_venv_py="$_tool_dir/bin/python3"
if [ -x "$_venv_py" ]; then
    "$_venv_py" -m py_compile "$_pkg_dir/detect.py" "$_pkg_dir/extract.py" "$_pkg_dir/extractors/generic_text.py"
    echo "py_compile OK"
fi

echo "Listo. Verifica con: graphify --version"
