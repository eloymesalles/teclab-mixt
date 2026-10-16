# Plantilla de Coder «teclab-mixt»

Crea un espai de treball per projecte amb la imatge `teclab-mixt:0.3.0`: **VS Code**
(code-server), **JupyterLab** i, si l'espai indica un port, un botó genèric **App** per a la
UI web del projecte, **Codex CLI** al terminal, una **base de dades PostgreSQL pròpia**
(sidecar), 2 vCPU i 3 GiB, i les variables de la
passarel·la (`LITELLM_BASE_URL`, `LITELLM_KEY`, `LITELLM_MODEL`, `CODEX_MODEL`) i de la
base de dades (`DATABASE_URL`, `PG*`) a l'entorn.

## Requisits

- Servidor de Coder desplegat (docker-stack, `demo/coder/`) amb el socket de Docker. La
  clau virtual de LiteLLM és a l'entorn del contenidor del servidor (`TF_VAR_litellm_key`,
  des del `.env` de docker-stack) només per poder passar-la al `push`; la clau no és enlloc
  d'aquest repo.
- La imatge `teclab-mixt:0.3.0` construïda al daemon de Docker del servidor.
- Xarxes Docker `demo-coder` i `demo-edge` existents (les crea el compose de docker-stack).
- Accés a Docker Hub des del daemon per baixar `pgvector/pgvector:0.8.7-pg16` la primera
  vegada que es crea un espai (`docker_image` amb `keep_locally`; després queda al host).

## Pujar la plantilla

Des del contenidor del servidor de Coder (docker-stack, `demo/coder/`), amb la CLI
autenticada (`coder login https://coder.mesalles.org`):

```bash
# copiar la plantilla al contenidor
docker compose --env-file .env -f demo/coder/docker-compose.yml cp ../teclab-mixt/coder coder:/tmp/teclab-mixt
# pujar-la: la clau és una VARIABLE DE PLANTILLA (Coder la guarda xifrada), no l'entorn de Terraform
docker compose --env-file .env -f demo/coder/docker-compose.yml exec coder   sh -c 'coder templates push teclab-mixt -d /tmp/teclab-mixt -y --variable "litellm_key=$TF_VAR_litellm_key"'
# aturada per inactivitat de la demo (el push no té aquest flag)
docker compose --env-file .env -f demo/coder/docker-compose.yml exec coder   coder templates edit teclab-mixt --default-ttl 30m -y
```

Un espai s'atura 30 minuts després de l'última activitat. Per actualitzar la plantilla,
el mateix `push`: **Coder conserva els valors de les variables del push anterior** (clau,
`workspace_image`, `codex_model`) encara que canviï el `default` de `main.tf`, així que
per canviar d'imatge cal passar-la explícitament:

```bash
coder templates push teclab-mixt -d /tmp/teclab-mixt -y --variable "litellm_key=$TF_VAR_litellm_key" --variable "workspace_image=teclab-mixt:0.3.0"
```

Els espais existents passen a la versió nova de la plantilla (i de la imatge) en
actualitzar-los des de la UI o amb `coder update <espai>`.

## Crear un espai

Des de la UI: *Templates → teclab-mixt → Create workspace* (demana el port de l'app web del
projecte; buit si no en té). L'espai apareix amb dues apps (tres si hi ha port):
**VS Code** (obre `/home/teclab/work`) i **JupyterLab**. Els exemples són a
`work/examples/`; `python examples/resum.py` des del terminal de VS Code retorna una
resposta real de la passarel·la.

### Codex CLI

Al terminal de VS Code (`Terminal → New Terminal`, ja a `~/work`):

```bash
codex "explica què fa examples/resum.py"
```

Parla amb la passarel·la amb la clau de l'espai (`LITELLM_KEY`) i el model `CODEX_MODEL`
(`gpt-6.1-sol`, variable `codex_model` de la plantilla); no hi ha cap clau d'OpenAI a
l'espai i el consum compta contra la clau del projecte. Demana confirmació abans de
cada ordre o escriptura. No és una app de l'espai perquè és un programa de terminal.
Detalls al README de l'arrel.

### Botó «App»: la UI web del projecte (paràmetre de l'espai)

En crear l'espai, Coder demana el **port de l'app web del projecte** (paràmetre `app_port`,
buit per defecte). Si s'hi posa un port (p. ex. `8501`), la fitxa té un tercer botó, **App**,
genèric, que apunta a `127.0.0.1:<port>` sota `/@usuari/espai/apps/app/`; si es deixa buit,
no hi ha botó. El paràmetre es pot canviar després des de la fitxa de l'espai (*Settings →
Parameters*) i s'aplica en reiniciar-lo.

La plantilla no sap res de cap projecte; qualsevol app web que es desenvolupi a l'espai
s'hi veu si compleix el contracte:

