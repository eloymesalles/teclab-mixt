# Plantilla de Coder «teclab-mixt»: un espai de treball per projecte amb VS Code
# (code-server), JupyterLab i Claude Code al terminal, sobre la imatge compartida amb
# JupyterHub, i una base de dades PostgreSQL pròpia (sidecar pgvector) en una xarxa
# privada de l'espai.
#
# Pujar-la (des del contenidor del servidor, CLI autenticada; vegeu README.md):
#   coder templates push teclab-mixt -d /tmp/teclab-mixt -y --variable "litellm_key=$TF_VAR_litellm_key" --variable "workspace_image=teclab-mixt:0.4.0"
#   coder templates edit teclab-mixt --default-ttl 30m -y
# La clau és una variable de plantilla (Coder la guarda xifrada); mai al codi. Coder
# conserva els valors de les variables entre pushes: per canviar d'imatge cal passar-la.

terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "2.19.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}

# ── Variables ──
variable "litellm_key" {
  description = "Clau virtual de la passarel·la LiteLLM per als espais (es fixa amb --variable en pujar la plantilla)."
  type        = string
  sensitive   = true
}

variable "workspace_image" {
  description = "Imatge d'espai de treball (ha d'existir al daemon de Docker del servidor)."
  type        = string
  default     = "teclab-mixt:0.4.0"
}

variable "db_image" {
  description = "Imatge del sidecar de PostgreSQL (pgvector sobre Postgres 16; es baixa la primera vegada)."
  type        = string
  default     = "pgvector/pgvector:0.8.7-pg16"
}

variable "litellm_base_url" {
  type    = string
  default = "https://api.mesalles.org/v1"
}

variable "litellm_model" {
  description = "Àlies del catàleg de la passarel·la que usen els exemples i apps de l'espai (LITELLM_MODEL). L'administració de LiteLLM decideix a quin model apunta."
  type        = string
  default     = "chat-default"
}

# Claude Code per la passarel·la («claude»): noms, al catàleg de LiteLLM, dels models de
# Claude. Buits a la demo (la seva passarel·la no en té): allà «claude» avisa i surt, i
# «claude-compte» (llicència de la UJI) funciona igualment.
variable "claude_model_sonnet" {
  description = "Nom al catàleg de la passarel·la del model «sonnet» de Claude Code (CLAUDE_MODEL_SONNET). Buit = «claude» desactivat a l'espai."
  type        = string
  default     = ""
}

variable "claude_model_haiku" {
  description = "Nom al catàleg de la passarel·la del model «haiku» de Claude Code (CLAUDE_MODEL_HAIKU). Buit = el de sonnet."
  type        = string
  default     = ""
}

# ── Coder ──
provider "coder" {}
provider "docker" {}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# Paràmetre de l'espai (es demana en crear-lo; mutable): port de l'app web del projecte.
# Buit = sense botó «App».
data "coder_parameter" "app_port" {
  name         = "app_port"
  display_name = "Port de l'app web del projecte"
  description  = "Si el projecte té una interfície web, el port on escoltarà a 127.0.0.1 (p. ex. 8501) sota la ruta /@usuari/espai/apps/app/. Deixa-ho buit si no en té: no hi haurà botó «App»."
  type         = "string"
  default      = ""
  mutable      = true
  icon         = "/icon/widgets.svg"
  order        = 1
  validation {
    regex = "^$|^[1-9][0-9]{1,4}$"
    error = "Un número de port (10-65535) o res."
  }
}

locals {
  app_port       = trimspace(data.coder_parameter.app_port.value)
  workspace_name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  # Nom del sidecar: resol pel DNS de la xarxa privada de l'espai (també amb l'àlies «db»)
  db_name     = "${local.workspace_name}-db"
  db_user     = "app"
  db_database = "app"
}

