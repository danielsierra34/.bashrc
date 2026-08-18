# 215-github-cli

Herramientas para instalar y autenticar GitHub CLI desde Bash.

## Funciones
- `github_cli_setup`: instala `gh` si hace falta, hace login con `gh auth login --web`, y valida el estado.
- `github_cli_repo_bootstrap`: verifica que el repo actual tenga remoto `origin` y que `gh` pueda verlo.
- `github_board_setup`: valida `gh`, el repo actual y deja listo el flujo para GitHub Projects V2.
- `github_board_create_issues_from_markdown [--dry-run] [archivo]`: crea issues de GitHub a partir de `project/tablero/tarjetas.md` o los simula sin publicarlos.
- `github_board_attach_issues_to_project [--dry-run] [nombre-proyecto]`: agrega las issues `epic` y `feature` a un GitHub Project V2, evitando duplicados si ya estan dentro.
