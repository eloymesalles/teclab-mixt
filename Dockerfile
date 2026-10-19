# teclab-mixt — imatge d'espai de treball compartida per Coder i JupyterHub.
# Totes les versions fixades. Arquitectura: linux/amd64.
FROM python:3.12.15-slim-bookworm

ARG NODE_VERSION=24.21.0
ARG CODE_SERVER_VERSION=4.141.0
ARG CODEX_VERSION=0.162.1
ARG PG_CLIENT_VERSION=16.15-1.pgdg12+2
ARG POCKETBASE_VERSION=0.40.5
ARG UV_VERSION=0.13.0
ARG USER=teclab
ARG UID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8

# ── Sistema ──
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git openssh-client tini xz-utils unzip procps bash nano less \
 && rm -rf /var/lib/apt/lists/*

# ── Client de PostgreSQL 16 (psql, pg_isready, pg_dump), del repositori oficial PGDG
#    (Debian bookworm només porta el 15); mateixa versió major que el sidecar de Coder ──
RUN install -d /usr/share/postgresql-common/pgdg \
 && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
 && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends "postgresql-client-16=${PG_CLIENT_VERSION}" \
 && rm -rf /var/lib/apt/lists/* \
 && psql --version && pg_isready --version

# ── Node.js LTS ──
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz \
 && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --exclude='*.md' --exclude='LICENSE' \
 && rm /tmp/node.tar.xz \
 && node --version && npm --version

# ── code-server (VS Code al navegador) ──
RUN curl -fsSL "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz" -o /tmp/code-server.tar.gz \
 && mkdir -p /opt/code-server \
 && tar -xzf /tmp/code-server.tar.gz -C /opt/code-server --strip-components=1 \
 && rm /tmp/code-server.tar.gz \
 && ln -s /opt/code-server/bin/code-server /usr/local/bin/code-server \
 && code-server --version

# ── Codex CLI (agent de codi d'OpenAI), apuntat a la passarel·la ──
# npm deixa el binari a /usr/local/lib/node_modules; l'ordre `codex` és l'embolcall de
# bin/codex, que genera ~/.codex/config.toml (proveïdor = passarel·la, clau de LITELLM_KEY)
# el primer cop que s'usa. Cap clau ni configuració amb valors a la imatge.
RUN npm install -g --no-fund --no-audit "@openai/codex@${CODEX_VERSION}" \
 && rm -rf /root/.npm /usr/local/bin/codex \
 && node /usr/local/lib/node_modules/@openai/codex/bin/codex.js --version
COPY --chmod=755 bin/codex /usr/local/bin/codex

# ── PocketBase (binari, no s'engega per defecte) ──
RUN curl -fsSL "https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}/pocketbase_${POCKETBASE_VERSION}_linux_amd64.zip" -o /tmp/pb.zip \
 && mkdir -p /opt/pocketbase \
 && unzip -q /tmp/pb.zip -d /opt/pocketbase pocketbase \
 && rm /tmp/pb.zip \
 && chmod +x /opt/pocketbase/pocketbase \
 && /opt/pocketbase/pocketbase --version

# ── Python: uv i paquets (JupyterLab, single-user de JupyterHub, VS Code al launcher,
#    client d'OpenAI, eines de qualitat) ──
COPY requirements.txt /tmp/requirements.txt
RUN pip install "uv==${UV_VERSION}" \
 && uv pip install --system --no-cache -r /tmp/requirements.txt \
 && rm /tmp/requirements.txt \
 && jupyter lab --version && jupyterhub-singleuser --version

# ── Usuari no root ──
RUN useradd --create-home --uid ${UID} --shell /bin/bash ${USER} \
 && mkdir -p /home/${USER}/work /home/${USER}/examples \
 && chown -R ${USER}:${USER} /home/${USER}

COPY --chown=${USER}:${USER} examples/ /home/${USER}/examples/
# El context de build des de Windows arriba amb bit d'execució; els exemples no en volen
RUN find /home/${USER}/examples -type f -exec chmod 644 {} +

USER ${USER}
WORKDIR /home/${USER}/work
ENV HOME=/home/${USER} \
    PATH=/home/${USER}/.local/bin:${PATH} \
    SHELL=/bin/bash \
    # Passarel·la LLM (la clau arriba sempre per l'entorn de l'espai, mai per aquí)
    LITELLM_BASE_URL=https://api.mesalles.org/v1 \
    LITELLM_MODEL=qwen3:8b \
    # Model que usa Codex CLI (d'OpenAI, via la passarel·la)
    CODEX_MODEL=gpt-6.1-sol \
    # OpenTelemetry (exemples d'agent): servei buit (la plantilla el posa), exportador OTLP,
    # endpoint buit = traces no exportades, sense error
    OTEL_SERVICE_NAME= \
    OTEL_TRACES_EXPORTER=otlp \
    OTEL_EXPORTER_OTLP_ENDPOINT=

EXPOSE 8888 8080

ENTRYPOINT ["tini", "--"]
# Per defecte, JupyterLab (ús directe o per JupyterHub, que substitueix l'ordre per
# jupyterhub-singleuser). La plantilla de Coder arrenca code-server des del seu agent.
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser"]
