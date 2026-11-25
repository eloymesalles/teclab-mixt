# Docker dins de l'espai

L'espai porta el client de Docker (`docker`, `docker compose`, `docker build`) i, al sandbox
del Teclab, parla amb el motor de Docker de la màquina del teu espai. Pots alçar serveis
auxiliars (una altra base de dades, una cua, una eina que es distribueix com a imatge) i
construir imatges del teu projecte sense eixir del terminal.

## Com funciona

L'espai és un contenidor dins d'una màquina virtual que és només teua. El motor de Docker
corre a la màquina, i l'espai hi té accés pel seu sòcol: els contenidors que llances són
**germans** del teu espai, no fills. Dues conseqüències:

- `docker ps` mostra també `espai` (el teu propi espai) i `espai-db` (la teua base de
  dades). No els pares ni els esborres: aturaries la teua sessió. Si passa, atura i engega
  l'espai des de Coder i tornen.
- Un servei que escolte a un port **no és a `localhost` de l'espai** per defecte. Per a
  tindre'l a `localhost`, el contenidor ha de compartir la xarxa de l'espai
  (`network_mode: "container:espai"`, més avall).

Les imatges i els contenidors viuen al disc del sistema de la màquina (20 GB, compartits
amb la imatge de l'espai), no al disc persistent.

## Alçar un servei amb Compose

Un `compose.yaml` a la carpeta del projecte, amb el servei unit a la xarxa de l'espai:

```yaml
services:
  redis:
    image: redis:7.4-alpine
    network_mode: "container:espai"
    volumes:
      - redis:/data
volumes:
  redis:
```

```bash
cd ~/work/<projecte>
docker compose up -d
redis-cli -h 127.0.0.1 ping      # o des de Python: redis://127.0.0.1:6379
docker compose logs -f redis
docker compose down              # atura i esborra el contenidor; el volum es queda
```

Amb `network_mode: "container:espai"` el servei escolta a `127.0.0.1` de l'espai, i el
botó **App** també el pot mostrar si escolta al port d'`APP_PORT`
([Mostrar una app web](app-web.md)). A canvi, no admet `ports:` (no cal: ja és a
`localhost`) i tots els serveis comparteixen els mateixos ports: dos serveis no poden
escoltar al mateix.

Si prefereixes que els serveis tinguen xarxa pròpia (i es vegen entre ells pel nom), lleva
`network_mode`: aleshores arribes a cada un per l'adreça que mostra
`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <contenidor>`,
no per `localhost`.

## Compartir fitxers amb un contenidor

Les rutes de `/home/teclab` funcionen com les esperes, tant amb `-v` com amb `volumes:` i
rutes relatives al `compose.yaml`:

```bash
docker run --rm -v ~/work/dades:/dades python:3.12-slim ls /dades
```

Qualsevol altra ruta de l'espai (`/tmp`, `/opt`, `/etc`) **no** és visible des del motor,
perquè el motor és a la màquina i no dins del contenidor de l'espai. Per a fitxers que no
són a la teua carpeta, usa un volum amb nom (com `redis:` a l'exemple de dalt).

## Construir una imatge

```bash
cd ~/work/<projecte>
docker build -t el-meu-projecte:0.1.0 .
docker run --rm --env-file .env el-meu-projecte:0.1.0
```

És la mateixa prova que demana [Preparar el projecte per a la porta 2](preparar-porta-2.md),
feta des de l'espai. Les imatges baixen pels registres de la
[llista de dominis permesos](../explicacio/xarxa-de-l-espai.md) (Docker Hub, `ghcr.io`).

## Què es conserva

| Acció | Contenidors i imatges de Docker |
|---|---|
| Aturar i engegar l'espai | es queden; els contenidors aturats, els tornes a alçar amb `docker compose up -d` (o `docker start`) |
| Actualització de la imatge de l'espai (administrador/a) | les imatges es queden; els serveis amb `network_mode: "container:espai"` cal tornar-los a crear: `docker compose up -d --force-recreate` |
| Esborrar l'espai | **desapareixen** amb la màquina |

Els volums amb nom segueixen la mateixa regla que les imatges: viuen al disc del sistema,
no al persistent, i desapareixen amb l'espai. El que ha de durar va a `/home/teclab`.

## Espai de disc i memòria

- `docker system df` diu quant ocupen imatges, contenidors i volums; `docker system prune`
  (i `docker image prune -a`) ho neteja. Amb 20 GB per a tot, convé fer-ho de tant en tant.
- Els contenidors comparteixen la CPU i la memòria de la màquina amb el teu espai (VS Code,
  notebooks). Per a serveis que mengen memòria, posa'ls un límit (`mem_limit: 512m` a
  Compose, `--memory 512m` a `docker run`): si la màquina es queda sense memòria, el que cau
  pot ser el teu espai.

## Com saber que ha funcionat

- `docker ps` mostra `espai` i `espai-db` sense demanar `sudo`.
- Després de `docker compose up -d`, el servei respon a `127.0.0.1` des del terminal de
  l'espai (`redis-cli -h 127.0.0.1 ping` → `PONG`).

## Si falla

- **`failed to connect to the docker API at unix:///var/run/docker.sock`**: l'espai no té
  el sòcol muntat (plataforma sense suport, o espai creat amb una plantilla anterior):
  actualitza l'espai des de Coder (*Update*) o demana-ho a l'administrador/a.
- **`permission denied` en parlar amb el sòcol**: el permís arriba amb l'arrencada de l'espai;
  atura'l i engega'l. Mentrestant, `sudo docker …` funciona.
- **El servei està en marxa però `localhost` no respon**: li falta
  `network_mode: "container:espai"`, o escolta en un port que ja usa un altre servei.
- **`docker compose up` diu que no troba un fitxer que existeix**: la ruta és fora de
  `/home/teclab`. Mou-lo a la teua carpeta o usa un volum amb nom.
- **`no space left on device`**: `docker system prune -a` i torna-ho a provar.

!!! warning "La màquina és teua, i tota la responsabilitat també"
    Amb el sòcol de Docker pots fer qualsevol cosa a la màquina del teu espai, inclòs
    espatllar-la. No hi ha res d'altres projectes ni cap secret de la plataforma: el que
    pots trencar és el teu espai, que l'administrador/a pot refer (el disc persistent no es
    toca). No muntes `/` de la màquina ni llances contenidors privilegiats: no et cal per a
    cap feina del projecte.

!!! note "Per a experimentar, no per a servir"
    Un servei alçat amb Compose viu mentre l'espai és engegat. Un servei que ha de funcionar
    sol és un desplegament fora del sandbox:
    [Preparar el projecte per a la porta 2](preparar-porta-2.md).
