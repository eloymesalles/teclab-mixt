# CLAUDE.md

Guia per a Claude Code en aquest repositori. Les regles globals d'usuari
(seguretat, secrets, git, idioma, autorització expressa abans de canviar l'estat del
sistema) s'apliquen sempre; aquí només hi ha el que és específic del projecte.

## Què és

Imatge d'espai de treball **`teclab-mixt`** per a la demo d'avaluació de dos entorns
d'escriptori gestionats al Teclab (laboratori d'IA de la UJI): **Coder** i
**JupyterHub**, de costat, a `coder.mesalles.org` i `jupyter.mesalles.org`. Una sola
imatge que els dos fan servir (plantilla de Coder i *single-user image* de JupyterHub)
per demostrar que el codi és portable entre els dos.

- `Dockerfile` — Python 3.12, Node LTS, JupyterLab, code-server, `openai`, git, ruff,
  detect-secrets, PocketBase (binari, no s'engega), exemples. **Versions fixades**, mai
  `:latest`.
- `examples/` — `resum.py` i un notebook que criden la passarel·la LiteLLM
  (`LITELLM_BASE_URL`, `LITELLM_KEY`) per obtenir una resposta real de l'Ollama local.
- `coder/` — plantilla Terraform (proveïdor Docker) que usa la imatge.
- `jupyterhub/` — `jupyterhub_config.py` (DockerSpawner) que usa la imatge.

El desplegament (compose de cada eina, blocs de Caddy, xarxes) viu a `../docker-stack`
(`demo/coder/`, `demo/jupyter/`). És una **demo**, no producció: ha de funcionar i
veure's bé amb la mínima petjada; la base de producció (panell, passarel·la, Ollama)
no s'ha de tocar.

## Punts delicats

- **Secrets**: la clau de LiteLLM arriba com a variable d'entorn de l'espai
  (`LITELLM_KEY`); mai al Dockerfile, als exemples ni al git. Per a proves locals, un
  `.env` ignorat per git.
- **Passarel·la**: els espais parlen amb `https://api.mesalles.org/v1` (compatible amb
  OpenAI). Dins de Docker, el nom resol a Caddy per la xarxa `demo-edge` (àlies), no a
  Internet. Model per defecte dels exemples: `qwen3:8b` (model de raonament: cal un
  `max_tokens` generós o el contingut arriba buit).
- **Recursos**: cada espai, 2 vCPU i 3 GiB com a màxim; aturada per inactivitat a 30 min
  a les dues eines. Docker Desktop (WSL2) té 16 GB per a tots els contenidors.
- **Superfície pública**: JupyterHub va darrere d'oauth2-proxy; Coder té autenticació
  pròpia (excepció acceptada per a la demo).
- **Socket de Docker**: el reben Coder i JupyterHub (necessari); els espais de treball,
  mai.

## Flux de treball — OBLIGATORI

Igual que als altres repos: issue amb plantilla de `.github/ISSUE_TEMPLATE/` →
branca `feature/…`, `fix/…`, `chore/…`, `docs/…` → commits amb Conventional Commits →
PR amb `closes #N` (comprovar `closingIssuesReferences`; si és buit, mutació
`addCloseIssueReferences` com a `local-llm-admin`) → fusió només quan l'usuari ho digui.
Cossos d'issues i PRs amb `--body-file` (fitxer UTF-8). Cap desplegament, build de
producció ni canvi d'estat del sistema sense autorització expressa al xat.
