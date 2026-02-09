########################################################################################## IOT
cupcarbon_docker_build(){
    if [ -z "$1" ]; then
        echo "Usage: cupcarbon_docker_build <zip_or_dir> [tag]"
        return 1
    fi

    local src="$1"
    local tag="${2:-cupcarbon:novnc}"
    local workdir=""

    if [ -f "$src" ] && [[ "$src" == *.zip ]]; then
        local base_dir
        base_dir="$(dirname "$src")"
        unzip -o "$src" -d "$base_dir" >/dev/null
        workdir="$base_dir/cupcarbon_docker"
    else
        workdir="$src"
    fi

    if [ ! -d "$workdir" ]; then
        echo "Error: directory not found: $workdir"
        return 1
    fi

    local df="$workdir/dockerfile"
    if [ ! -f "$df" ]; then
        if [ -f "$workdir/Dockerfile" ]; then
            df="$workdir/Dockerfile"
        else
            echo "Error: Dockerfile not found in $workdir"
            return 1
        fi
    fi

    docker build --no-cache -t "$tag" -f "$df" "$workdir"
}

cupcarbon_docker_run(){
    local tag="${1:-cupcarbon:novnc}"
    local vnc_pass="${2:-${VNC_PASSWORD:-ClaveSegura123}}"
    docker run -it --rm \
        -p 6080:6080 \
        -p 5901:5901 \
        -e VNC_PASSWORD="$vnc_pass" \
        "$tag"
}

cupcarbon_docker_help(){
    echo "Build: cupcarbon_docker_build <zip_or_dir> [tag]"
    echo "Run:   cupcarbon_docker_run [tag] [vnc_password]"
    echo "URL:   http://localhost:6080/vnc.html"
}
