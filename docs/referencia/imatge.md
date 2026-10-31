# La imatge: eines i versions

L'espai arranca des de la imatge `teclab-mixt`, que porta estes eines amb versió fixada. Les
versions corresponen a la imatge 0.5.0.

| Peça | Versió | Per a què |
|---|---|---|
| Python (base `python:3.12-slim-bookworm`) + `uv` | 3.12.15 / 0.13.0 | Llenguatge principal; `uv` instal·la paquets ràpid |
| Node.js LTS | 24.21.0 | JavaScript; necessari per a VS Code i Claude Code |
| JupyterLab / ipykernel | 4.6.4 / 7.4.0 | Notebooks |
| code-server | 4.141.0 | VS Code al navegador |
| `openai` (client Python) | 3.29.0 | Cridar la passarel·la |
| `psycopg` + client `psql` 16 | 3.3.6 / 16.15 | Base de dades de l'espai (`psql`, `pg_dump`, `pg_isready`) |
| Claude Code (`@anthropic-ai/claude-code`) | 2.1.300 | Agent de codi al terminal (`claude`, `claude-compte`) |
| `pydantic-ai-slim[openai]` + `langgraph` | 2.54.0 / 1.2.12 | SDK d'agents |
| `opentelemetry-sdk` + `opentelemetry-exporter-otlp` | 1.45.0 | Traces dels agents |
| git, ruff, detect-secrets | — / 0.17.0 / 1.5.0 | Control de versions, qualitat, detecció de secrets |
| `gh` (CLI de GitHub) | 2.102.0 | Repositoris de GitHub des del terminal |
| PocketBase (binari a `/opt/pocketbase`) | 0.40.5 | Backend lleuger; no s'engega per defecte |
| Eines del sistema | — | `curl`, `nano`, `less`, `unzip`, `openssh-client` |

## Usuari i carpetes

- Usuari `teclab` (no és root). No pots instal·lar paquets del sistema amb `apt`.
- Carpeta de treball: `/home/teclab/work`. VS Code s'hi obri directament.
- Exemples: `/home/teclab/examples` (còpia de la imatge) i `/home/teclab/work/examples`
  (la teua còpia, per a modificar-la).
- Tot `/home/teclab` és al disc persistent de l'espai.

## El que no hi ha

- Cap SDK d'un proveïdor concret (OpenAI Agents SDK, Claude Agent SDK, Google ADK) ni
  LangChain complet: si el teu projecte en necessita un, l'instal·les tu i ho justifiques a
  l'Estudi d'Integració.
- Cap clau d'API ni adreça de cap plataforma: tot arriba per l'entorn de l'espai.
- Docker: l'espai és un contenidor i no en pot crear d'altres.
