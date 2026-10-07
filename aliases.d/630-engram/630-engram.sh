#!/usr/bin/env bash

########################################################################################## ENGRAM

# Engram: memoria persistente local para agentes de codigo.

_engram_bin_dir() {
    printf '%s' "${ENGRAM_BIN_DIR:-$HOME/.local/bin}"
}

_engram_release_url() {
    local arch asset
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) echo "Arquitectura no soportada por Engram: $(uname -m)" >&2; return 1 ;;
    esac

    if [ -n "${ENGRAM_RELEASE_URL:-}" ]; then
        printf '%s' "$ENGRAM_RELEASE_URL"
        return 0
    fi

    command -v curl >/dev/null 2>&1 || { echo "curl no esta instalado." >&2; return 1; }
    asset="$(curl -fsSL https://api.github.com/repos/Gentleman-Programming/engram/releases/latest \
        | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*linux_'"$arch"'\.tar\.gz\)".*/\1/p' \
        | head -n 1)"
    [ -n "$asset" ] || { echo "No pude localizar el binario Linux mas reciente de Engram." >&2; return 1; }
    printf '%s' "$asset"
}

engram_help() {
    cat <<'EOF'
Engram helpers

  engram_check                         verifica el binario y la memoria local
  engram_install                       instala Engram globalmente
  engram_update                        actualiza Engram globalmente
  engram_uninstall                     elimina el binario global
  engram_setup_codex                   configura Engram en Codex
  engram_setup_claude                  configura Engram en Claude Code
  engram_setup_antigravity             configura Engram en Antigravity CLI
  engram_setup_all                     configura los tres agentes
  engram_search "consulta"             busca memorias desde la terminal
  engram_tui                           abre la interfaz de memoria
  engram_stats                         muestra estadisticas
  engram_sync                          sincroniza/exporta memorias del proyecto
  engram_doctor                        ejecuta diagnosticos

La instalacion no modifica agentes. Usa engram_setup_all cuando quieras
registrar el MCP y las instrucciones de memoria para Codex, Claude y Antigravity.

Variables opcionales:
  ENGRAM_BIN_DIR       default: ~/.local/bin
  ENGRAM_RELEASE_URL   URL fija de un tarball Linux de Engram
  ENGRAM_DATA_DIR      directorio de datos de Engram
  ENGRAM_PROJECT       nombre explicito del proyecto
EOF
}

engram_check() {
    if ! command -v engram >/dev/null 2>&1; then
        echo "Engram no esta instalado o no esta en PATH."
        return 1
    fi
    engram --version 2>/dev/null || engram version 2>/dev/null || true
    if [ -d "${ENGRAM_DATA_DIR:-$HOME/.engram}" ]; then
        echo "Datos: ${ENGRAM_DATA_DIR:-$HOME/.engram}"
    else
        echo "Datos: aun no creados (${ENGRAM_DATA_DIR:-$HOME/.engram})"
    fi
}

_engram_install_archive() {
    local url archive temp_dir extracted target rc
    command -v curl >/dev/null 2>&1 || { echo "curl no esta instalado." >&2; return 1; }
    command -v tar >/dev/null 2>&1 || { echo "tar no esta instalado." >&2; return 1; }

    url="$(_engram_release_url)" || return 1
    archive="$(mktemp --suffix=.tar.gz)" || return 1
    temp_dir="$(mktemp -d)" || { rm -f "$archive"; return 1; }

    echo "Descargando Engram desde: $url"
    if ! curl -fL "$url" -o "$archive" || ! tar -xzf "$archive" -C "$temp_dir"; then
        rm -f "$archive"
        rm -rf "$temp_dir"
        return 1
    fi

    extracted="$(find "$temp_dir" -type f -name engram -print -quit)"
    if [ -z "$extracted" ]; then
        echo "El archivo descargado no contiene el binario engram." >&2
        rm -f "$archive"
        rm -rf "$temp_dir"
        return 1
    fi

    target="$(_engram_bin_dir)/engram"
    mkdir -p "$(_engram_bin_dir)" || { rm -f "$archive"; rm -rf "$temp_dir"; return 1; }
    install -m 0755 "$extracted" "$target"
    rc=$?
    rm -f "$archive"
    rm -rf "$temp_dir"
    return "$rc"
}

engram_install() {
    echo "Instalando Engram globalmente en $(_engram_bin_dir)..."
    _engram_install_archive || return 1
    export PATH="$(_engram_bin_dir):$PATH"
    echo "Engram instalado en $(_engram_bin_dir)/engram"
    engram_check
}

engram_update() { engram_install; }

engram_uninstall() {
    local target
    target="$(_engram_bin_dir)/engram"
    [ -e "$target" ] || { echo "No encontre el binario: $target"; return 1; }
    rm -f "$target"
    echo "Binario eliminado: $target"
}

engram_setup_codex() {
    command -v engram >/dev/null 2>&1 || { echo "Ejecuta engram_install primero."; return 1; }
    engram setup codex
}

engram_setup_claude() {
    command -v engram >/dev/null 2>&1 || { echo "Ejecuta engram_install primero."; return 1; }
    engram setup claude-code
}

engram_setup_antigravity() {
    command -v engram >/dev/null 2>&1 || { echo "Ejecuta engram_install primero."; return 1; }
    engram setup antigravity-cli
}

engram_setup_all() {
    local rc=0
    engram_setup_codex || rc=1
    engram_setup_claude || rc=1
    engram_setup_antigravity || rc=1
    return "$rc"
}

engram_search() {
    command -v engram >/dev/null 2>&1 || { echo "Ejecuta engram_install primero."; return 1; }
    [ "$#" -gt 0 ] || { echo 'Uso: engram_search "consulta"'; return 1; }
    engram search "$@"
}

engram_tui() { command -v engram >/dev/null 2>&1 || { echo "Ejecuta engram_install primero."; return 1; }; engram tui; }
engram_stats() { command -v engram >/dev/null 2>&1 || { echo "Ejecuta engram_install primero."; return 1; }; engram stats; }
engram_sync() { command -v engram >/dev/null 2>&1 || { echo "Ejecuta engram_install primero."; return 1; }; engram sync "$@"; }
engram_doctor() { command -v engram >/dev/null 2>&1 || { echo "Ejecuta engram_install primero."; return 1; }; engram doctor "$@"; }
