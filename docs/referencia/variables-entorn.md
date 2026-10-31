# Variables d'entorn de l'espai

Les posa la plataforma en engegar l'espai. Els teus programes les llegeixen de l'entorn
(`os.environ` en Python); no les escrigues en cap fitxer.

## Passarel·la i models

| Variable | Valor | Qui la posa |
|---|---|---|
| `LITELLM_BASE_URL` | Adreça de la passarel·la (amb `/v1`) | La plataforma |
| `LITELLM_KEY` | Clau del projecte. **Mai al git** | La plataforma, en crear l'espai |
| `LITELLM_MODEL` | Àlies per defecte: `chat-default` | La imatge |
| `CLAUDE_MODEL_SONNET`, `CLAUDE_MODEL_HAIKU` | Noms al catàleg dels models de Claude que usa `claude`. Buides si l'espai no té accés a Claude | La plataforma |
| `CLAUDE_MODEL_OPUS` | Buida (no hi ha Opus al catàleg); `claude` usa el de Sonnet | La imatge |

## Base de dades

| Variable | Valor |
|---|---|
| `DATABASE_URL` | `postgres://app:…@db:5432/app` (sidecar de l'espai) |
| `PGHOST`, `PGUSER`, `PGPASSWORD`, `PGDATABASE` | `db`, `app`, (contrasenya), `app`: perquè `psql` funcione sense arguments |
| `DATA_SOURCE` | `csv` (per defecte) o `postgres`: font d'`examples/dades.py`. La fixes tu |

## App web i identitat de l'espai

| Variable | Valor |
|---|---|
| `APP_PORT` | Port del botó «App», si l'espai en té; buida si no |
| `CODER_WORKSPACE_OWNER_NAME`, `CODER_WORKSPACE_NAME` | El teu usuari i el nom de l'espai; serveixen per a calcular la ruta de les apps (`/@usuari/espai/apps/...`) |

## Traces i certificats

| Variable | Valor |
|---|---|
| `OTEL_SERVICE_NAME` | `teclab-<usuari>-<espai>`: nom amb què ixen les traces dels agents |
| `OTEL_TRACES_EXPORTER` | `otlp` |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Buida: les traces no s'exporten enlloc (sense error). Posa-hi un col·lector si en tens un |
| `TECLAB_CA_CERT` | `/etc/teclab/ca.crt`: certificat de l'autoritat del Teclab. L'entrada de l'espai l'afegeix a la confiança del sistema, de Python i de Node (`SSL_CERT_FILE`, `CURL_CA_BUNDLE`, `GIT_SSL_CAINFO`, `REQUESTS_CA_BUNDLE`, `NODE_EXTRA_CA_CERTS`) |

Per a veure-les totes des del terminal:

```bash
env | grep -E '^(LITELLM|CLAUDE_MODEL|PG|DATABASE|APP_PORT|OTEL|TECLAB|CODER_WORKSPACE)' | sed 's/=.*KEY=.*/=…/'
```

!!! warning
    `LITELLM_KEY` i `PGPASSWORD` són credencials. No les mostres en captures de pantalla ni les
    enganxes en cap missatge.