# Contrasenya de la base de dades: es genera en crear l'espai i viu només a l'estat de
# Terraform que guarda Coder (com el token de l'agent). Sense símbols: vàlida dins d'una URL.
resource "random_password" "db" {
  length  = 32
  special = false
}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"

  env = {
    LITELLM_BASE_URL = var.litellm_base_url
    LITELLM_KEY      = var.litellm_key
    LITELLM_MODEL    = var.litellm_model
    # Claude Code («claude») llegeix la clau de LITELLM_KEY i els models d'aquí
    CLAUDE_MODEL_SONNET = var.claude_model_sonnet
    CLAUDE_MODEL_HAIKU  = var.claude_model_haiku
    # Base de dades de l'espai: l'app només ha de conèixer DATABASE_URL
    DATABASE_URL = "postgres://${local.db_user}:${random_password.db.result}@${local.db_name}:5432/${local.db_database}"
    # ...i psql funciona al terminal sense configurar res
    PGHOST     = local.db_name
    PGUSER     = local.db_user
    PGPASSWORD = random_password.db.result
    PGDATABASE = local.db_database
    # Port del botó «App» (buit si no n'hi ha): els projectes hi arrenquen la seva UI web
    APP_PORT = local.app_port
    # Traces OpenTelemetry dels exemples d'agent: nom del servei = l'espai (l'endpoint OTLP
    # el posa cada projecte si en té; la imatge el deixa buit)
    OTEL_SERVICE_NAME = "teclab-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  }

  startup_script = <<-EOT
    set -e
    mkdir -p /home/teclab/work
    # Exemples a mà a l'espai (sense sobreescriure canvis de l'usuari)
    [ -e /home/teclab/work/examples ] || cp -r /home/teclab/examples /home/teclab/work/examples
    # VS Code al navegador
    code-server --auth none --bind-addr 127.0.0.1:13337 --disable-telemetry /home/teclab/work \
      > /tmp/code-server.log 2>&1 &
    # JupyterLab (sota la ruta de l'app de Coder)
    jupyter lab --ip=127.0.0.1 --port=8888 --no-browser --ServerApp.token='' --ServerApp.password='' \
      --ServerApp.base_url="/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.me.name}/apps/jupyterlab/" \
      --ServerApp.allow_remote_access=True --ServerApp.root_dir=/home/teclab/work \
      > /tmp/jupyterlab.log 2>&1 &
  EOT

  metadata {
    display_name = "CPU"
    key          = "cpu"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }
  metadata {
    display_name = "RAM"
    key          = "mem"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }
  # Estat en viu del sidecar (el healthcheck de Docker no és un atribut que Terraform exposi)
  metadata {
    display_name = "Postgres"
    key          = "postgres"
    script       = "pg_isready -q && echo 'sana' || echo 'no disponible'"
    interval     = 10
    timeout      = 3
  }
}

resource "coder_app" "code_server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code"
  url          = "http://127.0.0.1:13337/?folder=/home/teclab/work"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"
  healthcheck {
    url       = "http://127.0.0.1:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "coder_app" "jupyterlab" {
  agent_id     = coder_agent.main.id
  slug         = "jupyterlab"
  display_name = "JupyterLab"
  url          = "http://127.0.0.1:8888/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.me.name}/apps/jupyterlab/"
  icon         = "/icon/jupyter.svg"
  subdomain    = false
  share        = "owner"
}

# Botó genèric «App»: el port de l'app web del projecte que es desenvolupi a l'espai, sigui
# quin sigui. Només existeix si l'usuari indica un port al paràmetre de l'espai (es pot
# canviar després des de la fitxa; s'aplica en reiniciar). Contracte per al projecte:
# escoltar a 127.0.0.1:<port> sota la ruta /@<propietari>/<espai>/apps/app/ (l'agent
# exporta CODER_WORKSPACE_OWNER_NAME, CODER_WORKSPACE_NAME i APP_PORT). Sense healthcheck:
# cada projecte té la seva ruta de salut.
resource "coder_app" "app" {
  count        = local.app_port == "" ? 0 : 1
  agent_id     = coder_agent.main.id
  slug         = "app"
  display_name = "App"
  url          = "http://127.0.0.1:${local.app_port}/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.me.name}/apps/app/"
  icon         = "/icon/widgets.svg"
  subdomain    = false
  share        = "owner"
}

