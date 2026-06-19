#UPa
#sudo 7z x reports.rar -o/opt/bitnami/apache2/htdocs/kraken
#sudo apt install p7zip-full

fastpush() {
  # Si no se pasa mensaje, error y salir
  if [ -z "$1" ]; then
    echo "❌  Debes pasar un mensaje de commit."
    echo "👉  Uso: fastpush \"mensaje del commit\""
    return 1
  fi

  # Guarda el mensaje completo (por si contiene espacios)
  local msg="$*"

  echo "📦 Agregando archivos..."
  git add .

  echo "📝 Commit con mensaje: \"$msg\""
  git commit -m "$msg" || {
    echo "⚠️  No hay cambios para commitear."
    return 0
  }

  echo "🚀 Haciendo push..."
  git push

  echo "✅  Fastpush completado."
}

linux_version() {
    cat /etc/os-release
}

nano_install(){
    apt update && apt install nano -y
}

ssh_zip() {
    if [ -z "$1" ]; then
        echo "Usage: ssh_zip <foldername>"
        return 1
    fi
    sudo tar -czvf "$1".tgz "$1"/
}

python_serve(){
    python -m http.server 8000
}




flask_run() {
    clear
    flask run
}

flask_restart(){
    clear    
    sudo rm -f ../instance/*.sqlite ../instance/*.db
    flask run
}

bashrc_refresh(){
    local mode="$1"

    if [ -z "$mode" ]; then
        echo "❌ Uso: bashrc_refresh <remote|local>"
        return 1
    fi

    case "$mode" in
        remote)
            local prev_dir
            prev_dir="$(pwd)"
            cd ~/bashrc || { echo "❌ No pude entrar a ~/bashrc"; return 1; }
            git pull || { cd "$prev_dir"; return 1; }
            . ~/.bashrc
            cd "$prev_dir" || return 1
            ;;
        local)
            . ~/.bashrc
            ;;
        *)
            echo "❌ Modo inválido. Usa 'remote' o 'local'."
            return 1
            ;;
    esac
}

test_all(){
    python -m unittest discover
}

watchdog(){
    watchmedo shell-command --patterns="*.py" --recursive command='python -m unittest discover -s tests -v' .
}

watchdog_always(){
    nohup watchmedo shell-command --patterns="*.py" --recursive --command='python -m unittest discover -s tests -v' . &
}

port_check() {
    sudo lsof -i :"$1"
}

port_kill() {
    sudo kill -9 "$1"
}

ssh_iniciar() {
    eval "$(ssh-agent -s)"
}

ssh_generar() {
  if [ -z "$1" ]; then
    echo "❌ Error: Debes proporcionar un nombre para la clave."
    return 1
  fi

  # Definir el nombre del archivo de la clave
  local nombre_clave="$1"
  
  echo "🔑 Iniciando la generación de la clave SSH sin contraseña..."

  # Mensaje sobre los parámetros recibidos
  echo "📝 Nombre de la clave: $nombre_clave"
  echo "🔒 La clave no tendrá contraseña."

  # Generar la clave SSH ED25519 sin passphrase
  echo "⚙️ Generando clave SSH con el algoritmo ED25519..."
  ssh-keygen -t ed25519 -C "$nombre_clave" -f "$HOME/.ssh/$nombre_clave" -N ""

  # Verificar si la clave pública fue generada
  local pub_key="$HOME/.ssh/${nombre_clave}.pub"
  if [ -f "$pub_key" ]; then
    echo "✅ Clave SSH generada con éxito para '$nombre_clave'."

    # Mostrar contenido de la clave pública
    echo "📜 Contenido de la clave pública generada:"
    cat "$pub_key"

    echo "🎉 ¡La clave pública ha sido mostrada exitosamente!"
  else
    echo "❌ Error: No se pudo generar la clave pública. Revisa los errores anteriores."
    return 1
  fi
}

ssh_activar() {
    
    if [ -z "$1" ]; then
        echo "Usage: ssh_activar <key_filename>"
        return 1
    fi
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/"$1"
}

tree_list(){
    tree -I 'node_modules|venv|.git|__pycache__|dist|build|.pytest_cache|.vscode|.idea|coverage' -a
}

tree_install(){
    sudo apt install tree -y
}

server-setup() {

    OS=$1

    if [[ "$OS" != "debian" && "$OS" != "ubuntu" ]]; then
        echo ""
        echo "Uso:"
        echo "server-setup debian"
        echo "server-setup ubuntu"
        echo ""
        return 1
    fi

    echo "======================================="
    echo "Base Server Setup"
    echo "OS: $OS"
    echo "======================================="

    sudo apt update -y
    sudo apt upgrade -y

    sudo apt install -y \
        curl \
        wget \
        git \
        unzip \
        zip \
        nginx \
        certbot \
        python3-certbot-nginx \
        jq \
        htop \
        dnsutils \
        net-tools \
        build-essential \
        ca-certificates \
        gnupg

    echo ""
    echo "Instalando Node.js LTS..."

    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs

    echo ""
    echo "Instalando PM2..."

    sudo npm install -g pm2

    sudo systemctl enable nginx
    sudo systemctl start nginx

    echo ""
    echo "======================================="
    echo "Servidor preparado correctamente"
    echo "======================================="
}

site-deploy() {

    DOMAIN=$1
    WEBROOT=$(pwd)

    if [ -z "$DOMAIN" ]; then
        echo ""
        echo "Uso:"
        echo "site-deploy dominio.com"
        echo ""
        return 1
    fi

    echo ""
    echo "======================================="
    echo "Site Deploy"
    echo "Domain : $DOMAIN"
    echo "WebRoot: $WEBROOT"
    echo "======================================="

    sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN;

    root $WEBROOT;
    index index.html;

    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime on;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

    sudo ln -sf \
        /etc/nginx/sites-available/$DOMAIN \
        /etc/nginx/sites-enabled/$DOMAIN

    sudo rm -f /etc/nginx/sites-enabled/default

    sudo nginx -t || return 1

    sudo systemctl reload nginx

    echo ""
    echo "======================================="
    echo "Solicitando SSL..."
    echo "======================================="

    sudo certbot \
        --nginx \
        -d "$DOMAIN" \
        --redirect \
        --agree-tos \
        --register-unsafely-without-email \
        --non-interactive

    echo ""
    echo "======================================="
    echo "Sitio desplegado correctamente"
    echo "======================================="
    echo "URL : https://$DOMAIN"
    echo "ROOT: $WEBROOT"
    echo "======================================="
}
