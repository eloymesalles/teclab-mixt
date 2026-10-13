# Plantilla de Coder «teclab-mixt»: un espai de treball per projecte amb VS Code
# (code-server) i JupyterLab, sobre la imatge compartida amb JupyterHub.
#
# Pujar-la (des del servidor, amb la CLI de Coder autenticada):
#   coder templates push teclab-mixt -d coder/ --default-ttl 30m -y
# La clau de la passarel·la arriba al provisionador com a TF_VAR_litellm_key
# (variable d'entorn del servidor de Coder; vegeu docker-stack demo/coder).

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
  }
}

# ── Variables ──
variable "litellm_key" {
  description = "Clau virtual de la passarel·la LiteLLM per als espais (TF_VAR_litellm_key al servidor)."
  type        = string
  sensitive   = true
}

variable "workspace_image" {
  description = "Imatge d'espai de treball (ha d'existir al daemon de Docker del servidor)."
  type        = string
  default     = "teclab-mixt:0.1.0"
}

variable "litellm_base_url" {
  type    = string
  default = "https://api.mesalles.org/v1"
}

variable "litellm_model" {
  type    = string
  default = "qwen3:8b"
}

# ── Coder ──
provider "coder" {}
provider "docker" {}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"

  env = {
    LITELLM_BASE_URL = var.litellm_base_url
    LITELLM_KEY      = var.litellm_key
    LITELLM_MODEL    = var.litellm_model
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

# ── Docker ──
resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace.me.id}-home"
  lifecycle {
    ignore_changes = all
  }
}

resource "docker_container" "workspace" {
  count    = data.coder_workspace.me.start_count
  image    = var.workspace_image
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = data.coder_workspace.me.name

  # Límits de la demo: 2 vCPU i 3 GiB
  memory  = 3072
  cpu_set = "0-1"

  # L'agent de Coder arrenca via l'init script; l'ENTRYPOINT (tini) de la imatge es manté
  command = ["sh", "-c", coder_agent.main.init_script]
  env     = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

  # Xarxa privada dels espais de Coder, i demo-edge per arribar a api.mesalles.org (Caddy)
  networks_advanced {
    name = "demo-coder"
  }
  networks_advanced {
    name = "demo-edge"
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
