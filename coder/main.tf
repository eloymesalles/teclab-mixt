# Plantilla de Coder «teclab-mixt»: un espai de treball per projecte amb VS Code
# (code-server), JupyterLab i Codex CLI al terminal, sobre la imatge compartida amb
# JupyterHub, i una base de dades PostgreSQL pròpia (sidecar pgvector) en una xarxa
# privada de l'espai.
#
# Pujar-la (des del contenidor del servidor, CLI autenticada; vegeu README.md):
#   coder templates push teclab-mixt -d /tmp/teclab-mixt -y --variable "litellm_key=$TF_VAR_litellm_key" --variable "workspace_image=teclab-mixt:0.3.0"
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
  default     = "teclab-mixt:0.3.0"
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
  type    = string
  default = "qwen3:8b"
}

variable "codex_model" {
  description = "Model (d'OpenAI, via la passarel·la) que fa servir Codex CLI al terminal de l'espai."
  type        = string
  default     = "gpt-6.1-sol"
}

# ── Coder ──
provider "coder" {}
provider "docker" {}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
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
    # Codex CLI llegeix la clau de LITELLM_KEY (env_key) i el model d'aquí
    CODEX_MODEL = var.codex_model
    # Base de dades de l'espai: l'app només ha de conèixer DATABASE_URL
    DATABASE_URL = "postgres://${local.db_user}:${random_password.db.result}@${local.db_name}:5432/${local.db_database}"
    # ...i psql funciona al terminal sense configurar res
    PGHOST     = local.db_name
    PGUSER     = local.db_user
    PGPASSWORD = random_password.db.result
    PGDATABASE = local.db_database
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

  # El sandbox de Codex CLI (bubblewrap) necessita espais de noms d'usuari sense
  # privilegis, que el perfil seccomp per defecte de Docker bloqueja. Sense això Codex
  # no pot executar cap ordre. L'espai continua sense capacitats ni socket de Docker.
  security_opts = ["seccomp=unconfined"]

  # L'agent de Coder arrenca via l'init script; l'ENTRYPOINT (tini) de la imatge es manté
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
