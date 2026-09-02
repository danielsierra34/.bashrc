#!/usr/bin/env bash

########################################################################################## QUARTO

# Quarto es un CLI de publicacion tecnica para Markdown, notebooks y proyectos.
# En Debian/WSL se instala globalmente mediante el paquete .deb oficial.

_quarto_release_url() {
    local arch asset
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            echo "Arquitectura no soportada por este instalador: $(uname -m)" >&2
            return 1
            ;;
    esac

    if [ -n "${QUARTO_DEB_URL:-}" ]; then
        printf '%s' "$QUARTO_DEB_URL"
        return 0
    fi

    command -v curl >/dev/null 2>&1 || {
        echo "curl no esta instalado." >&2
        return 1
    }

    asset="$(curl -fsSL https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest \
        | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*linux-'"$arch"'\.deb\)".*/\1/p' \
        | head -n 1)"
    [ -n "$asset" ] || {
        echo "No pude localizar el paquete .deb mas reciente de Quarto." >&2
        return 1
    }
    printf '%s' "$asset"
}

quarto_help() {
    cat <<'EOF'
Quarto helpers

  quarto_check                         verifica la instalacion
  quarto_install                       instala Quarto globalmente
  quarto_update                        actualiza Quarto globalmente
  quarto_uninstall                     desinstala Quarto
  quarto_render [ruta|.] [argumentos]  renderiza un documento o proyecto
  quarto_preview [ruta|.] [puerto]     previsualiza con recarga automatica
  quarto_run [ruta|.] [puerto]         atajo para quarto_preview

Ejemplos:
  quarto_install
  cd ~/curso && quarto_run . 4444
  quarto_render informe.qmd --to html
  quarto_render .

Variable opcional:
  QUARTO_DEB_URL  URL fija de un paquete .deb de Quarto
EOF
}

quarto_check() {
    if ! command -v quarto >/dev/null 2>&1; then
        echo "Quarto no esta instalado o no esta en PATH."
        return 1
    fi
    quarto check
}

_quarto_install_deb() {
    local deb_file url

    command -v sudo >/dev/null 2>&1 || {
        echo "sudo no esta disponible." >&2
        return 1
    }
    command -v curl >/dev/null 2>&1 || {
        echo "curl no esta instalado." >&2
        return 1
    }

    url="$(_quarto_release_url)" || return 1
    deb_file="$(mktemp --suffix=.deb)" || return 1

    echo "Descargando Quarto desde: $url"
    if ! curl -fL "$url" -o "$deb_file"; then
        rm -f "$deb_file"
        return 1
    fi
    sudo apt-get install -y "$deb_file"
    local rc=$?
    rm -f "$deb_file"
    return "$rc"
}

quarto_install() {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "Este instalador esta pensado para Debian/WSL Linux."
        echo "En Windows puedes instalar Quarto con winget: winget install Posit.Quarto"
        return 1
    fi
    echo "Instalando Quarto globalmente en Debian..."
    _quarto_install_deb
}

quarto_update() {
    quarto_install
}

quarto_uninstall() {
    if ! command -v quarto >/dev/null 2>&1; then
        echo "Quarto no esta instalado."
        return 1
    fi
    sudo apt-get remove -y quarto
}

quarto_render() {
    local target
    target="${1:-.}"
    shift || true

    command -v quarto >/dev/null 2>&1 || {
        echo "Quarto no esta instalado. Ejecuta quarto_install."
        return 1
    }
    quarto render "$target" "$@"
}

quarto_preview() {
    local target port
    target="${1:-.}"
    port="${2:-${QUARTO_PORT:-4444}}"
    shift || true
    shift || true

    command -v quarto >/dev/null 2>&1 || {
        echo "Quarto no esta instalado. Ejecuta quarto_install."
        return 1
    }
    quarto preview "$target" --port "$port" "$@"
}

quarto_run() {
    quarto_preview "$@"
}
