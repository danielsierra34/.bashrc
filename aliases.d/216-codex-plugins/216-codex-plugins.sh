########################################################################################## CODEX PLUGINS

codex_plugin_marketplace_add_source() {
    if [ -z "$1" ]; then
        echo "Uso: codex_plugin_marketplace_add_source <fuente> [--ref REF] [--sparse PATH]"
        return 1
    fi

    codex plugin marketplace add "$@"
}

codex_plugin_marketplace_list_sources() {
    codex plugin marketplace list "$@"
}

codex_plugin_marketplace_upgrade_sources() {
    codex plugin marketplace upgrade "$@"
}

codex_plugin_marketplace_remove_source() {
    if [ -z "$1" ]; then
        echo "Uso: codex_plugin_marketplace_remove_source <marketplace-name>"
        return 1
    fi

    codex plugin marketplace remove "$@"
}

codex_plugin_install_named() {
    local plugin_name
    plugin_name="$1"
    shift || true

    if [ -z "$plugin_name" ]; then
        echo "Uso: codex_plugin_install_named \"Plugin Name\" [opciones]"
        return 1
    fi

    codex plugin add "$plugin_name" "$@"
}

codex_plugin_install() {
    codex_plugin_install_named "$@"
}

codex_plugin_list_installed() {
    codex plugin list "$@"
}

codex_plugin_list_available() {
    codex plugin list --available --json "$@"
}

codex_plugin_remove_installed() {
    if [ -z "$1" ]; then
        echo "Uso: codex_plugin_remove_installed <plugin[@marketplace]>"
        return 1
    fi

    codex plugin remove "$@"
}

_codex_plugin_system_name() {
    case "$1" in
        airtable) printf '%s' 'Airtable' ;;
        asana) printf '%s' 'Asana' ;;
        atlassian-rovo) printf '%s' 'Atlassian Rovo' ;;
        box) printf '%s' 'Box' ;;
        canva) printf '%s' 'Canva' ;;
        cloudflare) printf '%s' 'Cloudflare' ;;
        codex-security) printf '%s' 'Codex Security' ;;
        figma) printf '%s' 'Figma' ;;
        gmail) printf '%s' 'Gmail' ;;
        google-calendar) printf '%s' 'Google Calendar' ;;
        google-drive) printf '%s' 'Google Drive' ;;
        google-docs) printf '%s' 'Google Docs' ;;
        google-sheets) printf '%s' 'Google Sheets' ;;
        google-slides) printf '%s' 'Google Slides' ;;
        granola) printf '%s' 'Granola' ;;
        heygen) printf '%s' 'HeyGen' ;;
        hubspot) printf '%s' 'HubSpot' ;;
        hyperframes) printf '%s' 'HyperFrames by HeyGen' ;;
        linear) printf '%s' 'Linear' ;;
        monday-com) printf '%s' 'Monday.com' ;;
        neon-postgres) printf '%s' 'Neon Postgres' ;;
        notion) printf '%s' 'Notion' ;;
        openai-developers) printf '%s' 'OpenAI Developers' ;;
        outlook-calendar) printf '%s' 'Outlook Calendar' ;;
        outlook-email) printf '%s' 'Outlook Email' ;;
        posthog) printf '%s' 'PostHog' ;;
        replit) printf '%s' 'Replit' ;;
        remotion) printf '%s' 'Remotion' ;;
        semrush) printf '%s' 'Semrush' ;;
        sentry) printf '%s' 'Sentry' ;;
        sharepoint) printf '%s' 'SharePoint' ;;
        slack) printf '%s' 'Slack' ;;
        stripe) printf '%s' 'Stripe' ;;
        supabase) printf '%s' 'Supabase' ;;
        teams) printf '%s' 'Teams' ;;
        vercel) printf '%s' 'Vercel' ;;
        *)
            return 1
            ;;
    esac
}

codex_plugin_systems() {
    cat <<'EOF'
Supported system keys:
- airtable
- asana
- atlassian-rovo
- box
- canva
- cloudflare
- codex-security
- figma
- gmail
- google-calendar
- google-drive
- google-docs
- google-sheets
- google-slides
- granola
- heygen
- hubspot
- hyperframes
- linear
- monday-com
- neon-postgres
- notion
- openai-developers
- outlook-calendar
- outlook-email
- posthog
- replit
- remotion
- semrush
- sentry
- sharepoint
- slack
- stripe
- supabase
- teams
- vercel
EOF
}

codex_plugin_install_system() {
    local system_name plugin_name
    system_name="$1"
    shift || true

    if [ -z "$system_name" ]; then
        echo "Uso: codex_plugin_install_system <system-key> [opciones]"
        codex_plugin_systems
        return 1
    fi

    plugin_name="$(_codex_plugin_system_name "$system_name")"
    if [ -z "$plugin_name" ]; then
        echo "Sistema no soportado: $system_name"
        codex_plugin_systems
        return 1
    fi

    codex_plugin_install_named "$plugin_name" "$@"
}

codex_plugin_install_systems() {
    local system_key plugin_name missing=0

    if [ "$#" -eq 0 ]; then
        echo "Uso: codex_plugin_install_systems <system-key> [system-key ...]"
        return 1
    fi

    for system_key in "$@"; do
        plugin_name="$(_codex_plugin_system_name "$system_key")"
        if [ -z "$plugin_name" ]; then
            echo "Sistema no soportado: $system_key"
            missing=1
            continue
        fi

        codex_plugin_install_named "$plugin_name" || missing=1
    done

    return "$missing"
}

codex_plugin_bootstrap() {
    if ! command -v codex >/dev/null 2>&1; then
        echo "No se encontro el binario 'codex'. Instala o activa Codex primero."
        return 1
    fi

    echo "Codex detectado en: $(command -v codex)"
    codex_plugin_marketplace_list_sources
}
