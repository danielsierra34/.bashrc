########################################################################################## IOT
cupcarbon_run(){
    local image="${1:-danielsierra34/cupcarbon:latest}"
    local vnc_pass="${2:-${VNC_PASSWORD:-}}"
    local host_port_vnc="${3:-5901}"
    local host_port_web="${4:-6080}"

    if ! command -v docker >/dev/null 2>&1; then
        echo "Error: docker no está instalado o no está en PATH."
        return 1
    fi

    # Login si no existe config de Docker
    if [ ! -f "$HOME/.docker/config.json" ]; then
        echo "Necesitas iniciar sesión en Docker Hub."
        read -r -p "Docker Hub user: " docker_user
        if [ -z "$docker_user" ]; then
            echo "Error: usuario vacío."
            return 1
        fi
        docker login --username "$docker_user" || return 1
    fi

    echo "Descargando imagen: $image"
    docker pull "$image" || return 1

    echo "Ejecutando contenedor..."
    if [ -n "$vnc_pass" ]; then
        docker run -it --rm \
            -p "${host_port_web}:6080" \
            -p "${host_port_vnc}:5901" \
            -e VNC_PASSWORD="$vnc_pass" \
            "$image"
        return $?
    fi

    docker run -it --rm \
        -p "${host_port_web}:6080" \
        -p "${host_port_vnc}:5901" \
        "$image"
}

cupcarbon_help(){
    echo "Uso: cupcarbon_run [imagen] [vnc_password] [host_port_vnc] [host_port_web]"
    echo "Ejemplo: cupcarbon_run danielsierra34/cupcarbon:latest MiClave 5901 6080"
    echo "Luego abre: http://localhost:6080/vnc.html"
}
