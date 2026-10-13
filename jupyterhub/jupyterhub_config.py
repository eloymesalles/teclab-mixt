"""Configuració de JupyterHub per a la demo Teclab (DockerSpawner + Google).

Cada usuari té un contenidor amb la imatge teclab-mixt (la mateixa que Coder), amb
JupyterLab i, al launcher, VS Code (code-server) i terminal. Variables d'entorn que
llegeix el hub (les posa docker-stack, demo/jupyter):

  TECLAB_IMAGE            imatge d'espai (per defecte teclab-mixt:0.1.0)
  TECLAB_LITELLM_KEY      clau virtual de la passarel·la (obligatòria; va a l'entorn de l'espai)
  TECLAB_ALLOWED_EMAILS   correus permesos, separats per comes (el primer és administrador)
  LLM_GOOGLE_CLIENT_ID / LLM_GOOGLE_CLIENT_SECRET   client OAuth de Google
"""

import os
import sys

from dockerspawner import DockerSpawner
from oauthenticator.google import GoogleOAuthenticator

c = get_config()  # noqa: F821  (injectat per JupyterHub)

IMAGE = os.environ.get("TECLAB_IMAGE", "teclab-mixt:0.1.0")
WORK_NETWORK = "demo-jupyter"  # privada: hub i espais
EDGE_NETWORK = "demo-edge"  # compartida amb Caddy: api.mesalles.org resol a Caddy
PUBLIC_URL = "https://jupyter.mesalles.org"
IDLE_TIMEOUT_S = 1800  # 30 min

litellm_key = os.environ.get("TECLAB_LITELLM_KEY")
if not litellm_key:
    sys.exit("Cal TECLAB_LITELLM_KEY a l'entorn del hub")
allowed = [e.strip().lower() for e in os.environ.get("TECLAB_ALLOWED_EMAILS", "").split(",") if e.strip()]
if not allowed:
    sys.exit("Cal TECLAB_ALLOWED_EMAILS (correus separats per comes)")


# ── Spawner ──
class TeclabSpawner(DockerSpawner):
    """DockerSpawner que, a més de la xarxa privada, connecta l'espai a demo-edge."""

    async def start(self, *args, **kwargs):
        result = await super().start(*args, **kwargs)
        await self.docker("connect_container_to_network", EDGE_NETWORK, self.container_id)
        return result


c.JupyterHub.spawner_class = TeclabSpawner
c.DockerSpawner.image = IMAGE
c.DockerSpawner.pull_policy = "never"  # la imatge és local al host
c.DockerSpawner.name_template = "jupyter-{username}"
c.DockerSpawner.network_name = WORK_NETWORK
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.extra_host_config = {"network_mode": WORK_NETWORK}
c.DockerSpawner.remove = True  # el contenidor s'esborra en aturar; el home persisteix al volum
c.DockerSpawner.notebook_dir = "/home/teclab/work"
c.DockerSpawner.volumes = {"jupyterhub-user-{username}": "/home/teclab"}
# Límits de la demo: 2 vCPU i 3 GiB
c.DockerSpawner.mem_limit = "3G"
c.DockerSpawner.cpu_limit = 2.0
c.DockerSpawner.environment = {
    "LITELLM_BASE_URL": "https://api.mesalles.org/v1",
    "LITELLM_KEY": litellm_key,
    "LITELLM_MODEL": "qwen3:8b",
}
# Exemples a mà a work/ (sense sobreescriure canvis de l'usuari)
c.DockerSpawner.post_start_cmd = "sh -c '[ -e /home/teclab/work/examples ] || cp -r /home/teclab/examples /home/teclab/work/examples'"
c.Spawner.default_url = "/lab"
c.Spawner.http_timeout = 120
c.Spawner.start_timeout = 180

# ── Hub ──
c.JupyterHub.bind_url = "http://0.0.0.0:8000"
c.JupyterHub.hub_ip = "0.0.0.0"
c.JupyterHub.hub_connect_ip = "jupyterhub"  # nom del servei a demo-jupyter
c.JupyterHub.db_url = "sqlite:////srv/jupyterhub/data/jupyterhub.sqlite"
c.JupyterHub.cookie_secret_file = "/srv/jupyterhub/data/jupyterhub_cookie_secret"
c.JupyterHub.trust_xheaders = True  # darrere de Caddy (i oauth2-proxy)
c.JupyterHub.cleanup_servers = False  # no aturar els espais en reiniciar el hub

# ── Autenticació: Google (mateix client que la resta de serveis) ──
c.JupyterHub.authenticator_class = GoogleOAuthenticator
c.GoogleOAuthenticator.client_id = os.environ["LLM_GOOGLE_CLIENT_ID"]
c.GoogleOAuthenticator.client_secret = os.environ["LLM_GOOGLE_CLIENT_SECRET"]
c.GoogleOAuthenticator.oauth_callback_url = f"{PUBLIC_URL}/hub/oauth_callback"
c.GoogleOAuthenticator.allowed_users = set(allowed)
c.GoogleOAuthenticator.admin_users = {allowed[0]}
c.GoogleOAuthenticator.login_service = "Google"

# ── Aturada per inactivitat (idle culler) ──
c.JupyterHub.load_roles = [
    {
        "name": "jupyterhub-idle-culler-role",
        "scopes": ["list:users", "read:users:activity", "read:servers", "delete:servers"],
        "services": ["jupyterhub-idle-culler-service"],
    }
]
c.JupyterHub.services = [
    {
        "name": "jupyterhub-idle-culler-service",
        "command": [sys.executable, "-m", "jupyterhub_idle_culler", f"--timeout={IDLE_TIMEOUT_S}"],
    }
]
