# 215-github-cli

Herramientas para instalar y autenticar GitHub CLI desde Bash.

## Funciones
- `github_cli_setup`: instala `gh` si hace falta, hace login con `gh auth login --web`, y valida el estado.
- `github_cli_repo_bootstrap`: verifica que el repo actual tenga remoto `origin` y que `gh` pueda verlo.
