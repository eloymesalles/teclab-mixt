# Preparar el projecte per a la porta 2

La **porta 2** és el moment en què un projecte ix de l'espai: el codi ha de poder arrancar
sol, en un contenidor, en qualsevol plataforma, sense dependre de res de l'espai. Esta guia
diu què ha de tindre el repositori del projecte perquè eixe pas siga possible. La imatge de
l'espai, `teclab-mixt`, segueix estes mateixes regles i serveix d'exemple.

## 1. Un `Dockerfile` que construïsca la imatge del projecte

- Parteix d'una imatge base amb versió fixada (`python:3.12.15-slim-bookworm`, no
  `python:latest`).
- Fixa la versió de cada eina i paquet (`requirements.txt` amb `==`).
- Un usuari no root i una carpeta de treball.
- Cap clau, adreça de servei ni valor d'entorn concret dins de la imatge.

```dockerfile
FROM python:3.12.15-slim-bookworm
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt
RUN useradd --create-home --uid 1000 app
USER app
WORKDIR /home/app
COPY --chown=app:app . .
CMD ["python", "app.py"]
```

## 2. Un `.env.example` amb el contracte de variables

Tot el que depén de la plataforma arriba per variables d'entorn. El fitxer `.env.example`
les llista, amb un comentari i **sense valors reals**; el `.env` de veritat no es puja mai al
git (`.gitignore`).

```bash
# Passarel·la de models (la posa la plataforma)
LITELLM_BASE_URL=
LITELLM_KEY=
LITELLM_MODEL=chat-default
# Font de dades: csv | postgres
DATA_SOURCE=csv
DATABASE_URL=
```

Al codi, llig-les de l'entorn i, si falta una d'obligatòria, atura't amb un missatge clar
(com fa `examples/resum.py`: «Falta la variable d'entorn LITELLM_KEY»).

## 3. Un adaptador per a les dades

El codi de l'aplicació no sap d'on vénen les dades: ho decideix una peça a part, triada per
una variable (`DATA_SOURCE`). A l'espai, el CSV sintètic o el Postgres del sidecar; fora, la
font real. `examples/dades.py` és el patró: una funció (`carrega_sollicituds()`) que torna
sempre la mateixa estructura.

## 4. Integració contínua (CI)

Un workflow de GitHub Actions que, a cada PR, construïsca la imatge i execute unes proves de
fum: que arranca, que les ordres principals responen, que sense variables ix amb un missatge
i no amb un error estrany. El workflow `imatge.yml` de `teclab-mixt` n'és un exemple:
construeix, prova i només publica quan hi ha una versió etiquetada.

## 5. Prova final: arrancar fora de l'espai

Des d'una màquina amb Docker, fora de l'espai:

```bash
docker build -t el-meu-projecte:0.1.0 .
cp .env.example .env                     # i omple els valors de prova
docker run --rm --env-file .env el-meu-projecte:0.1.0
```

## Com saber que ha funcionat

- La imatge es construeix sense accedir a res de l'espai.
- Amb el `.env` buit, el programa diu quina variable falta i ix.
- Amb un `.env` complet, fa la seua feina contra la passarel·la i la font de dades indicades.
- La CI passa en verd a la PR.

## Si falla

- **La imatge té valors cuits** (una adreça, una clau): trau-los a variables. `detect-secrets
  scan` ajuda a trobar claus.
- **Només funciona a l'espai**: busca dependències implícites: fitxers fora del repositori,
  variables que l'espai posa i el teu `.env.example` no llista, paquets instal·lats a mà.
- **Versions flotants** (`latest`, sense `==`): el que funciona hui pot no funcionar demà.
  Fixa-les.

!!! info "Pendent"
    La llista de comprovació completa de la porta 2 (requisits de seguretat, documentació i
    operació) la publica el Teclab; esta guia només cobreix la part tècnica del repositori.
