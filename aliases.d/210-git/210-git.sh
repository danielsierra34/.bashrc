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



