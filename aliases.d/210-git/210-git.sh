########################################################################################## GIT
git_email() {
    if [ -z "$1" ]; then
        echo "Uso: git_set_email \"correo@example.com\""
        return 1
    fi
    git config --global user.email "$1"
    echo "Correo de Git configurado como: $1"
}

git_name() {
    if [ -z "$1" ]; then
        echo "Uso: git_set_name \"Tu Nombre\""
        return 1
    fi
    git config --global user.name "$1"
    echo "Nombre de Git configurado como: $1"
}

git_identity_here() {
    local name email
    name="$1"
    email="$2"

    if [ -z "$name" ] || [ -z "$email" ]; then
        echo "Uso: git_identity_here \"Tu Nombre\" \"tu@email.com\""
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Debes ejecutar este comando dentro de un repositorio Git."
        return 1
    fi

    git config --local user.name "$name"
    git config --local user.email "$email"
    echo "Identidad local configurada en $(git rev-parse --show-toplevel 2>/dev/null)"
}

git_coauthor() {
    local name email
    name="$1"
    email="$2"

    if [ -z "$name" ] || [ -z "$email" ]; then
        echo "Uso: git_coauthor \"Nombre Apellido\" \"correo@example.com\""
        return 1
    fi

    printf 'Co-authored-by: %s <%s>\n' "$name" "$email"
}
