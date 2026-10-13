# teclab-mixt

Imatge d'espai de treball compartida per a la demo d'avaluació de **Coder** i
**JupyterHub** al Teclab (laboratori d'IA de la UJI): VS Code al navegador, notebooks,
Python 3.12, Node LTS i accés a la passarel·la LLM de `api.mesalles.org`. Una sola
imatge per a les dues eines, per demostrar que el codi és portable.

## Contingut de la imatge

| Peça | Versió |
|---|---|
| Python (base `python:3.12.15-slim-bookworm`) + `uv` | 3.12.15 / 0.13.0 |
| Node.js LTS | 24.21.0 |
| JupyterLab / ipykernel | 4.6.4 / 7.4.0 |
| `jupyterhub` (aporta `jupyterhub-singleuser`, mateixa versió que el hub) | 6.0.1 |
| `jupyter-server-proxy` + `jupyter-code-server` (VS Code al launcher) | 4.6.0 / 1.2 |
| code-server (VS Code al navegador) | 4.141.0 |
| `openai` (client compatible amb la passarel·la) | 3.29.0 |
| git, ruff, detect-secrets | — / 0.17.0 / 1.5.0 |
| PocketBase (binari a `/opt/pocketbase`, no s'engega) | 0.40.5 |

Usuari `teclab` (uid 1000), directori de treball `/home/teclab/work`, exemples a
`/home/teclab/examples`. Mida: uns 2,1 GB.

## Variables d'entorn de l'espai

| Variable | Valor |
|---|---|
| `LITELLM_BASE_URL` | `https://api.mesalles.org/v1` (per defecte a la imatge) |
| `LITELLM_KEY` | Clau virtual creada a `https://api.mesalles.org/ui` → *Virtual Keys*. **La posa l'eina (Coder o JupyterHub) a l'entorn de l'espai; mai a la imatge ni al git.** |
| `LITELLM_MODEL` | `qwen3:8b` per defecte (model local via Ollama) |

## Exemples

- `examples/resum.py`: demana un resum curt a la passarel·la i mostra model, tokens i temps.
- `examples/resum.ipynb`: el mateix en notebook, més la llista de models disponibles.

`qwen3:8b` és un model de raonament: els exemples usen `max_tokens=1500` perquè el
contingut no arribi buit.

## Construir i provar en local

```bash
docker build -t teclab-mixt:0.1.0 .

# Clau de prova a .env (ignorat per git), vegeu .env.example
cp .env.example .env   # i omple LITELLM_KEY

# Des del mateix servidor, el domini públic no fa hairpin: resol-lo a l'host, on Caddy escolta
docker run --rm --env-file .env --add-host api.mesalles.org:host-gateway teclab-mixt:0.1.0 \
  python /home/teclab/examples/resum.py

# JupyterLab en local (http://localhost:8888)
docker run --rm -p 8888:8888 --env-file .env teclab-mixt:0.1.0
```

A Git Bash de Windows, afegeix `MSYS_NO_PATHCONV=1` davant de `docker run` perquè no
reescrigui les rutes `/home/...`.

## Desplegament

Els compose de Coder i JupyterHub, els blocs de Caddy i les xarxes viuen a
`../docker-stack` (`demo/coder/`, `demo/jupyter/`). Dins de Docker, `api.mesalles.org`
resol a Caddy per la xarxa `demo-edge`. La plantilla de Coder és a `coder/` i la
configuració de JupyterHub a `jupyterhub/` (issues a part).
