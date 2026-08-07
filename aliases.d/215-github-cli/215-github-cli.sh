########################################################################################## GITHUB CLI
github_cli_setup() {
    if ! command -v gh >/dev/null 2>&1; then
        if ! command -v sudo >/dev/null 2>&1; then
            echo "No se encontro 'gh' y no esta disponible 'sudo'. Instala GitHub CLI manualmente."
            return 1
        fi

        echo "Instalando GitHub CLI (gh)..."
        sudo apt-get update && sudo apt-get install -y gh
        if [ $? -ne 0 ]; then
            echo "No fue posible instalar 'gh'."
            return 1
        fi
    fi

    echo "Verificando autenticacion de GitHub CLI..."
    if ! gh auth status >/dev/null 2>&1; then
        echo "Iniciando autenticacion interactiva..."
        gh auth login --web --git-protocol https --hostname github.com
        if [ $? -ne 0 ]; then
            echo "La autenticacion con GitHub CLI no se completo."
            return 1
        fi
    fi

    gh auth setup-git >/dev/null 2>&1
    echo "GitHub CLI listo."
    gh auth status
}

github_cli_repo_bootstrap() {
    if ! command -v gh >/dev/null 2>&1; then
        echo "Primero ejecuta: github_cli_setup"
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Este comando debe ejecutarse dentro de un repositorio Git."
        return 1
    fi

    local remote_url repo_slug
    remote_url="$(git remote get-url origin 2>/dev/null)"
    if [ -z "$remote_url" ]; then
        echo "No se encontro un remoto 'origin'."
        return 1
    fi

    repo_slug="$remote_url"
    repo_slug="${repo_slug#git@github.com:}"
    repo_slug="${repo_slug#https://github.com/}"
    repo_slug="${repo_slug%.git}"

    echo "Repositorio detectado: $repo_slug"
    gh repo view "$repo_slug" >/dev/null 2>&1 || {
        echo "No se pudo acceder al repositorio con gh."
        return 1
    }

    echo "GitHub CLI autenticado y repositorio verificado: $repo_slug"
}
