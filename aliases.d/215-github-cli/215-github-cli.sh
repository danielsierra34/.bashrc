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

github_board_setup() {
    local repo_root repo_url repo_slug

    if ! command -v gh >/dev/null 2>&1; then
        echo "Primero ejecuta: github_cli_setup"
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Debes ejecutar esto dentro de un repositorio Git."
        return 1
    fi

    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    repo_url="$(git remote get-url origin 2>/dev/null)"

    if [ -z "$repo_url" ]; then
        echo "No se encontro un remoto 'origin'."
        return 1
    fi

    repo_slug="$repo_url"
    repo_slug="${repo_slug#git@github.com:}"
    repo_slug="${repo_slug#https://github.com/}"
    repo_slug="${repo_slug%.git}"

    echo "Repositorio: $repo_slug"
    echo "Raiz local: $repo_root"

    if gh auth status >/dev/null 2>&1; then
        echo "GitHub CLI autenticado."
    else
        echo "GitHub CLI no esta autenticado. Ejecuta: github_cli_setup"
        return 1
    fi

    if gh repo view "$repo_slug" >/dev/null 2>&1; then
        echo "Repositorio accesible desde gh."
    else
        echo "No se pudo acceder al repositorio con gh."
        return 1
    fi

    echo "Siguiente paso sugerido:"
    echo "1. Crear o vincular el proyecto del grupo en GitHub Projects V2."
    echo "2. Crear issues/tarjetas para las tareas semanales."
    echo "3. Sincronizar las issues al Project V2."
    echo "4. Moverlas por estados: Todo, In progress, Done."
}

github_board_create_issues_from_markdown() {
    local backlog_file repo_root repo_slug line created_count
    local current_epic_title current_epic_track current_epic_description current_mode
    local feature_title feature_body
    local dry_run=0
    local arg

    if ! command -v gh >/dev/null 2>&1; then
        echo "Primero ejecuta: github_cli_setup"
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Debes ejecutar esto dentro de un repositorio Git."
        return 1
    fi

    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    repo_slug="$(git remote get-url origin 2>/dev/null)"
    if [ -z "$repo_slug" ]; then
        echo "No se encontro un remoto 'origin'."
        return 1
    fi

    repo_slug="${repo_slug#git@github.com:}"
    repo_slug="${repo_slug#https://github.com/}"
    repo_slug="${repo_slug%.git}"

    backlog_file="$repo_root/project/tablero/tarjetas.md"
    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                dry_run=1
                ;;
            --help|-h)
                echo "Uso: github_board_create_issues_from_markdown [--dry-run] [archivo]"
                echo "  --dry-run  Muestra los issues que se crearian sin publicarlos."
                echo "  archivo    Ruta al markdown de tarjetas. Por defecto: project/tablero/tarjetas.md"
                return 0
                ;;
            *)
                backlog_file="$arg"
                ;;
        esac
    done

    if [ ! -f "$backlog_file" ]; then
        echo "No existe el backlog: $backlog_file"
        return 1
    fi

    ensure_board_label() {
        local label_name label_description label_color
        label_name="$1"
        label_description="$2"
        label_color="$3"

        if [ "$dry_run" -eq 1 ]; then
            return 0
        fi

        if gh label list --repo "$repo_slug" --limit 200 | cut -f1 | grep -Fxq "$label_name"; then
            return 0
        fi

        gh label create "$label_name" \
            --repo "$repo_slug" \
            --description "$label_description" \
            --color "$label_color" >/dev/null
    }

    ensure_board_label "epic" "Epica del proyecto" "8250df"
    ensure_board_label "feature" "Feature del proyecto" "0e8a16"
    ensure_board_label "web" "Trabajo del componente web" "1f77b4"
    ensure_board_label "mobile" "Trabajo del componente movil" "fbca04"

    created_count=0
    current_epic_title=""
    current_epic_track=""
    current_epic_description=""
    current_mode=""

    create_issue_from_board() {
        local title body label_track label_type
        title="$1"
        body="$2"
        label_type="$3"
        label_track="$4"

        if [ -z "$title" ]; then
            return 1
        fi

        if [ "$dry_run" -eq 1 ]; then
            echo "DRY-RUN issue create --repo '$repo_slug' --title '$title' --label '$label_type' --label '$label_track'"
            if [ -n "$body" ]; then
                printf '%s\n' "$body" | sed 's/^/  /'
            fi
        elif [ -n "$body" ]; then
            gh issue create \
                --repo "$repo_slug" \
                --title "$title" \
                --body "$body" \
                --label "$label_type" \
                --label "$label_track"
        else
            gh issue create \
                --repo "$repo_slug" \
                --title "$title" \
                --label "$label_type" \
                --label "$label_track"
        fi

        created_count=$((created_count + 1))
    }

    create_current_epic_if_needed() {
        if [ -n "$current_epic_title" ] && [ "$current_mode" != "created" ]; then
            create_issue_from_board \
                "$current_epic_title" \
                "Fuente: $backlog_file"$'\n'"Categoria: epic"$'\n'"Track: $current_epic_track"$'\n\n'"Descripcion: $current_epic_description" \
                "epic" \
                "$current_epic_track"
            current_mode="created"
        fi
    }

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            "### Epica web 1"*)
                create_current_epic_if_needed
                current_epic_title="Gestion comercial y ciclo de vida de polizas"
                current_epic_track="web"
                current_epic_description=""
                current_mode="epic"
                ;;
            "### Epica web 2"*)
                create_current_epic_if_needed
                current_epic_title="Administracion operativa y de socios de distribucion"
                current_epic_track="web"
                current_epic_description=""
                current_mode="epic"
                ;;
            "### Epica movil 1"*)
                create_current_epic_if_needed
                current_epic_title="Autoservicio del cliente asegurado"
                current_epic_track="mobile"
                current_epic_description=""
                current_mode="epic"
                ;;
            "### Epica movil 2"*)
                create_current_epic_if_needed
                current_epic_title="Reporte y seguimiento de siniestros"
                current_epic_track="mobile"
                current_epic_description=""
                current_mode="epic"
                ;;
            "**Descripcion:**"*)
                if [ "$current_mode" = "epic" ]; then
                    current_epic_description="${line#**Descripcion:** }"
                    current_epic_description="${current_epic_description#**Descripcion:**}"
                    current_epic_description="${current_epic_description# }"
                fi
                ;;
            "**Tarjetas asociadas:**"*)
                if [ "$current_mode" = "epic" ]; then
                    create_current_epic_if_needed
                    current_mode="features"
                fi
                ;;
            "- "*)
                if [ "$current_mode" = "features" ] && [ -n "$current_epic_track" ]; then
                    feature_title="${line#- }"
                    feature_body="Fuente: $backlog_file"$'\n'"Categoria: feature"$'\n'"Track: $current_epic_track"$'\n\n'"Descripcion: $feature_title"$'\n'"Epica relacionada: $current_epic_title"
                    create_issue_from_board "$feature_title" "$feature_body" "feature" "$current_epic_track"
                fi
                ;;
        esac
    done < "$backlog_file"

    create_current_epic_if_needed

    echo "Issues creados: $created_count"
}

