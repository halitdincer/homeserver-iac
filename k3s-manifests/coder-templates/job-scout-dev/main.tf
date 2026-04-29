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

    # Clone repo if not already present
    if [ ! -d /home/coder/job-scout/.git ]; then
      git clone https://github.com/halitdincer/job-scout.git /home/coder/job-scout
    fi

    # Install Python dependencies
    cd /home/coder/job-scout
    if [ -f requirements.txt ]; then
      pip3 install --user -r requirements.txt 2>/dev/null
    fi

    # Run migrations (SQLite for dev) and start Django dev server
    export DATABASE_URL="sqlite:///db.sqlite3"
    python3 manage.py migrate --run-syncdb 2>/dev/null
    python3 manage.py runserver 0.0.0.0:8000 >/tmp/django-dev.log 2>&1 &

    # Start code-server
    if [ ! -f /home/coder/.local/bin/code-server ]; then
      curl -fsSL https://code-server.dev/install.sh | sh -s -- --method standalone --prefix=/home/coder/.local
    fi
    /home/coder/.local/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
    EOF
}

module "jetbrains-gateway" {
  source   = "registry.coder.com/coder/jetbrains-gateway/coder"
  version  = "1.2.5"
  agent_id = coder_agent.main.id
  folder   = "/home/coder/job-scout"
  latest   = true
}

module "mux" {
  count       = data.coder_workspace.me.start_count
  source      = "registry.coder.com/coder/mux/coder"
  version     = "1.4.3"
  agent_id    = coder_agent.main.id
  add_project = "/home/coder/job-scout"
  subdomain   = false
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
  url          = "http://localhost:8000"
  icon         = "/icon/widgets.svg"
  subdomain    = false
  share        = "owner"
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
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "workspace" {
  metadata {
    name      = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-job-scout"
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
          volume_mount {
            mount_path = "/home/coder"
            name       = "home"
          }
        }
        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.home.metadata[0].name
          }
        }
      }
    }
  }
  wait_for_rollout = false
}