- escoltar a `127.0.0.1:$APP_PORT` (l'agent exporta `APP_PORT` amb el valor del paràmetre);
- servir-se sota la ruta `/@$CODER_WORKSPACE_OWNER_NAME/$CODER_WORKSPACE_NAME/apps/app/`
  (l'agent exporta aquestes dues variables), com fa JupyterLab amb el seu `base_url`.

Mentre no hi hagi res escoltant, el botó obre un error de connexió. S'arriba pel 443 de
`coder.mesalles.org`, només el propietari i amb la sessió de Coder: cap port nou ni canvi al
Caddyfile. Primer projecte que l'usa: `eloymesalles/teclab-notebook` (`./arrenca.sh`).

### Base de dades de l'espai (sidecar de PostgreSQL)

Cada espai té el seu **PostgreSQL 16 amb pgvector** (`pgvector/pgvector:0.8.7-pg16`) en un
contenidor a part, `coder-<propietari>-<espai>-db`, creat i destruït per Terraform junt amb
l'espai. Només existeix a la **xarxa privada de l'espai** (`coder-<id>-net`, interna, sense
sortida a Internet): cap port publicat, cap altre espai hi arriba. Límits: 0,5 vCPU i
512 MiB (sense swap extra). La fitxa de l'espai mostra el contenidor, la imatge, la base i
el volum, i l'indicador «Postgres» (`pg_isready` cada 10 s).

**Com s'hi connecta l'app**: només per `DATABASE_URL`
(`postgres://app:<contrasenya>@coder-<propietari>-<espai>-db:5432/app`; el nom resol pel
DNS de la xarxa privada, també com a `db`). La contrasenya la genera `random_password` en
crear l'espai i viu només a l'estat de Terraform que guarda Coder (xifrat), mai al codi ni al
git. Al terminal, `psql` funciona sense configurar res (`PGHOST`, `PGUSER`, `PGPASSWORD`,
`PGDATABASE` a l'entorn):

```bash
psql -c 'select version();'
python examples/dades.py --carrega                  # copia examples/mostra.csv a la taula sollicituds
DATA_SOURCE=postgres python examples/dades.py       # les llegeix de Postgres (csv per defecte)
```

`examples/dades.py` és l'adaptador de dades del contracte de desplegament: canviar de font
(`DATA_SOURCE=csv|postgres`) és tocar una peça, no l'app.

**Què passa en aturar i en esborrar**:

| Acció | Contenidors (espai i sidecar) | Volums (`-home` i `-db`) | Xarxa privada |
|---|---|---|---|
| Aturar (o TTL de 30 min) | desapareixen | es queden: les dades de Postgres hi continuen | desapareix |
| Arrencar | es tornen a crear (l'espai espera que la base sigui sana) | es reutilitzen | es torna a crear |
| Esborrar l'espai | desapareixen | **s'esborren**: cap rastre | desapareix |

El volum de dades queda **lligat a Postgres 16**: canviar de versió major (p. ex. a una
imatge `-pg17`) requereix migrar les dades (`pg_dump` / `pg_restore`) o esborrar el volum.

> **Només dades sintètiques o anonimitzades.** Aquest entorn és d'experiment i
> demostratiu: no hi pot haver cap dada de producció (requisit base **mp.sw.1.1** de l'ENS i
> apartat **7.2** de la Instrucció 05: cap dada de producció a desenvolupament).
> `examples/mostra.csv` és sintètic.

## Com funciona

- `docker_container.workspace`: imatge local (sense `docker_image`, per no fer cap pull),
  `memory = 3072`, `cpus = "2"` (quota, no afinitat de nuclis), xarxes `demo-coder`,
  `demo-edge` (per arribar a `api.mesalles.org`, que resol a Caddy) i la privada de l'espai,
  volum persistent a `/home/teclab`, **sense** socket de Docker, `depends_on` del sidecar.
  `security_opts = ["seccomp=unconfined"]` perquè el sandbox de Codex (bubblewrap) pugui
  crear espais de noms d'usuari; l'espai continua sense capacitats.
- `docker_container.db`: el sidecar (`count = start_count`, com l'espai), `cpus = "0.5"`,
  `memory = memory_swap = 512`, healthcheck `pg_isready` i `wait = true`; `docker_network`
  privada per espai (`internal`); `docker_volume.db` amb `ignore_changes = all`;
  `random_password.db`; `coder_metadata` amb la fitxa (sense contrasenya).
- `coder_agent`: arrenca code-server (127.0.0.1:13337) i JupyterLab (127.0.0.1:8888 amb el
  `base_url` de l'app) i exposa CPU i RAM. Codex no necessita res a l'arrencada: la seva
  configuració la genera l'embolcall `codex` de la imatge el primer cop que s'executa.
- Les apps són *path-based* (`/@usuari/espai/apps/...`): no cal cap subdomini comodí.