github_board_attach_issues_to_project() {
    local project_name dry_run repo_slug repo_root repo_owner repo_name
    local project_json project_id project_item_json existing_ids issue_json
    local issue_count issue_id issue_number issue_title line
    local arg

    if ! command -v gh >/dev/null 2>&1; then
        echo "Primero ejecuta: github_cli_setup"
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Debes ejecutar esto dentro de un repositorio Git."
        return 1
    fi

    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    repo_slug="$(git remote get-url origin 2>/dev/null)"
    if [ -z "$repo_slug" ]; then
        echo "No se encontro un remoto 'origin'."
        return 1
    fi

    repo_slug="${repo_slug#git@github.com:}"
    repo_slug="${repo_slug#https://github.com/}"
    repo_slug="${repo_slug%.git}"
    repo_owner="${repo_slug%%/*}"

    project_name="Proyecto de Grado 1"
    dry_run=0

    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                dry_run=1
                ;;
            --help|-h)
                echo "Uso: github_board_attach_issues_to_project [--dry-run] [nombre-proyecto]"
                echo "  --dry-run       Muestra los cambios sin ejecutar gh issue edit."
                echo "  nombre-proyecto Nombre exacto del GitHub Project."
                return 0
                ;;
            *)
                project_name="$arg"
                ;;
        esac
    done

    echo "Repositorio: $repo_slug"
    echo "Proyecto: $project_name"

    if gh auth status >/dev/null 2>&1; then
        :
    else
        echo "GitHub CLI no esta autenticado. Ejecuta: github_cli_setup"
        return 1
    fi

    project_json="$(
        gh api graphql -f query='query($org:String!){ organization(login:$org){ id projectsV2(first:100){ nodes { id title number } } } }' \
            -F org="$repo_owner"
    )"

    project_id="$(
        python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); target=sys.argv[1]; nodes=data["data"]["organization"]["projectsV2"]["nodes"]; 
for node in nodes:
    if node["title"] == target:
        print(node["id"])
        raise SystemExit(0)
