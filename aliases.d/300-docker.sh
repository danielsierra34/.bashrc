########################################################################################## DOCKER

docker_restart(){
  docker compose build --no-cache && docker compose up
}

docker_networks(){
    sudo docker network ls

}

docker_networks_create(){
    if [ -z "$1" ]; then
        echo "Usage: cdocker_networks_create <network_name>"
        return 1
    fi

    NETWORK_NAME="$1"

    if sudo docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
        echo "Network '$NETWORK_NAME' already exists."
    else
        sudo docker network create "$NETWORK_NAME"
        echo "Network '$NETWORK_NAME' created successfully."
    fi
}

docker_networks_delete(){
        if [ -z "$1" ]; then
        echo "Usage: docker_networks_delete <network_name | all>"
        return 1
    fi

    NETWORK_NAME="$1"

    if [ "$NETWORK_NAME" == "all" ]; then
        echo "Deleting all user-defined Docker networks..."
        # List all user-defined networks (excluding 'bridge', 'host', 'none') and delete them
        for net in $(sudo docker network ls --format "{{.Name}}" --filter "driver=bridge"); do
            if [[ "$net" != "bridge" && "$net" != "host" && "$net" != "none" ]]; then
                echo "Deleting network: $net"
                sudo docker network rm "$net"
            fi
        done
        echo "All user-defined networks deleted successfully."
    else
        # Check if the specific network exists
        if sudo docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
            # Check if any containers are connected to the network
            if [ "$(sudo docker network inspect --format='{{range .Containers}}{{.Name}} {{end}}' "$NETWORK_NAME")" ]; then
                echo "Error: Network '$NETWORK_NAME' has active containers. Remove them first."
                return 1
            fi

            # Remove the network
            sudo docker network rm "$NETWORK_NAME"
            echo "Network '$NETWORK_NAME' deleted successfully."
        else
            echo "Network '$NETWORK_NAME' does not exist."
        fi
    fi
}

docker_c(){
    sudo docker ps -a
}

docker_c_run() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
        echo "Usage: docker_c_run <originPort> <destinationPort> <image_name> <container_name>"
        return 1
    fi
    sudo docker run -d -p "$2:$1" --name "$4" "$3"
}

docker_c_run_in_network() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
        echo "Usage: docker_run <originPort> <destinationPort> <image_name> <container_name> <network>"
        return 1
    fi

    CUSTOM_URL="$5"  # Set the custom URL to the 5th parameter (network name)
    
    sudo docker run --network "$5" -p "$2:$1" --name "$4" -e CUSTOM_URL="$CUSTOM_URL" "$3"
}


docker_c_run_always() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
        echo "Usage: docker_run <originPort> <destinationPort> <image_name> <container_name>"
        return 1
    fi
    sudo docker run -dp "$2":"$1" --name "$4" -w /app -v "$(pwd):/app" "$3"   
}

docker_c_run_always_in_network() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
        echo "Usage: docker_run <originPort> <destinationPort> <image_name> <container_name> <network>"
        return 1
    fi
    sudo docker run -dp "$2:$1" --network "$5" --name "$4" -w /app -v "$(pwd):/app" "$3" tail -f /dev/null
}


docker_c_start() {
    if [ "$1" == "all" ]; then
        echo "Starting all stopped containers..."
        sudo docker start $(sudo docker ps -aq)
    else
        echo "Starting container: $1"
        sudo docker start "$1"
    fi
}

docker_c_stop() {
    if [ -z "$1" ]; then
        echo "Usage: docker_c_stop <container_name_or_id> | all"
        return 1
    fi

    if [ "$1" = "all" ]; then
        sudo docker stop $(sudo docker ps -q)
    else
        sudo docker stop "$1"
    fi
}

docker_c_restart() {
    if [ -z "$1" ]; then
        echo "Usage: docker_c_restart <container_name_or_id> | all"
        return 1
    fi

    if [ "$1" = "all" ]; then
        sudo docker restart $(sudo docker ps -q)
    else
        sudo docker restart "$1"
    fi
}

docker_c_delete() {
    if [ -z "$1" ]; then
        echo "Usage: docker_delete <container_name_or_id> | all"
        return 1
    fi

    if [ "$1" = "all" ]; then
        sudo docker rm $(sudo docker ps -aq)
    else
        sudo docker rm "$1"
    fi
}

