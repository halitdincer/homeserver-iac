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

    # Install Ruby via rbenv if not present
    if ! command -v ruby > /dev/null 2>&1; then
      if [ ! -d /home/coder/.rbenv ]; then
        git clone https://github.com/rbenv/rbenv.git /home/coder/.rbenv
        git clone https://github.com/rbenv/ruby-build.git /home/coder/.rbenv/plugins/ruby-build
      fi
      export RBENV_ROOT="/home/coder/.rbenv"
      export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
      echo 'export RBENV_ROOT="/home/coder/.rbenv"' >> /home/coder/.bashrc
      echo 'export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"' >> /home/coder/.bashrc
      echo 'eval "$(rbenv init -)"' >> /home/coder/.bashrc
      rbenv install 3.2.6 && rbenv global 3.2.6
      gem install bundler
    else
      export RBENV_ROOT="/home/coder/.rbenv"
      export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
      eval "$(rbenv init -)"
    fi

    # Install Node.js LTS via nvm if not present
    if ! command -v node > /dev/null 2>&1; then
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
      export NVM_DIR="/home/coder/.nvm"
      source "$NVM_DIR/nvm.sh"
      nvm install --lts
      nvm use --lts
    else
      export NVM_DIR="/home/coder/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    fi

    # Install MySQL client and Redis CLI
    if ! command -v mysql > /dev/null 2>&1; then
      sudo apt-get update -qq && sudo apt-get install -y -qq mysql-client redis-tools 2>/dev/null
    fi

    # Clone repo if not already present
    if [ ! -d /home/coder/flight-tracker/.git ]; then
      git clone https://github.com/halitdincer/flight-tracker.git /home/coder/flight-tracker
    fi

    # Install Ruby dependencies
    cd /home/coder/flight-tracker/api
    if [ -f Gemfile ] && [ ! -d vendor/bundle ]; then
      bundle install 2>/dev/null
    fi

    # Install Node dependencies
    cd /home/coder/flight-tracker/web
    if [ -f package.json ] && [ ! -d node_modules ]; then
      npm install 2>/dev/null
    fi

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
  workdir  = "/home/coder/flight-tracker"
}

module "jetbrains-gateway" {
  source   = "registry.coder.com/coder/jetbrains-gateway/coder"
  version  = "1.2.5"
  agent_id = coder_agent.main.id
  folder   = "/home/coder/flight-tracker"
  latest   = true
}

module "mux" {
  count       = data.coder_workspace.me.start_count
  source      = "registry.coder.com/coder/mux/coder"
  version     = "1.4.3"
  agent_id    = coder_agent.main.id
  add_project = "/home/coder/flight-tracker"
  subdomain   = false
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code Web"
  url          = "http://localhost:13337/?folder=/home/coder/flight-tracker"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"
}

resource "coder_app" "rails-api" {
  agent_id     = coder_agent.main.id
  slug         = "rails-api"
  display_name = "Rails API"
  url          = "http://localhost:3000"
  icon         = "/icon/widgets.svg"
  subdomain    = false
  share        = "owner"
}

resource "coder_app" "react-dev" {
  agent_id     = coder_agent.main.id
  slug         = "react-dev"
  display_name = "React Dev"
  url          = "http://localhost:5173"
  icon         = "/icon/widgets.svg"
  subdomain    = false
  share        = "owner"
}

resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-flight-tracker"
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
    name      = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-flight-tracker"
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