raise SystemExit(1)' "$project_name" <<<"$project_json"
    )" || {
        echo "No se encontro un Project V2 llamado '$project_name' en la organizacion '$repo_owner'."
        echo "Crea el proyecto primero o usa otro nombre."
        return 1
    }

    project_item_json="$(
        gh api graphql -f query='query($id:ID!){ node(id:$id){ ... on ProjectV2 { items(first:100){ nodes { content { ... on Issue { id number title } } } } } } }' \
            -F id="$project_id"
    )"

    existing_ids="$(
        python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); items=data["data"]["node"]["items"]["nodes"];
for item in items:
    content = item.get("content")
    if content and content.get("id"):
        print(content["id"])' <<<"$project_item_json"
    )"

    issue_count=0

    add_issue_to_project() {
        local issue_id="$1"
        local issue_number="$2"
        local issue_title="$3"

        if printf '%s\n' "$existing_ids" | grep -Fxq "$issue_id"; then
            echo "SKIP issue $issue_number: ya estaba en el Project V2."
            return 0
        fi

        if [ "$dry_run" -eq 1 ]; then
            echo "DRY-RUN gh api graphql addProjectV2ItemById issue=$issue_number project=$project_name"
            return 0
        fi

        gh api graphql -f query='mutation($projectId:ID!, $contentId:ID!){ addProjectV2ItemById(input:{projectId:$projectId, contentId:$contentId}){ item { id } } }' \
            -F projectId="$project_id" \
            -F contentId="$issue_id" >/dev/null
        echo "ADD issue $issue_number: $issue_title"
        issue_count=$((issue_count + 1))
    }

    while IFS=$'\t' read -r issue_id issue_number issue_title; do
        [ -z "$issue_id" ] && continue
        add_issue_to_project "$issue_id" "$issue_number" "$issue_title"
    done < <(
        gh issue list --repo "$repo_slug" --state all --label epic --limit 100 --json id,number,title --jq '.[] | "\(.id)\t\(.number)\t\(.title)"'
        gh issue list --repo "$repo_slug" --state all --label feature --limit 100 --json id,number,title --jq '.[] | "\(.id)\t\(.number)\t\(.title)"'
    )

    echo "Project V2 listo: $project_name"
    echo "Issues agregadas nuevas: $issue_count"
}

github_board_create_user_stories_from_markdown() {
    local stories_file repo_root repo_slug repo_owner line
    local dry_run=0 project_name="Proyecto de Grado 1"
    local current_story_code="" current_story_text="" current_story_track=""
    local current_story_epic="" current_criteria="" current_mode=""
    local story_title story_body story_label story_id
    local project_json project_id existing_ids project_item_json story_count
    local arg

    if ! command -v gh >/dev/null 2>&1; then
        echo "Primero ejecuta: github_cli_setup"
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Debes ejecutar esto dentro de un repositorio Git."
        return 1
    fi

    repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    repo_slug="$(git remote get-url origin 2>/dev/null)"
    if [ -z "$repo_slug" ]; then
        echo "No se encontro un remoto 'origin'."
        return 1
    fi

    repo_slug="${repo_slug#git@github.com:}"
    repo_slug="${repo_slug#https://github.com/}"
    repo_slug="${repo_slug%.git}"
    repo_owner="${repo_slug%%/*}"

    stories_file="$repo_root/project/historias-usuario/versiones/v001.md"
    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                dry_run=1
                ;;
            --project)
                current_mode="project-arg"
                ;;
            --help|-h)
                echo "Uso: github_board_create_user_stories_from_markdown [--dry-run] [archivo]"
                echo "  --dry-run  Muestra los issues que se crearian sin publicarlos."
                echo "  archivo    Ruta al markdown de historias. Por defecto: project/historias-usuario/versiones/v001.md"
                return 0
                ;;
            *)
                if [ "$current_mode" = "project-arg" ]; then
                    project_name="$arg"
                    current_mode=""
                else
                    stories_file="$arg"
                fi
                ;;
        esac
    done

    if [ ! -f "$stories_file" ]; then
        echo "No existe el archivo de historias: $stories_file"
        return 1
    fi

    ensure_board_label() {
        local label_name label_description label_color
        label_name="$1"
        label_description="$2"
        label_color="$3"

        if [ "$dry_run" -eq 1 ]; then
            return 0
        fi

        if gh label list --repo "$repo_slug" --limit 200 | cut -f1 | grep -Fxq "$label_name"; then
            return 0
        fi

        gh label create "$label_name" \
            --repo "$repo_slug" \
            --description "$label_description" \
            --color "$label_color" >/dev/null
    }

    ensure_board_label "user-story" "Historia de usuario" "5319e7"
    ensure_board_label "web" "Trabajo del componente web" "1f77b4"
    ensure_board_label "mobile" "Trabajo del componente movil" "fbca04"

    project_json="$(
        gh api graphql -f query='query($org:String!){ organization(login:$org){ projectsV2(first:100){ nodes { id title number } } } }' \
            -F org="$repo_owner"
    )"

    project_id="$(
        python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); target=sys.argv[1]; nodes=data["data"]["organization"]["projectsV2"]["nodes"];
