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

    # Install Node.js LTS if not present
    if ! command -v node > /dev/null 2>&1; then
      curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /home/coder/.local/bin --skip-shell
      /home/coder/.local/bin/fnm install --lts
      /home/coder/.local/bin/fnm use lts-latest
      # Add fnm shims to PATH
      eval "$$(/home/coder/.local/bin/fnm env)"
    fi

    # Clone repo if not already present
    if [ ! -d /home/coder/job-scout/.git ]; then
      git clone https://github.com/halitdincer/job-scout.git /home/coder/job-scout
    fi

    # Install dependencies
    cd /home/coder/job-scout
    if [ -f package.json ] && [ ! -d node_modules ]; then
      npm install
    fi

    # Start dev server
    npm run dev >/tmp/job-scout-dev.log 2>&1 &

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
  workdir  = "/home/coder/job-scout"
}

module "jetbrains-gateway" {
  source   = "registry.coder.com/coder/jetbrains-gateway/coder"
  version  = "1.2.5"
  agent_id = coder_agent.main.id
  folder   = "/home/coder/job-scout"
  latest   = true
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code Web"
  url          = "http://localhost:13337/?folder=/home/coder/job-scout"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"
}

resource "coder_app" "dev-server" {
  agent_id     = coder_agent.main.id
  slug         = "dev-server"
  display_name = "Job Scout Dev"
  url          = "http://localhost:3000"
  icon         = "/icon/widgets.svg"
  subdomain    = false
  share        = "owner"
  healthcheck {
    url      = "http://localhost:3000/api/health"
    interval = 10
    threshold = 15
  }
}

resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-job-scout"
    namespace = "coder"
  }
  wait_until_bound = false
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = { storage = "10Gi" }
    }
  }
}

resource "kubernetes_deployment" "workspace" {
  metadata {
    name      = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-job-scout"
    namespace = "coder"
    labels    = { "coder.workspace" = data.coder_workspace.me.name }
  }
  spec {
    replicas = data.coder_workspace.me.start_count
    selector { match_labels = { "coder.workspace" = data.coder_workspace.me.name } }
    template {
      metadata { labels = { "coder.workspace" = data.coder_workspace.me.name } }
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
          security_context  { run_as_user = 1000 }

          env { name = "CODER_AGENT_TOKEN" value = coder_agent.main.token }
          env { name = "NODE_ENV"          value = "development" }
          env { name = "DB_PATH"           value = "/home/coder/data/jobscout.sqlite" }
          env {
            name = "ANTHROPIC_API_KEY"
            value_from {
              secret_key_ref { name = "coder-secret" key = "ANTHROPIC_API_KEY" }
            }
          }
          env {
            name = "SESSION_SECRET"
            value_from {
              secret_key_ref { name = "job-scout-secret" key = "SESSION_SECRET" }
            }
          }

          resources {
            requests = { cpu = "250m", memory = "512Mi" }
            limits   = { cpu = "2000m", memory = "2Gi" }
          }
          volume_mount { mount_path = "/home/coder" name = "home" }
        }
        volume {
          name = "home"
          persistent_volume_claim { claim_name = kubernetes_persistent_volume_claim.home.metadata[0].name }
        }
      }
    }
  }
  wait_for_rollout = false
}
