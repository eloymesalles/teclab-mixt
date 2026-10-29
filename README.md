# teclab-mixt

Imatge d'espai de treball del Teclab (laboratori d'IA de la UJI): VS Code al navegador,
notebooks, Python 3.12, Node LTS i accés a una passarel·la LLM (LiteLLM). Una sola imatge
per a **dues plataformes**, per demostrar que el codi és portable:

- la **demo** de `mesalles.org` (Coder amb Docker i JupyterHub, `../docker-stack`), que es
  manté com a banc de proves;
- el **sandbox del Teclab a Google Cloud** (`eloymesalles/teclab-gcp`: Coder amb una màquina
  virtual per espai i LiteLLM a `llm-teclab.uji.es`).

La imatge **no sap en quina plataforma corre**: l'adreça de la passarel·la, la clau i la
resta de valors de plataforma arriben sempre per l'entorn de l'espai (taula de sota).

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
| `psycopg` (driver de PostgreSQL) + client `psql` 16 (PGDG) | 3.3.6 / 16.15 |
| Codex CLI (`@openai/codex`, agent de codi al terminal, via la passarel·la) | 0.162.1 |
| `pydantic-ai-slim[openai]` + `langgraph` (SDK d'agents; vegeu `examples/README.md`) | 2.54.0 / 1.2.12 |
| `opentelemetry-sdk` + `opentelemetry-exporter-otlp` (traces dels agents) | 1.45.0 |
| git, ruff, detect-secrets | — / 0.17.0 / 1.5.0 |
| PocketBase (binari a `/opt/pocketbase`, no s'engega) | 0.40.5 |

Usuari `teclab` (uid 1000), directori de treball `/home/teclab/work`, exemples a
`/home/teclab/examples`. Mida: uns 2,2 GB.

## Variables d'entorn de l'espai

| Variable | Valor |
|---|---|
| `LITELLM_BASE_URL` | Adreça de la passarel·la. **Buida a la imatge**: la posa la plataforma. Demo: `https://api.mesalles.org/v1`; Teclab GCP: `https://llm-teclab.uji.es:4443/v1` (nom privat de la VPC, certificat de la CA del Teclab) |
| `LITELLM_KEY` | Clau virtual creada a l'administració de LiteLLM de la plataforma (*Virtual Keys*). **La posa l'eina (Coder o JupyterHub) a l'entorn de l'espai; mai a la imatge ni al git.** |
| `LITELLM_MODEL` | **Àlies del catàleg** de la passarel·la, no un model: `chat-default` (per defecte a la imatge, igual a les dues plataformes). A quin model apunta ho decideix l'administració de LiteLLM |
| `OTEL_SERVICE_NAME`, `OTEL_TRACES_EXPORTER`, `OTEL_EXPORTER_OTLP_ENDPOINT` | Traces OpenTelemetry dels exemples d'agent: nom del servei (la plantilla el posa, `teclab-<propietari>-<espai>`), exportador `otlp`, endpoint buit per defecte (sense exportar) |
| `CODEX_MODEL` | `gpt-6.1-sol` per defecte: model que fa servir Codex CLI (d'OpenAI, via la passarel·la) |
| `DATABASE_URL`, `PGHOST`, `PGUSER`, `PGPASSWORD`, `PGDATABASE` | Només a Coder: la base de dades PostgreSQL pròpia de l'espai (sidecar; vegeu `coder/README.md`). A JupyterHub no hi ha base de dades. |
| `DATA_SOURCE` | `csv` (per defecte) o `postgres`: font de dades d'`examples/dades.py` |
| `TECLAB_CA_CERT` | Ruta del certificat (PEM) de la CA privada del Teclab, muntat al contenidor per la plataforma (Teclab GCP: `/etc/teclab/ca.crt`). Buida a la demo. Vegeu «CA del Teclab» |

## CA del Teclab

Al sandbox de Google Cloud, Coder (`https://plataforma-teclab.uji.es:3443`) i LiteLLM
(`https://llm-teclab.uji.es:4443`) serveixen per dins amb un certificat signat per una **CA
privada del Teclab**. L'espai l'ha de verificar com qualsevol altre: **cap `verify=False`,
cap `curl -k`** enlloc (TLS intern obligatori, ENS mp.com.2).

Ho fa l'script d'entrada `bin/teclab-entrypoint` (`/usr/local/bin/teclab-entrypoint`, executat
per `tini` abans de l'ordre del contenidor), a partir de `TECLAB_CA_CERT`:

- Si la variable és buida o el fitxer no hi és: **no fa res** (la demo arrenca igual).
- Si hi és: escriu `~/.teclab/ca-bundle.pem` = CA públiques del sistema + CA del Teclab (l'usuari
  `teclab` no pot tocar `/etc/ssl`) i exporta, per a tot el que arrenqui dins de l'espai (l'agent
  de Coder, JupyterLab, terminals): `SSL_CERT_FILE`, `CURL_CA_BUNDLE`, `GIT_SSL_CAINFO` i
  `REQUESTS_CA_BUNDLE` cap al paquet combinat (OpenSSL, `curl`, `git`, `psql`, Python `ssl`,
  `httpx`, `requests`, `pip`, `uv`), i `NODE_EXTRA_CA_CERTS` cap a la CA sola (Node l'afegeix
  als seus: code-server, `npm`, Claude Code). Les variables que la plataforma ja hagi fixat no
  se sobreescriuen. El paquet combinat és el que fa que les webs públiques continuïn verificant.

Comprovació en local amb una CA de prova (`openssl`): un servidor `https` dins del contenidor
amb un certificat signat per ella, i `curl`, `httpx`, `requests` i `node -e "fetch(...)"`
contra ell funcionen amb `TECLAB_CA_CERT` i fallen sense (vegeu la PR de la issue #21).

## Codex CLI

Al terminal de l'espai (VS Code a Coder, o terminal del launcher a JupyterHub):

```bash
codex                         # sessió interactiva al directori actual (~/work)
codex "explica què fa examples/resum.py"
```

- **Cap a on apunta**: a la passarel·la de la plataforma (`LITELLM_BASE_URL`, obligatòria)
  amb la clau de l'espai (`LITELLM_KEY`), **mai** a `api.openai.com`. L'espai no té cap
  clau d'OpenAI; LiteLLM reenvia la petició a OpenAI amb la seva. Codex només parla l'API
  Responses, que LiteLLM serveix a `/v1/responses`.
- **Model**: `gpt-6.1-sol` (el recomanat per OpenAI per a Codex; 2 $/10 $ per milió de
  tokens d'entrada/sortida). Es canvia amb `CODEX_MODEL` o amb `codex -m <model>`;
  `gpt-6-luna` és vint vegades més barat però més fluix. **El consum compta contra el
  pressupost de la clau del projecte** a l'administració de LiteLLM de la plataforma.
- **Mode conservador**: `approval_policy = "on-request"` i `sandbox_mode = "read-only"`.
  Llegeix lliurement, però demana confirmació abans d'executar ordres o escriure fitxers.
  El sandbox de Linux de Codex és **bubblewrap** i necessita espais de noms d'usuari sense
  privilegis, que el perfil seccomp per defecte de Docker bloqueja: per això els espais
  de Coder i de JupyterHub arrenquen amb `seccomp=unconfined` (sense capacitats ni
  socket, igualment). En un contenidor sense aquesta opció, Codex no pot executar cap
  ordre (`bwrap: No permissions to create a new namespace`).
- **Configuració**: `~/.codex/config.toml` el genera l'embolcall `/usr/local/bin/codex`
  (font: `bin/codex`) el primer cop que s'executa, a partir de `LITELLM_BASE_URL` i
  `CODEX_MODEL`. No conté cap clau (Codex la llegeix de `LITELLM_KEY` amb `env_key`). Es
  pot editar; per regenerar-lo, esborra'l.

## Exemples

- `examples/resum.py`: demana un resum curt a la passarel·la i mostra model, tokens i temps.
- `examples/resum.ipynb`: el mateix en notebook, més la llista de models disponibles.
- `examples/dades.py` + `examples/mostra.csv`: adaptador de dades (`carrega_sollicituds()`),
  que llegeix el CSV sintètic o la taula `sollicituds` de Postgres segons `DATA_SOURCE`;
  `--carrega` copia el CSV a la taula. Només dades sintètiques o anonimitzades en aquest
  entorn (ENS mp.sw.1.1; Instrucció 05, apt. 7.2).
- `examples/agent.py`: **agent amb Pydantic AI** (SDK per defecte): proveïdor cap a la
  passarel·la per l'àlies `LITELLM_MODEL`, dues eines (Postgres de l'espai i CSV, via
  l'adaptador), sortida estructurada i traces OpenTelemetry.
  `python examples/agent.py "quantes sol·licituds hi ha pendents?"`.
- `examples/agent_langgraph.py`: el mateix cas amb **LangGraph** (graf de dos nodes), com a
  referència de l'altre enfocament. Quan usar cadascun, àlies i traces: `examples/README.md`.

Els SDK de proveïdor (OpenAI Agents SDK, Claude Agent SDK, Google ADK) **no** són a la imatge:
si un projecte els necessita, els instal·la ell i ho justifica a l'Estudi d'Integració.

Si l'àlies apunta a un model de raonament (a la demo, `qwen3:8b`), `resum.py` usa
`max_tokens=1500` perquè el contingut no arribi buit.

## Construir i provar en local

```bash
docker build -t teclab-mixt:0.5.0 .

# Passarel·la i clau de prova a .env (ignorat per git), vegeu .env.example
cp .env.example .env   # i omple LITELLM_BASE_URL i LITELLM_KEY

# Sense les variables, els exemples diuen quina falta i surten (codi 2)
docker run --rm teclab-mixt:0.5.0 python /home/teclab/examples/resum.py

# Demo, des del mateix servidor: el domini públic no fa hairpin, resol-lo a l'host (Caddy)
docker run --rm --env-file .env --add-host api.mesalles.org:host-gateway teclab-mixt:0.5.0 \
  python /home/teclab/examples/resum.py

# Codex CLI sense interactiu (genera ~/.codex/config.toml i respon); el seccomp és pel sandbox
docker run --rm --env-file .env --add-host api.mesalles.org:host-gateway \
  --security-opt seccomp=unconfined teclab-mixt:0.5.0 \
  codex exec --skip-git-repo-check "explica en dues frases què fa /home/teclab/examples/resum.py"

# JupyterLab en local (http://localhost:8888)
docker run --rm -p 8888:8888 --env-file .env teclab-mixt:0.5.0
```

A Git Bash de Windows, afegeix `MSYS_NO_PATHCONV=1` davant de `docker run` perquè no
reescrigui les rutes `/home/...`.

## Desplegament

- **Demo** (`mesalles.org`): els compose de Coder i JupyterHub, els blocs de Caddy i les
  xarxes viuen a `../docker-stack` (`demo/coder/`, `demo/jupyter/`). Dins de Docker,
  `api.mesalles.org` resol a Caddy per la xarxa `demo-edge`. La plantilla de Coder (proveïdor
  Docker) és a `coder/` i la configuració de JupyterHub a `jupyterhub/`; totes dues posen
  `LITELLM_BASE_URL` a l'entorn de l'espai.
- **Sandbox del Teclab a Google Cloud**: `eloymesalles/teclab-gcp` (Terraform, GitHub
  Actions). La plantilla de Coder per a màquines virtuals (`coder-template-gce/`, pendent) hi
  posa la passarel·la privada, la clau virtual del projecte i la CA del Teclab. La imatge s'hi
  publicarà al registre `teclab` des d'aquest repo (workflow pendent).