docker_c_logs(){
    if [ -z "$1" ]; then
        echo "Usage: docker_c_logs <container_name_or_id>"
        return 1
    fi
    sudo docker logs -f "$1"
}

docker_c_enter(){
    if [ -z "$1" ]; then
        echo "Usage: docker_c_enter <container_name_or_id>"
        return 1
    fi
    sudo docker exec -it "$1" sh
}

docker_i(){
    sudo docker images
}

docker_i_build() {
    if [ -z "$1" ]; then
        echo "Usage: docker_build <image_name>"
        return 1
    fi
    sudo docker build --network=host -t "$1" .
}

docker_i_delete() {
    if [ -z "$1" ]; then
        echo "Usage: docker_delete_image <image_name_or_id> | all"
        return 1
    fi

    if [ "$1" = "all" ]; then
        sudo docker rmi $(sudo docker images -q)
    else
        sudo docker rmi "$1"
    fi
}

docker_i_delete_forced() {
    if [ -z "$1" ]; then
        echo "Usage: docker_delete_image <image_name_or_id> | all"
        return 1
    fi

    if [ "$1" = "all" ]; then
        sudo docker rmi -f $(sudo docker images -q)
    else
        sudo docker rmi -f "$1"
    fi
}

docker_i_compose() {
    sudo docker compose up
}

docker_i_compose_forced() {
    if [ -z "$1" ]; then
        echo "Usage: docker_i_compose_forced <service_name>"
        return 1
    fi
    sudo docker compose up --build --force-recreate --no-deps "$1"
}

docker_i_pull() {
    if [ -z "$1" ]; then
        echo "Usage: docker_i_pull <image_name> <version (opcional)>"
        return 1
    fi
    sudo docker image pull "$1:${2:-latest}"
}

docker_install() {
    OS=$1                 # 'debian' o 'ubuntu'
    TARGET_USER=${2:-$USER}  # usuario al que darle permisos (default: usuario actual)

    if [[ "$OS" != "debian" && "$OS" != "ubuntu" ]]; then
        echo "Error: Debes especificar 'debian' o 'ubuntu' como primer parámetro."
        return 1
    fi

    if ! id -u "$TARGET_USER" >/dev/null 2>&1; then
        echo "Error: el usuario '$TARGET_USER' no existe en el sistema."
        return 1
    fi

    set -euo pipefail
    echo ">>> Instalando Docker en $OS para el usuario: $TARGET_USER"

    # Paquetes base y llave del repo oficial
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
        sudo curl -fsSL "https://download.docker.com/linux/$OS/gpg" -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
    fi

    # Agregar repo estable
    CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    echo ">>> Usando codename: $CODENAME"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$OS $CODENAME stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    # Instalar Docker + Buildx + Compose v2
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Habilitar y arrancar Docker
    sudo systemctl enable --now docker

    # Crear grupo docker si no existe y agregar usuario
    if ! getent group docker >/dev/null; then
        sudo groupadd docker
    fi
    sudo usermod -aG docker "$TARGET_USER"

    # Ajustar permisos del socket (para que funcione de inmediato en esta sesión)
    if [[ -S /var/run/docker.sock ]]; then
        sudo chown root:docker /var/run/docker.sock
        sudo chmod 660 /var/run/docker.sock
    fi

    # Verificación básica
    echo ">>> Verificación:"
    docker --version || true
    docker compose version || true

    # Intentar ejecutar como el usuario objetivo sin re-login
    if sudo -u "$TARGET_USER" docker ps >/dev/null 2>&1; then
        echo "✅ $TARGET_USER puede usar docker sin sudo."
    else
        # Intentar con 'sg docker' si está disponible (aplica el grupo en caliente)
        if command -v sg >/dev/null 2>&1; then
            if sudo -u "$TARGET_USER" sg docker -c 'docker ps' >/dev/null 2>&1; then
                echo "✅ $TARGET_USER puede usar docker vía 'sg docker' en esta sesión."
            else
                echo "ℹ️ Aún no es posible usar docker sin sudo en esta sesión."
            fi
        else
            echo "ℹ️ 'sg' no disponible; puede requerir re-login para aplicar el grupo."
        fi
        echo "👉 Mientras tanto, puedes usar: sudo docker ..."
    fi

    echo "✅ Instalación completa. Si aún no puedes usar 'docker' sin sudo, cierra y vuelve a entrar sesión de $TARGET_USER."
}

docker_clean(){
    sudo docker system prune -a --volumes
}