for node in nodes:
    if node["title"] == target:
        print(node["id"])
        raise SystemExit(0)
raise SystemExit(1)' "$project_name" <<<"$project_json"
    )" || {
        echo "No se encontro un Project V2 llamado '$project_name'."
        return 1
    }

    project_item_json="$(
        gh api graphql -f query='query($id:ID!){ node(id:$id){ ... on ProjectV2 { items(first:100){ nodes { content { ... on Issue { id number title } } } } } } }' \
            -F id="$project_id"
    )"

    existing_ids="$(
        python3 -c 'import json,sys; data=json.loads(sys.stdin.read()); items=data["data"]["node"]["items"]["nodes"];
for item in items:
    content = item.get("content")
    if content and content.get("id"):
        print(content["id"])' <<<"$project_item_json"
    )"

    story_count=0
    current_mode=""
    current_story_code=""
    current_story_text=""
    current_story_track=""
    current_story_epic=""
    current_criteria=""

    flush_story() {
        if [ -z "$current_story_code" ] || [ -z "$current_story_text" ]; then
            return 0
        fi

        story_title="$current_story_code | $current_story_text"
        story_label="user-story"
        story_body="Fuente: $stories_file"$'\n'"Categoria: historia de usuario"$'\n'"Track: $current_story_track"$'\n'"Epica: $current_story_epic"$'\n\n'"Historia:"$'\n'"Como $current_story_text"$'\n\n'"Criterios de aceptacion:"$'\n'"$current_criteria"

        if [ "$dry_run" -eq 1 ]; then
            echo "DRY-RUN issue create --repo '$repo_slug' --title '$story_title' --label '$story_label' --label '$current_story_track'"
            current_story_code=""
            current_story_text=""
            current_criteria=""
            current_mode=""
            return 0
        fi

        gh issue create \
            --repo "$repo_slug" \
            --title "$story_title" \
            --body "$story_body" \
            --label "$story_label" \
            --label "$current_story_track" >/dev/null

        story_count=$((story_count + 1))
        story_id="$(gh issue list --repo "$repo_slug" --state all --search "$story_title" --limit 1 --json id --jq '.[0].id')"
        if ! printf '%s\n' "$existing_ids" | grep -Fxq "$story_id"; then
            gh api graphql -f query='mutation($projectId:ID!, $contentId:ID!){ addProjectV2ItemById(input:{projectId:$projectId, contentId:$contentId}){ item { id } } }' \
                -F projectId="$project_id" \
                -F contentId="$story_id" >/dev/null
        fi
        echo "ADD $story_title"

        current_story_code=""
        current_story_text=""
        current_criteria=""
        current_mode=""
    }

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            "### Epica web 1:"*)
                flush_story
                current_story_epic="Gestion comercial y ciclo de vida de polizas"
                current_story_track="web"
                ;;
            "### Epica web 2:"*)
                flush_story
                current_story_epic="Administracion operativa y de socios de distribucion"
                current_story_track="web"
                ;;
            "### Epica movil 1:"*)
                flush_story
                current_story_epic="Autoservicio del cliente asegurado"
                current_story_track="mobile"
                ;;
            "### Epica movil 2:"*)
                flush_story
                current_story_epic="Reporte y seguimiento de siniestros"
                current_story_track="mobile"
                ;;
            "#### HU-"*)
                flush_story
                current_story_code="${line#\#\#\#\# }"
                current_story_text=""
                current_criteria=""
                current_mode="story"
                ;;
            "Como "*)
                if [ "$current_mode" = "story" ]; then
                    current_story_text="${line#Como }"
                fi
                ;;
            "**Criterios de aceptacion**"*)
                if [ "$current_mode" = "story" ]; then
                    current_mode="criteria"
                fi
                ;;
            "- "*)
                if [ "$current_mode" = "criteria" ]; then
                    if [ -n "$current_criteria" ]; then
                        current_criteria="$current_criteria"$'\n'
                    fi
                    current_criteria="$current_criteria${line#- }"
                fi
                ;;
        esac
    done < "$stories_file"

    flush_story

    echo "Historias de usuario creadas: $story_count"
}