# ── Docker: xarxa i volums (els volums sobreviuen a les aturades; s'esborren amb l'espai) ──

# Xarxa privada de l'espai: només l'espai i el seu sidecar; internal = sense sortida a
# Internet (l'espai surt per demo-edge). Es crea i es destrueix amb els contenidors.
resource "docker_network" "workspace" {
  count    = data.coder_workspace.me.start_count
  name     = "coder-${data.coder_workspace.me.id}-net"
  internal = true
}

resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace.me.id}-home"
  lifecycle {
    ignore_changes = all
  }
}

# Dades de Postgres: lligades a la versió major (16). Canviar de major = migrar o esborrar.
resource "docker_volume" "db" {
  name = "coder-${data.coder_workspace.me.id}-db"
  lifecycle {
    ignore_changes = all
  }
}

# ── Docker: sidecar de PostgreSQL ──
resource "docker_image" "db" {
  name         = var.db_image
  keep_locally = true # compartida entre espais: no s'esborra en esborrar-ne un
}

resource "docker_container" "db" {
  count    = data.coder_workspace.me.start_count
  image    = docker_image.db.image_id
  name     = local.db_name
  hostname = "db"

  # Límits: mig vCPU (quota) i 512 MiB sense swap extra (RAM justa a la màquina)
  cpus        = "0.5"
  memory      = 512
  memory_swap = 512

  env = [
    "POSTGRES_USER=${local.db_user}",
    "POSTGRES_PASSWORD=${random_password.db.result}",
    "POSTGRES_DB=${local.db_database}",
  ]

  # NOMÉS a la xarxa privada de l'espai: cap port publicat, cap altra xarxa
  networks_advanced {
    name    = docker_network.workspace[0].name
    aliases = ["db"]
  }

  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = docker_volume.db.name
    read_only      = false
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U ${local.db_user} -d ${local.db_database}"]
    interval     = "10s"
    timeout      = "5s"
    start_period = "10s"
    retries      = 5
  }
  # L'arrencada de l'espai no acaba fins que el healthcheck diu que la base és sana
  wait         = true
  wait_timeout = 120

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}

# Fitxa de l'espai: què és el sidecar (mai la contrasenya)
resource "coder_metadata" "db" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.db[0].id
  icon        = "/icon/postgres.svg"
  item {
    key   = "Contenidor"
    value = local.db_name
  }
  item {
    key   = "Imatge"
    value = var.db_image
  }
  item {
    key   = "Base de dades / usuari"
    value = "${local.db_database} / ${local.db_user}"
  }
  item {
    key   = "Xarxa"
    value = "${docker_network.workspace[0].name} (privada de l'espai)"
  }
  item {
    key   = "Volum"
    value = docker_volume.db.name
  }
}

# ── Docker: contenidor de l'espai ──
resource "docker_container" "workspace" {
  count    = data.coder_workspace.me.start_count
  image    = var.workspace_image
  name     = local.workspace_name
  hostname = data.coder_workspace.me.name

  # La base de dades primer (wait = true al sidecar): l'espai arrenca amb la base sana
  depends_on = [docker_container.db]

  # Límits de la demo: 2 vCPU (quota, no afinitat de nuclis) i 3 GiB
  cpus   = "2"
  memory = 3072

  # Cap permís extra: el seccomp=unconfined que demanava el sandbox de Codex ja no cal amb
  # Claude Code. L'espai continua sense capacitats ni socket de Docker.

  # L'agent de Coder arrenca via l'init script; l'ENTRYPOINT (tini + teclab-entrypoint) de
  # la imatge es manté
  command = ["sh", "-c", coder_agent.main.init_script]
  env     = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

  # Xarxa privada dels espais de Coder (servidor), demo-edge per arribar a
  # api.mesalles.org (Caddy) i la xarxa privada de l'espai (sidecar)
  networks_advanced {
    name = "demo-coder"
  }
  networks_advanced {
    name = "demo-edge"
  }
  networks_advanced {
    name = docker_network.workspace[0].name
  }

  volumes {
    container_path = "/home/teclab"
    volume_name    = docker_volume.home.name
    read_only      = false
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}
