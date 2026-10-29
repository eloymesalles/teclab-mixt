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
| Claude Code (`@anthropic-ai/claude-code`, agent de codi al terminal; `claude` per la passarel·la, `claude-compte` amb la llicència de la UJI) | 2.1.300 |
| `pydantic-ai-slim[openai]` + `langgraph` (SDK d'agents; vegeu `examples/README.md`) | 2.54.0 / 1.2.12 |
| `opentelemetry-sdk` + `opentelemetry-exporter-otlp` (traces dels agents) | 1.45.0 |
| git, ruff, detect-secrets | — / 0.17.0 / 1.5.0 |
| `gh` (CLI de GitHub; `gh auth login` per codi de dispositiu, cadascú el seu) | 2.102.0 |
| PocketBase (binari a `/opt/pocketbase`, no s'engega) | 0.40.5 |

Usuari `teclab` (uid 1000), directori de treball `/home/teclab/work`, exemples a
`/home/teclab/examples`. Mida: uns 2,7 GB (Claude Code és un binari natiu de 270 MB).

## Variables d'entorn de l'espai

| Variable | Valor |
|---|---|
| `LITELLM_BASE_URL` | Adreça de la passarel·la. **Buida a la imatge**: la posa la plataforma. Demo: `https://api.mesalles.org/v1`; Teclab GCP: `https://llm-teclab.uji.es:4443/v1` (nom privat de la VPC, certificat de la CA del Teclab) |
| `LITELLM_KEY` | Clau virtual creada a l'administració de LiteLLM de la plataforma (*Virtual Keys*). **La posa l'eina (Coder o JupyterHub) a l'entorn de l'espai; mai a la imatge ni al git.** |
| `LITELLM_MODEL` | **Àlies del catàleg** de la passarel·la, no un model: `chat-default` (per defecte a la imatge, igual a les dues plataformes). A quin model apunta ho decideix l'administració de LiteLLM |
| `OTEL_SERVICE_NAME`, `OTEL_TRACES_EXPORTER`, `OTEL_EXPORTER_OTLP_ENDPOINT` | Traces OpenTelemetry dels exemples d'agent: nom del servei (la plantilla el posa, `teclab-<propietari>-<espai>`), exportador `otlp`, endpoint buit per defecte (sense exportar) |
| `CLAUDE_MODEL_SONNET`, `CLAUDE_MODEL_HAIKU`, `CLAUDE_MODEL_OPUS` | Noms, al catàleg de la passarel·la, dels models de Claude que usa `claude` (Teclab: `claude-sonnet-5.5`, `claude-haiku-5.5`; sense Opus). Buits a la imatge: els posa la plataforma. Sense `CLAUDE_MODEL_SONNET`, `claude` no arrenca |
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

## Claude Code

Agent de codi al terminal de l'espai (VS Code a Coder, o terminal del launcher a JupyterHub),
amb **dos modes**, que són dues ordres:

```bash
claude                         # per la PASSAREL·LA del projecte (mode per defecte)
claude "explica què fa examples/resum.py"
claude-compte                  # amb la LLICÈNCIA DE CLAUDE DE LA UJI de l'usuari
```

- **`claude` (passarel·la)**: l'embolcall `/usr/local/bin/claude` (font: `bin/claude`) tradueix
  les variables de la plataforma a les de Claude Code i executa el programa: `ANTHROPIC_BASE_URL`
  = `LITELLM_BASE_URL` sense `/v1` (Claude Code hi afegeix `/v1/messages`, que LiteLLM serveix
  en format Anthropic), `ANTHROPIC_AUTH_TOKEN` = `LITELLM_KEY` (capçalera `Authorization:
  Bearer`), i els àlies `sonnet`/`haiku`/`opus` resolen a `CLAUDE_MODEL_SONNET`,
  `CLAUDE_MODEL_HAIKU` i `CLAUDE_MODEL_OPUS` (noms del catàleg de la passarel·la; sense Opus,
  Sonnet). **Els models que pot usar els limita la clau virtual** (llista de models i pressupost
  del projecte), no la imatge. Cap trànsit fora de la passarel·la
  (`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`), cap autoactualització (versió fixada) i sense
  capacitats experimentals (`CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1`: la passarel·la reenvia a
  Bedrock i rebutjaria camps que no coneix; es pot posar a `0` a l'entorn). La clau no s'escriu
  mai a cap fitxer. Sense `LITELLM_BASE_URL`, `LITELLM_KEY` o `CLAUDE_MODEL_SONNET`, surt amb
  un missatge (codi 2). A la demo, la passarel·la no té models de Claude: `claude` hi fallarà
  mentre no se n'afegeixi un a LiteLLM; `claude-compte` sí que hi funciona.
- **`claude-compte` (llicència de la UJI)**: el mateix programa amb la carpeta de configuració
  `~/.claude-compte` i **sense cap variable de la passarel·la** (font: `bin/claude-compte`). El
  primer cop, `/login` mostra una adreça: s'obre al navegador del portàtil, s'hi entra amb el
  compte i s'enganxa el codi al terminal. La credencial queda a `~/.claude-compte`, al disc
  persistent de l'espai: una vegada per espai. El consum compta contra la llicència de la
  persona, no contra la clau del projecte, i no passa pel registre de LiteLLM.
- **Per què dues ordres**: Claude Code tria sempre les variables de la passarel·la per davant
  del compte de `/login` (ordre de prioritat fix) i no té cap ordre per commutar dins d'una
  sessió; el mètode documentat per a dos comptes és una carpeta de configuració per compte
  (`CLAUDE_CONFIG_DIR`). Les dues ordres no es trepitgen: `claude` usa `~/.claude`.
- **Mode conservador**: per defecte Claude Code demana confirmació abans d'editar fitxers o
  executar ordres. No necessita cap permís extra del contenidor (el sandbox de Codex, que
  requeria `seccomp=unconfined`, ja no hi és).

## GitHub des de l'espai (`gh`)

La CLI de GitHub és a la imatge (versió fixada, paquet `.deb` oficial amb la suma verificada).
Cada persona s'hi autentica a mà, una vegada per espai, des del terminal:

```bash
gh auth login        # GitHub.com → HTTPS → «Login with a web browser»: mostra un codi i una
                     # adreça; s'obre al navegador del portàtil, s'hi escriu el codi, i llest
gh auth setup-git    # perquè git push/pull per HTTPS facin servir la mateixa sessió
gh repo clone eloymesalles/teclab-notebook
```

La credencial queda a `~/.config/gh/` (disc persistent de l'espai), mai a la imatge ni al git.
`gh auth status` diu amb qui s'està; `gh auth logout` ho desfà.

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

# Claude Code sense interactiu, per la passarel·la (cal CLAUDE_MODEL_SONNET al .env i que la
# passarel·la tingui aquest model)
docker run --rm --env-file .env --add-host api.mesalles.org:host-gateway teclab-mixt:0.5.0 \
  claude -p "explica en dues frases què fa /home/teclab/examples/resum.py"

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
