# CLAUDE.md

Guia per a Claude Code en aquest repositori. Les regles globals d'usuari
(seguretat, secrets, git, idioma, autorització expressa abans de canviar l'estat del
sistema) s'apliquen sempre; aquí només hi ha el que és específic del projecte.

## Què és

Imatge d'espai de treball **`teclab-mixt`** del Teclab (laboratori d'IA de la UJI), compartida
per **dues plataformes**: la **demo** de `mesalles.org` (**Coder** amb Docker i **JupyterHub**,
a `coder.mesalles.org` i `jupyter.mesalles.org`; es manté com a banc de proves) i el **sandbox
del Teclab a Google Cloud** (`eloymesalles/teclab-gcp`: Coder amb una VM per espai, LiteLLM a
`llm-teclab.uji.es`). Una sola imatge per demostrar que el codi és portable. **La imatge no sap
en quina plataforma corre**: cap adreça, nom de màquina ni model de cap plataforma cuit a la
imatge; `LITELLM_BASE_URL` i `LITELLM_KEY` arriben sempre per l'entorn de l'espai.

- `Dockerfile` — Python 3.12, Node LTS, JupyterLab, code-server, Codex CLI, `openai`,
  git, ruff, detect-secrets, PocketBase (binari, no s'engega), exemples. **Versions
  fixades**, mai `:latest`. Etiqueta actual `teclab-mixt:0.5.0` (cada canvi d'imatge puja
  la versió; docker-stack la fixa als compose i a la plantilla de Coder; al Teclab es fixa
  per empremta al registre `teclab`). Porta el client `psql` 16 (repositori PGDG, versió
  fixada) i `psycopg`.
- `bin/teclab-entrypoint` — entrada del contenidor (`tini` → script → ordre): si la plataforma
  passa `TECLAB_CA_CERT` (ruta del certificat de la CA del Teclab muntat al contenidor), escriu
  `~/.teclab/ca-bundle.pem` (CA públiques + CA del Teclab) i exporta `SSL_CERT_FILE`,
  `CURL_CA_BUNDLE`, `GIT_SSL_CAINFO`, `REQUESTS_CA_BUNDLE` (paquet combinat) i
  `NODE_EXTRA_CA_CERTS` (la CA sola). Sense la variable, no fa res. **Cap `verify=False` ni
  `curl -k` al repo**: la confiança es resol aquí, no amb excepcions.
- `bin/codex` — embolcall instal·lat a `/usr/local/bin/codex`: genera
  `~/.codex/config.toml` el primer cop (proveïdor `teclab` = passarel·la, `env_key =
  LITELLM_KEY`, `wire_api = "responses"`, model `CODEX_MODEL`, `on-request` +
  `read-only`) i executa el binari de `@openai/codex`.
- `examples/` — `resum.py` i un notebook que criden la passarel·la LiteLLM
  (`LITELLM_BASE_URL`, `LITELLM_KEY`, obligatòries: surten amb missatge si falten);
  `dades.py` + `mostra.csv`, l'adaptador de dades (`DATA_SOURCE=csv|postgres`);
  `agent.py` (Pydantic AI: eines sobre l'adaptador, sortida estructurada, OpenTelemetry) i
  `agent_langgraph.py` (LangGraph, dos nodes); `examples/README.md` explica quan cadascun.
- **SDK d'agents a la imatge**: `pydantic-ai-slim[openai]`, `langgraph`, `opentelemetry-sdk`
  i `opentelemetry-exporter-otlp`, versions fixades. **Mai** SDK de proveïdor (OpenAI Agents,
  Claude Agent, Google ADK) ni langchain complet: els instal·la el projecte que els necessiti
  i ho justifica a l'Estudi d'Integració. Els models s'invoquen per **àlies del catàleg**
  (`LITELLM_MODEL`, per defecte `chat-default` a la plantilla), mai per nom de model.
  Traces: `OTEL_EXPORTER_OTLP_ENDPOINT` buit a la imatge (sense exportar, sense error).
- `coder/` — plantilla Terraform (proveïdor Docker) que usa la imatge. **És un sandbox
  genèric per a projectes del Teclab: mai res d'un projecte concret a la plantilla.** Apps:
  VS Code, JupyterLab i el botó genèric «App» (només si el paràmetre `app_port` de
  l'espai té valor; ruta `/@usuari/espai/apps/app/`; l'agent exporta `APP_PORT`), per a la
  UI web del projecte, sigui quin sigui. Amb un **sidecar de
  PostgreSQL per espai** (`docker_container.db`, `pgvector/pgvector` versió fixada,
  `count = start_count`, xarxa `docker_network` privada i `internal`, `docker_volume.db`
  persistent, `random_password`; l'app només rep `DATABASE_URL` i les `PG*`). Límits amb
  `cpus` (quota), mai `cpu_set`.
- `jupyterhub/` — `jupyterhub_config.py` (DockerSpawner) que usa la imatge.

El desplegament (compose de cada eina, blocs de Caddy, xarxes) viu a `../docker-stack`
(`demo/coder/`, `demo/jupyter/`). És una **demo**, no producció: ha de funcionar i
veure's bé amb la mínima petjada; la base de producció (panell, passarel·la, Ollama)
no s'ha de tocar.

## Punts delicats

- **Secrets**: la clau de LiteLLM arriba com a variable d'entorn de l'espai
  (`LITELLM_KEY`); mai al Dockerfile, als exemples ni al git. Per a proves locals, un
  `.env` ignorat per git.
- **Passarel·la**: compatible amb OpenAI; l'adreça la posa la plataforma (`LITELLM_BASE_URL`
  buida a la imatge). Demo: `https://api.mesalles.org/v1` (dins de Docker, el nom resol a
  Caddy per la xarxa `demo-edge`, no a Internet). Teclab GCP: `https://llm-teclab.uji.es:4443/v1`
  (nom privat, CA del Teclab). `LITELLM_MODEL` és l'àlies `chat-default` a tot arreu; si
  apunta a un model de raonament (a la demo, `qwen3:8b`) cal un `max_tokens` generós o el
  contingut arriba buit.
- **Codex CLI**: apunta sempre a la passarel·la, mai a `api.openai.com`; l'espai no ha de
  tenir cap clau d'OpenAI. Només admet l'API Responses (`wire_api = "responses"`; `chat`
  ja no existeix), que LiteLLM serveix a `/v1/responses`. Model per defecte `gpt-6.1-sol`
  (d'OpenAI; el consum compta contra la clau del projecte). Mantén el mode conservador
  (`on-request` + `read-only`: demana confirmació per a ordres i escriptures): és un
  sandbox compartit de demo. Cada torn porta uns 10k tokens de pròleg (~0,03 $ la primera
  crida, menys després per la memòria cau).
- **Recursos**: cada espai, 2 vCPU i 3 GiB com a màxim; aturada per inactivitat a 30 min
  a les dues eines. Docker Desktop (WSL2) té 16 GB per a tots els contenidors.
- **Superfície pública**: JupyterHub va darrere d'oauth2-proxy; Coder té autenticació
  pròpia (excepció acceptada per a la demo).
- **Base de dades per espai (Coder)**: el sidecar només viu a la xarxa privada de l'espai
  (mai a `demo-edge` ni `demo-coder`, cap port publicat); la contrasenya la genera
  Terraform i viu a l'estat que guarda Coder, mai al codi, als exemples ni al git. El volum
  `-db` queda lligat a Postgres 16: canviar de major és migrar o esborrar. **Només dades
  sintètiques o anonimitzades** als espais (ENS mp.sw.1.1; Instrucció 05, apt. 7.2): cap
  dada de producció.
- **Socket de Docker**: el reben Coder i JupyterHub (necessari); els espais de treball,
  mai. L'únic permís extra dels espais és `seccomp=unconfined` (plantilla de Coder i
  spawner de JupyterHub), imprescindible perquè el sandbox de Codex (bubblewrap, espais
  de noms d'usuari) funcioni; sense capacitats ni privilegis. Decisió de #11.

## Flux de treball — OBLIGATORI

Igual que als altres repos: issue amb plantilla de `.github/ISSUE_TEMPLATE/` →
branca `feature/…`, `fix/…`, `chore/…`, `docs/…` → commits amb Conventional Commits →
PR amb `closes #N` (comprovar `closingIssuesReferences`; si és buit, mutació
`addCloseIssueReferences` com a `local-llm-admin`) → fusió només quan l'usuari ho digui.
Cossos d'issues i PRs amb `--body-file` (fitxer UTF-8). Cap desplegament, build de
producció ni canvi d'estat del sistema sense autorització expressa al xat.
