## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

## Graphify + Codex

- WSL Debian is the execution environment for project tools.
- If Codex is running from Windows or PowerShell, switch into WSL Debian before invoking Graphify.
- Graphify is installed inside WSL Debian and should not be treated as a connector, plugin, or external integration.
- Apply the same project integration flow for Codex and Claude when Graphify is available.
- For codebase questions, consult Graphify first whenever `graphify-out/graph.json` exists.
- Do not require the user to type `/graphify` or mention Graphify explicitly.
- Prefer `graphify query "<question>"` first.
- Use `graphify explain "<concept>"` for specific concepts.
- Use `graphify path "<A>" "<B>"` for relationships.
- If a query returns `No matching nodes found`, retry with more specific real file, class, function, or component names before abandoning Graphify.
- Use `graphify-out/GRAPH_REPORT.md` for broad architectural analysis.
- Use `graphify-out/wiki/index.md` if it exists for general navigation.
- After modifying code, run `graphify update .`.
- Graphify is the first pass for locating relevant codebase areas; Codex can then inspect the source files Graphify identified.

<!-- BEGIN GRAPHIFY-CODEX CUSTOM -->

## Graphify + Codex

- WSL Debian is the execution environment for project tools.
- If Codex is running from Windows or PowerShell, switch into WSL Debian before invoking Graphify.
- Graphify is installed inside WSL Debian and should not be treated as a connector, plugin, or external integration.
- Apply the same project integration flow for Codex, Claude, and Antigravity when Graphify is available.
- For codebase questions, consult Graphify first whenever `graphify-out/graph.json` exists.
- Do not require the user to type `/graphify` or mention Graphify explicitly.
- Prefer `graphify query "<question>"` first.
- Use `graphify explain "<concept>"` for specific concepts.
- Use `graphify path "<A>" "<B>"` for relationships.
- If a query returns `No matching nodes found`, retry with more specific real file, class, function, or component names before abandoning Graphify.
- Use `graphify-out/GRAPH_REPORT.md` for broad architectural analysis.
- Use `graphify-out/wiki/index.md` if it exists for general navigation.
- After modifying code, run `graphify update .`.
- Graphify is the first pass for locating relevant codebase areas; Codex can then inspect the source files Graphify identified.

<!-- END GRAPHIFY-CODEX CUSTOM -->
