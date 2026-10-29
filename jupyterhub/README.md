# Configuració de JupyterHub «teclab-mixt»

`jupyterhub_config.py` fa que cada usuari tingui un contenidor amb la imatge
`teclab-mixt:0.3.0` (la mateixa que Coder): JupyterLab a `/home/teclab/work` i, al
launcher, **VS Code** (code-server via `jupyter-code-server`) i **terminal**. Els exemples
es copien a `work/examples/` en arrencar. Al terminal també hi ha **Claude Code**
(`claude-compte`, amb la llicència de Claude de la UJI; `claude` per la passarel·la només si
el hub posa `CLAUDE_MODEL_SONNET` i la passarel·la té models de Claude, cosa que la demo no
té); vegeu el README de l'arrel; no cal cap configuració al hub.

## Com funciona

- **Spawner**: `TeclabSpawner` (DockerSpawner) amb la imatge local (`pull_policy never`),
  xarxa privada `demo-jupyter` i, després d'arrencar, connexió a `demo-edge` perquè
  `api.mesalles.org` resolgui a Caddy. `mem_limit 3G`, `cpu_limit 2`, volum
  `jupyterhub-user-<usuari>` a `/home/teclab`, contenidor esborrat en aturar (el home
  persisteix). Entorn: `LITELLM_BASE_URL`, `LITELLM_KEY`, `LITELLM_MODEL`. Cap permís
  extra (el `seccomp=unconfined` del sandbox de Codex ja no cal); l'espai continua sense
  capacitats ni socket.
- **Autenticació**: `GoogleOAuthenticator` amb el client de Google de l'stack; només els
  correus de `TECLAB_ALLOWED_EMAILS` (el primer és administrador). Redirect URI al client
  de Google: `https://jupyter.mesalles.org/hub/oauth_callback`. A més, a docker-stack el
  hub va darrere d'oauth2-proxy (no es veu res sense sessió).
- **Idle culler**: els servidors s'aturen als 30 minuts d'inactivitat.
- **Hub**: SQLite i secret de cookie a `/srv/jupyterhub/data` (volum), `hub_connect_ip`
  = nom del servei, `trust_xheaders`.

## Variables que llegeix el hub

| Variable | Origen |
|---|---|
| `TECLAB_LITELLM_KEY` | `.env` de docker-stack; va a l'entorn de cada espai com a `LITELLM_KEY` |
| `TECLAB_ALLOWED_EMAILS` | `.env` de docker-stack, correus separats per comes |
| `LLM_GOOGLE_CLIENT_ID` / `LLM_GOOGLE_CLIENT_SECRET` | `.env` de docker-stack (client compartit) |
| `TECLAB_IMAGE` | opcional, per defecte `teclab-mixt:0.3.0` (docker-stack la fixa al compose) |

## Desplegament

Compose del hub (imatge amb `dockerspawner`, `oauthenticator` i `jupyterhub-idle-culler`,
socket de Docker, xarxes i variables) a docker-stack `demo/jupyter/`. Aquest fitxer es
munta al contenidor del hub com a `/srv/jupyterhub/jupyterhub_config.py`.
