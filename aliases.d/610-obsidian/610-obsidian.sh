#!/usr/bin/env bash

########################################################################################## OBSIDIAN

# Obsidian es una aplicacion de escritorio. En WSL se instala en Windows mediante winget.
# En Linux se usa flatpak o snap, segun lo que exista en el sistema.

_obsidian_winget_id() {
  printf '%s' "${OBSIDIAN_WINGET_ID:-Obsidian.Obsidian}"
}

_obsidian_linux_package() {
  printf '%s' "${OBSIDIAN_LINUX_PACKAGE:-com.obsidian.Obsidian}"
}

_obsidian_is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

_obsidian_windows_install() {
  powershell.exe -NoProfile -Command \
    "winget install --id '$(_obsidian_winget_id)' --exact --accept-source-agreements --accept-package-agreements"
}

_obsidian_windows_upgrade() {
  powershell.exe -NoProfile -Command \
    "winget upgrade --id '$(_obsidian_winget_id)' --exact --accept-source-agreements --accept-package-agreements"
}

_obsidian_windows_uninstall() {
  powershell.exe -NoProfile -Command \
    "winget uninstall --id '$(_obsidian_winget_id)' --exact"
}

obsidian_help() {
  cat <<'EOF'
Obsidian helpers

  obsidian_check              verifica si Obsidian esta instalado
  obsidian_install            instala Obsidian globalmente
  obsidian_update             actualiza Obsidian
  obsidian_uninstall          desinstala Obsidian
  obsidian_open [ruta|.]      abre Obsidian, opcionalmente con una ruta

En WSL Debian la instalacion, actualizacion y desinstalacion se ejecutan en
Windows mediante winget. En Linux se intenta usar flatpak o snap.

Variables opcionales:
  OBSIDIAN_WINGET_ID          default: Obsidian.Obsidian
  OBSIDIAN_LINUX_PACKAGE      default: com.obsidian.Obsidian
EOF
}

obsidian_check() {
  if _obsidian_is_wsl; then
    if ! command -v powershell.exe >/dev/null 2>&1; then
      echo "WSL detectado, pero powershell.exe no esta disponible."
      return 1
    fi
    powershell.exe -NoProfile -Command \
      "if (Get-AppxPackage -Name 'Obsidian.Obsidian' -ErrorAction SilentlyContinue) { exit 0 }; winget list --id '$(_obsidian_winget_id)' --exact --accept-source-agreements 2>\$null | Out-Null; if (\$LASTEXITCODE -eq 0) { exit 0 }; exit 1"
    if [ "$?" -eq 0 ]; then
      echo "Obsidian esta instalado en Windows."
      return 0
    fi
    echo "Obsidian no esta instalado en Windows."
    return 1
  fi

  if command -v obsidian >/dev/null 2>&1; then
    echo "Obsidian esta instalado: $(command -v obsidian)"
    return 0
  fi
  if command -v flatpak >/dev/null 2>&1 && flatpak info "$(_obsidian_linux_package)" >/dev/null 2>&1; then
    echo "Obsidian esta instalado mediante Flatpak."
    return 0
  fi
  if command -v snap >/dev/null 2>&1 && snap list obsidian >/dev/null 2>&1; then
    echo "Obsidian esta instalado mediante Snap."
    return 0
  fi
  echo "Obsidian no esta instalado."
  return 1
}

obsidian_install() {
  if _obsidian_is_wsl; then
    command -v powershell.exe >/dev/null 2>&1 || {
      echo "No se encontro powershell.exe para instalar Obsidian en Windows."
      return 1
    }
    echo "Instalando Obsidian globalmente en Windows mediante winget..."
    _obsidian_windows_install
    return $?
  fi

  if command -v flatpak >/dev/null 2>&1; then
    echo "Instalando Obsidian mediante Flatpak..."
    flatpak install -y flathub "$(_obsidian_linux_package)"
    return $?
  fi
  if command -v snap >/dev/null 2>&1; then
    echo "Instalando Obsidian mediante Snap..."
    sudo snap install obsidian --classic
    return $?
  fi
  echo "No hay flatpak ni snap disponibles. Instala uno de ellos o usa el AppImage oficial."
  return 1
}

obsidian_update() {
  if _obsidian_is_wsl; then
    echo "Actualizando Obsidian en Windows mediante winget..."
    _obsidian_windows_upgrade
    return $?
  fi
  if command -v flatpak >/dev/null 2>&1 && flatpak info "$(_obsidian_linux_package)" >/dev/null 2>&1; then
    flatpak update -y "$(_obsidian_linux_package)"
    return $?
  fi
  if command -v snap >/dev/null 2>&1 && snap list obsidian >/dev/null 2>&1; then
    sudo snap refresh obsidian
    return $?
  fi
  echo "No se encontro una instalacion administrable de Obsidian."
  return 1
}

obsidian_uninstall() {
  if _obsidian_is_wsl; then
    echo "Desinstalando Obsidian de Windows mediante winget..."
    _obsidian_windows_uninstall
    return $?
  fi
  if command -v flatpak >/dev/null 2>&1 && flatpak info "$(_obsidian_linux_package)" >/dev/null 2>&1; then
    flatpak uninstall -y "$(_obsidian_linux_package)"
    return $?
  fi
  if command -v snap >/dev/null 2>&1 && snap list obsidian >/dev/null 2>&1; then
    sudo snap remove obsidian
    return $?
  fi
  echo "No se encontro una instalacion administrable de Obsidian."
  return 1
}

obsidian_open() {
  local target="${1:-}"

  if _obsidian_is_wsl; then
    command -v powershell.exe >/dev/null 2>&1 || {
      echo "No se encontro powershell.exe."
      return 1
    }
    if [ -n "$target" ]; then
      local win_target
      win_target="$(wslpath -w "$(cd "$target" 2>/dev/null && pwd)")" || {
        echo "Ruta no encontrada: $target"
        return 1
      }
      powershell.exe -NoProfile -Command "Start-Process 'Obsidian.exe' -ArgumentList @('$win_target')"
    else
      powershell.exe -NoProfile -Command "Start-Process 'Obsidian.exe'"
    fi
    return $?
  fi

  if command -v obsidian >/dev/null 2>&1; then
    command obsidian ${target:+"$target"} >/dev/null 2>&1 &
    return 0
  fi
  if command -v flatpak >/dev/null 2>&1 && flatpak info "$(_obsidian_linux_package)" >/dev/null 2>&1; then
    flatpak run "$(_obsidian_linux_package)" ${target:+"$target"} >/dev/null 2>&1 &
    return 0
  fi
  if command -v snap >/dev/null 2>&1 && snap list obsidian >/dev/null 2>&1; then
    snap run obsidian ${target:+"$target"} >/dev/null 2>&1 &
    return 0
  fi
  echo "Obsidian no esta instalado. Ejecuta obsidian_install."
  return 1
}
