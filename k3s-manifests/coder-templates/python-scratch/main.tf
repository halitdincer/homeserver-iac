terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "coder" {}
provider "kubernetes" {}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"
  startup_script = <<-EOF
    #!/bin/bash
    export PATH="/home/coder/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    # Install JupyterLab and common data science packages
    if ! command -v jupyter > /dev/null 2>&1; then
      pip3 install --user jupyterlab notebook ipython pandas numpy matplotlib requests httpx 2>/dev/null
    fi

    # Start JupyterLab (no auth for simplicity — workspace is owner-only)
    /home/coder/.local/bin/jupyter lab \
      --no-browser \
      --port=8888 \
      --ip=0.0.0.0 \
      --ServerApp.token='' \
      --ServerApp.password='' \
      --notebook-dir=/home/coder \
      >/tmp/jupyter.log 2>&1 &

    # Start code-server
    if [ ! -f /home/coder/.local/bin/code-server ]; then
      curl -fsSL https://code-server.dev/install.sh | sh -s -- --method standalone --prefix=/home/coder/.local
    fi
    /home/coder/.local/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
    EOF
}

module "claude-code" {
  source   = "registry.coder.com/coder/claude-code/coder"
  version  = "3.4.3"
  agent_id = coder_agent.main.id
  workdir  = "/home/coder"
}

module "mux" {
  count       = data.coder_workspace.me.start_count
  source      = "registry.coder.com/coder/mux/coder"
  version     = "1.4.3"
  agent_id    = coder_agent.main.id
  add_project = "/home/coder"
  subdomain   = false
}

resource "coder_app" "jupyterlab" {
  agent_id     = coder_agent.main.id
  slug         = "jupyterlab"
  display_name = "JupyterLab"
  url          = "http://localhost:8888"
  icon         = "/icon/jupyter.svg"
  subdomain    = false
  share        = "owner"
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code Web"
  url          = "http://localhost:13337/?folder=/home/coder"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"
}

# Ephemeral — no PVC, data lost on stop. Intentional for scratch use.
resource "kubernetes_deployment" "workspace" {
  metadata {
    name      = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-python"
    namespace = "coder"
    labels = {
      "coder.workspace" = data.coder_workspace.me.name
    }
  }
  spec {
    replicas = data.coder_workspace.me.start_count
    selector {
      match_labels = {
        "coder.workspace" = data.coder_workspace.me.name
      }
    }
    template {
      metadata {
        labels = {
          "coder.workspace" = data.coder_workspace.me.name
        }
      }
      spec {
        security_context {
          run_as_user = 1000
          fs_group    = 1000
        }
        container {
          name              = "dev"
          image             = "codercom/enterprise-base:ubuntu"
          image_pull_policy = "Always"
          command           = ["/bin/bash", "-c", coder_agent.main.init_script]
          security_context {
            run_as_user = 1000
          }
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          env {
            name = "ANTHROPIC_API_KEY"
            value_from {
              secret_key_ref {
                name = "coder-secret"
                key  = "ANTHROPIC_API_KEY"
              }
            }
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "2000m"
              memory = "2Gi"
            }
          }
        }
      }
    }
  }
  wait_for_rollout = false
}
