########################################################################################## DEV SERVER

_dev_server_run() {
    local role port command

    role="$1"
    port="$2"
    shift 2
    command="$*"

    if [ -z "$port" ]; then
        echo "Usage: ${role}_iniciar <puerto> [comando]"
        return 1
    fi

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "El puerto debe ser numerico: $port"
        return 1
    fi

    if [ -z "$command" ]; then
        command="${DEV_SERVER_CMD:-npm run dev}"
    fi

    echo "Iniciando ${role} en 0.0.0.0:$port con: $command"
    PORT="$port" HOST="${DEV_SERVER_HOST:-0.0.0.0}" sh -c "$command"
}

backend_iniciar() {
    _dev_server_run "backend" "$@"
}

frontend_iniciar() {
    _dev_server_run "frontend" "$@"
}
