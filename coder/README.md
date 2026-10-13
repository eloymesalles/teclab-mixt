# Plantilla de Coder «teclab-mixt»

Crea un espai de treball per projecte amb la imatge `teclab-mixt:0.1.0`: **VS Code**
(code-server) i **JupyterLab** com a apps de l'espai, 2 vCPU i 3 GiB, i les variables de
la passarel·la (`LITELLM_BASE_URL`, `LITELLM_KEY`, `LITELLM_MODEL`) a l'entorn.

## Requisits

- Servidor de Coder desplegat (docker-stack, `demo/coder/`) amb el socket de Docker i la
  variable d'entorn `TF_VAR_litellm_key` (la clau virtual de LiteLLM). La clau no és enlloc
  d'aquest repo.
- La imatge `teclab-mixt:0.1.0` construïda al daemon de Docker del servidor.
- Xarxes Docker `demo-coder` i `demo-edge` existents (les crea el compose de docker-stack).

## Pujar la plantilla

Des del servidor, amb la CLI de Coder (`coder login https://coder.mesalles.org`):

```bash
coder templates push teclab-mixt -d coder/ --default-ttl 30m -y
```

`--default-ttl 30m` és l'aturada per inactivitat de la demo: un espai s'atura 30 minuts
després de l'última activitat. Per actualitzar la plantilla, el mateix ordre.

## Crear un espai

Des de la UI: *Templates → teclab-mixt → Create workspace*. L'espai apareix amb dues apps:
**VS Code** (obre `/home/teclab/work`) i **JupyterLab**. Els exemples són a
`work/examples/`; `python examples/resum.py` des del terminal de VS Code retorna una
resposta real de la passarel·la.

## Com funciona

- `docker_container`: imatge local (sense `docker_image`, per no fer cap pull), `memory =
  3072`, `cpu_set = "0-1"`, xarxes `demo-coder` i `demo-edge` (per arribar a
  `api.mesalles.org`, que resol a Caddy), volum persistent a `/home/teclab`, **sense** socket
  de Docker.
- `coder_agent`: arrenca code-server (127.0.0.1:13337) i JupyterLab (127.0.0.1:8888 amb el
  `base_url` de l'app) i exposa CPU i RAM.
- Les apps són *path-based* (`/@usuari/espai/apps/...`): no cal cap subdomini comodí.
