########################################################################################## GHOST

MAILGUN_USER="brad@sandbox27703646c4a5406f948c2ed685c84070.mailgun.org"
MAILGUN_API_KEY="27450cd34c15e02c3830faae0f41ff63-67bd41c2-c8b32c62"

ghost_terminal(){
    sudo docker exec -it ghost /bin/bash
}

install_jq_in_container() {
    echo "🔧 Instalando jq dentro del contenedor Ghost..."
    sudo docker exec ghost bash -c "apt-get update && apt-get install -y jq"
}

replace_mail_config() {
    local config_file=$1

    echo "Verificando existencia del archivo en el contenedor: $config_file"
    sudo docker exec ghost ls "$config_file"

    if [ $? -ne 0 ]; then
        echo "El archivo $config_file no existe en el contenedor."
        return 1
    fi

    echo "Reemplazando la configuración de mail en $config_file con jq..."

    sudo docker exec ghost bash -c "jq \
    '.mail = {
        transport: \"SMTP\",
        options: {
            service: \"Mailgun\",
            host: \"smtp.mailgun.org\",
            port: 587,
            secure: false,
            auth: {
                user: \"${MAILGUN_USER}\",
                pass: \"${MAILGUN_API_KEY}\"
            }
        }
    }' $config_file > /tmp/config.tmp && mv /tmp/config.tmp $config_file"

    echo "✅ Configuración de mail reemplazada usando jq."
}

ghost_run() {
    # Parámetro: versión de Ghost
    GHOST_VERSION=$1

    # Nombre fijo para el contenedor y puerto estándar
    CONTAINER_NAME="ghost"
    IMAGE_NAME="ghost:${GHOST_VERSION}"
    HOST_PORT=2368
    CONTAINER_PORT=2368

    echo "🧭 Verificando existencia del contenedor '${CONTAINER_NAME}'..."

    if [ "$(sudo docker ps -a -q -f name=^/${CONTAINER_NAME}$)" ]; then
        echo "⛔ Contenedor '${CONTAINER_NAME}' encontrado. Deteniendo y eliminando..."
        sudo docker stop ${CONTAINER_NAME}
        sudo docker rm ${CONTAINER_NAME}
    else
        echo "ℹ️ No existe un contenedor llamado '${CONTAINER_NAME}'."
    fi

    echo "🧹 Limpiando volúmenes sin uso..."
    sudo docker volume prune -f

    echo "📦 Levantando Ghost ${GHOST_VERSION} en http://localhost:${HOST_PORT}..."
    sudo docker run -d \
        --name ${CONTAINER_NAME} \
        -e NODE_ENV=development \
        -p ${HOST_PORT}:${CONTAINER_PORT} \
        ${IMAGE_NAME}

    echo "✅ Ghost ${GHOST_VERSION} corriendo en http://localhost:${HOST_PORT}"
}


cypress_run() {
    # Recibir la versión de Ghost como parámetro
    VERSION=$1

    echo "🚀 Ejecutando pruebas con Cypress usando la versión de Ghost ${VERSION}..."
    VERSION=$VERSION npm run test --workspace=e2e/misw-4103-cypress

    echo "🧹 Renombrando y moviendo archivos .png, y eliminando directorios vacíos..."

    find e2e/misw-4103-cypress/cypress/screenshots/$VERSION -mindepth 2 -type f -name "*.png" -exec bash -c '
      for file; do
        folder_path=$(dirname "$file")
        folder_name=$(basename "$folder_path")
        ext="${file##*.}"
        new_name="${folder_name}.${ext}"
        mv "$file" "e2e/misw-4103-cypress/cypress/screenshots/'"$VERSION"'/$new_name"
      done
    ' bash {} +

    find e2e/misw-4103-cypress/cypress/screenshots/$VERSION -mindepth 1 -type d -empty -delete
}




kraken_run(){
    npm run test --workspace=e2e/misw-4103-kraken
}

