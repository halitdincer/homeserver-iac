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

# ServiceAccount with cluster-admin so kubectl works inside the workspace
resource "kubernetes_service_account" "workspace" {
  metadata {
    name      = "coder-homeserver-iac-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
    namespace = "coder"
  }
}

resource "kubernetes_cluster_role_binding" "workspace" {
  metadata {
    name = "coder-homeserver-iac-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.workspace.metadata[0].name
    namespace = "coder"
  }
}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"
  startup_script = <<-EOF
    #!/bin/bash
    export PATH="/home/coder/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    # Install terraform
    if ! command -v terraform > /dev/null 2>&1; then
      curl -fsSL https://releases.hashicorp.com/terraform/1.10.5/terraform_1.10.5_linux_amd64.zip -o /tmp/tf.zip
      unzip -o /tmp/tf.zip -d /home/coder/.local/bin/ && rm /tmp/tf.zip
    fi

    # Install kubectl
    if ! command -v kubectl > /dev/null 2>&1; then
      curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /home/coder/.local/bin/kubectl
      chmod +x /home/coder/.local/bin/kubectl
    fi

    # Install helm
    if ! command -v helm > /dev/null 2>&1; then
      curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | HELM_INSTALL_DIR=/home/coder/.local/bin USE_SUDO=false bash
    fi

    # Install ansible
    if ! command -v ansible > /dev/null 2>&1; then
      pip3 install --user ansible 2>/dev/null || true
    fi

    # Set up SSH key for homeserver VMs
    mkdir -p /home/coder/.ssh && chmod 700 /home/coder/.ssh
    printf '%s' "$HOMESERVER_SSH_KEY" > /home/coder/.ssh/homeserver_ed25519
    chmod 600 /home/coder/.ssh/homeserver_ed25519
    cat >> /home/coder/.ssh/config << 'SSHCONF'
Host homeserver-proxmox
  HostName 10.10.10.1
  User root
  IdentityFile ~/.ssh/homeserver_ed25519
Host homeserver-k3s
  HostName 10.10.10.105
  User root
  IdentityFile ~/.ssh/homeserver_ed25519
Host homeserver-immich
  HostName 10.10.10.100
  User root
  IdentityFile ~/.ssh/homeserver_ed25519
SSHCONF
    chmod 600 /home/coder/.ssh/config

    # Clone repo if not already present
    if [ ! -d /home/coder/homeserver-iac/.git ]; then
      git clone https://github.com/halitdincer/homeserver-iac.git /home/coder/homeserver-iac
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
  workdir  = "/home/coder/homeserver-iac"
}

module "jetbrains-gateway" {
  source   = "registry.coder.com/coder/jetbrains-gateway/coder"
  version  = "1.2.5"
  agent_id = coder_agent.main.id
  folder   = "/home/coder/homeserver-iac"
  latest   = true
}

module "mux" {
  count       = data.coder_workspace.me.start_count
  source      = "registry.coder.com/coder/mux/coder"
  version     = "1.4.3"
  agent_id    = coder_agent.main.id
  add_project = "/home/coder/homeserver-iac"
  subdomain   = false
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code Web"
  url          = "http://localhost:13337/?folder=/home/coder/homeserver-iac"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"
}

resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-homeserver-iac"
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
    name      = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}-homeserver-iac"
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
        service_account_name = kubernetes_service_account.workspace.metadata[0].name
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
            name = "HOMESERVER_SSH_KEY"
            value_from {
              secret_key_ref {
                name = "homeserver-iac-secret"
                key  = "HOMESERVER_SSH_KEY"
              }
            }
          }
          env {
            name = "ANTHROPIC_API_KEY"
            value_from {
              secret_key_ref {
                name = "homeserver-iac-secret"
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
