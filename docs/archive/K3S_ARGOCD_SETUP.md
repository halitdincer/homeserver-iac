# K3s + ArgoCD Setup Complete! 🚀

## Your New Kubernetes Infrastructure

**VM 105 - K3s Cluster:**
- Local IP: `192.168.2.216`
- Tailscale IP: `100.112.34.54`
- CPU: 2 cores
- RAM: 4GB
- Disk: 64GB
- K3s Version: v1.34.3+k3s1
- ArgoCD: Installed and running

## Quick Access

### ArgoCD Web UI
**Via Tailscale (Recommended):**
```
https://100.112.34.54:31552
```

**Login Credentials:**
- Username: `admin`
- Password: `TBzg7LT33AOdtQhP`

**Important:** Change the admin password after first login!

### SSH to K3s VM
```bash
# Via Tailscale (works from anywhere)
ssh root@100.112.34.54

# Via local network (at home only)
ssh root@192.168.2.216
```

## Accessing Kubernetes Cluster Remotely

### Option 1: SSH + kubectl (Quick)
```bash
# SSH to K3s VM and run kubectl
ssh root@100.112.34.54 "kubectl get pods -A"
```

### Option 2: Copy kubeconfig (Better)
```bash
# Copy kubeconfig from K3s VM to your Mac
scp root@100.112.34.54:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config

# Edit the config to use Tailscale IP
sed -i '' 's/127.0.0.1/100.112.34.54/g' ~/.kube/k3s-config

# Use it
export KUBECONFIG=~/.kube/k3s-config
kubectl get nodes
```

### Option 3: Merge with existing kubeconfig
```bash
# If you have other Kubernetes clusters
scp root@100.112.34.54:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config
sed -i '' 's/127.0.0.1/100.112.34.54/g' ~/.kube/k3s-config
sed -i '' 's/default/k3s-homeserver/g' ~/.kube/k3s-config

# Merge configs
KUBECONFIG=~/.kube/config:~/.kube/k3s-config kubectl config view --flatten > ~/.kube/config-merged
mv ~/.kube/config-merged ~/.kube/config

# Switch context
kubectl config use-context k3s-homeserver
kubectl get nodes
```

## What's Running

### K3s Cluster
```bash
# Check cluster status
ssh root@100.112.34.54 "kubectl get nodes"

# View all pods
ssh root@100.112.34.54 "kubectl get pods -A"
```

### ArgoCD Components
```bash
# Check ArgoCD pods
ssh root@100.112.34.54 "kubectl get pods -n argocd"

# ArgoCD services
ssh root@100.112.34.54 "kubectl get svc -n argocd"
```

## Your First GitOps Deployment

### Step 1: Create a Git Repository
Create a new GitHub/GitLab repository with a simple Kubernetes manifest:

```yaml
# app.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: demo
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

### Step 2: Deploy via ArgoCD

**Option A: Via ArgoCD CLI**
```bash
# Install ArgoCD CLI on your Mac
brew install argocd

# Login to ArgoCD
argocd login 100.112.34.54:31552 --username admin --password TBzg7LT33AOdtQhP --insecure

# Create application
argocd app create demo-app \
  --repo https://github.com/YOUR_USERNAME/YOUR_REPO.git \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace demo

# Sync (deploy)
argocd app sync demo-app
```

**Option B: Via ArgoCD Web UI**
1. Open https://100.112.34.54:31552
2. Login with admin / TBzg7LT33AOdtQhP
3. Click "NEW APP"
4. Fill in:
   - Application Name: `demo-app`
   - Project: `default`
   - Sync Policy: `Automatic`
   - Repository URL: Your Git repo URL
   - Path: `.` (or path to manifests)
   - Cluster URL: `https://kubernetes.default.svc`
   - Namespace: `demo`
5. Click "CREATE"

### Step 3: Watch the Magic
ArgoCD will:
- Clone your Git repo
- Apply the Kubernetes manifests
- Monitor for changes
- Auto-sync when you push to Git

```bash
# Watch deployment
ssh root@100.112.34.54 "kubectl get pods -n demo -w"
```

## GitOps Workflow

### Traditional Way (Manual):
```bash
# Edit file
vim deployment.yaml

# Apply manually
kubectl apply -f deployment.yaml
```

### GitOps Way (Automated):
```bash
# Edit file
vim deployment.yaml

# Commit and push
git add deployment.yaml
git commit -m "Update deployment"
git push

# ArgoCD automatically detects change and deploys!
# No kubectl needed!
```

## ArgoCD Management

### Change Admin Password
```bash
# Via Web UI: User Info → Update Password

# Or via CLI:
argocd login 100.112.34.54:31552 --username admin --password TBzg7LT33AOdtQhP --insecure
argocd account update-password
```

### Add Git Repository
```bash
# Via CLI
argocd repo add https://github.com/YOUR_USERNAME/YOUR_REPO.git \
  --username YOUR_USERNAME \
  --password YOUR_TOKEN

# Or via Web UI: Settings → Repositories → Connect Repo
```

### View Applications
```bash
# List all apps
argocd app list

# Get app details
argocd app get demo-app

# Sync app
argocd app sync demo-app

# Delete app
argocd app delete demo-app
```

## Useful Commands

### K3s Management
```bash
# Restart K3s
ssh root@100.112.34.54 "systemctl restart k3s"

# Check K3s logs
ssh root@100.112.34.54 "journalctl -u k3s -f"

# K3s status
ssh root@100.112.34.54 "systemctl status k3s"
```

### Kubectl Quick Reference
```bash
# Get all resources
kubectl get all -A

# Get pods in namespace
kubectl get pods -n argocd

# Describe pod
kubectl describe pod POD_NAME -n NAMESPACE

# View logs
kubectl logs POD_NAME -n NAMESPACE -f

# Execute command in pod
kubectl exec -it POD_NAME -n NAMESPACE -- /bin/bash

# Port forward
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

## Architecture

```
Your Homeserver Stack:

Docker VMs (Existing):
├── Immich (VM 100) - Photos
├── Nginx (VM 102) - Reverse proxy
└── Home Assistant (VM 103) - Smart home

Kubernetes:
└── K3s (VM 105)
    ├── Control Plane (master + worker)
    ├── ArgoCD (GitOps)
    └── Your apps (deployed via GitOps)

Access Pattern:
You (Remote) → Tailscale → K3s (100.112.34.54:31552) → ArgoCD
ArgoCD → Git Repository → Auto-deploy to K3s
```

## Deployment Strategy

**Keep Existing Services Running:**
- ✅ Immich (Docker) - stable, working
- ✅ Home Assistant (Docker) - stable, working
- ✅ Nginx (Docker) - stable, working

**Use K3s for New Applications:**
- ✅ Deploy new apps via ArgoCD + Git
- ✅ Learn Kubernetes gradually
- ✅ GitOps workflow
- ✅ Infrastructure as Code

**Future (Optional):**
- Migrate existing apps to K3s
- Add more worker nodes for HA
- Expand cluster

## Example: Deploy Homepage Dashboard

Deploy Homepage dashboard via ArgoCD:

1. Create `homepage.yaml` in a Git repo:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: homepage
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: homepage
  namespace: homepage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: homepage
  template:
    metadata:
      labels:
        app: homepage
    spec:
      containers:
      - name: homepage
        image: ghcr.io/gethomepage/homepage:latest
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: homepage
  namespace: homepage
spec:
  type: NodePort
  selector:
    app: homepage
  ports:
  - port: 3000
    targetPort: 3000
```

2. Deploy via ArgoCD:
```bash
argocd app create homepage \
  --repo https://github.com/YOUR_USERNAME/YOUR_REPO.git \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace homepage \
  --sync-policy automated
```

3. Access via Tailscale:
```bash
# Get NodePort
kubectl get svc -n homepage

# Access at http://100.112.34.54:NODE_PORT
```

## Troubleshooting

### ArgoCD won't sync
```bash
# Check app status
argocd app get APP_NAME

# Force sync
argocd app sync APP_NAME --force

# Check logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Can't access ArgoCD UI
```bash
# Check service
ssh root@100.112.34.54 "kubectl get svc -n argocd argocd-server"

# Check pods
ssh root@100.112.34.54 "kubectl get pods -n argocd"

# Check Tailscale
ping 100.112.34.54
```

### K3s not working
```bash
# Check service
ssh root@100.112.34.54 "systemctl status k3s"

# Restart
ssh root@100.112.34.54 "systemctl restart k3s"

# Check logs
ssh root@100.112.34.54 "journalctl -u k3s -n 100"
```

## Next Steps

### Immediate:
1. ✅ Login to ArgoCD and change admin password
2. ✅ Set up kubeconfig on your Mac
3. ✅ Create your first Git repository with K8s manifests
4. ✅ Deploy your first app via ArgoCD

### Soon:
1. Deploy Homepage dashboard via ArgoCD
2. Set up monitoring (Grafana + Prometheus)
3. Add SSL/TLS for ArgoCD (via cert-manager)
4. Create multiple ArgoCD projects

### Later:
1. Add Nginx ingress rules for K3s apps
2. Migrate some Docker apps to K3s
3. Expand to multi-node cluster
4. Set up CI/CD pipeline

## Resources

- **ArgoCD Docs**: https://argo-cd.readthedocs.io/
- **K3s Docs**: https://docs.k3s.io/
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **GitOps Guide**: https://www.gitops.tech/

## Summary

**What You Have Now:**

✅ K3s single-node Kubernetes cluster
✅ ArgoCD for GitOps deployments
✅ Accessible remotely via Tailscale
✅ Existing Docker services still running
✅ Ready to deploy apps via Git!

**Your Infrastructure:**

| VM | Service | IP | Tailscale | Purpose |
|----|---------|-----|-----------|---------|
| 100 | Immich | 192.168.2.202 | - | Photos (Docker) |
| 102 | Nginx | 192.168.2.10 | 100.119.146.124 | Proxy (Docker) |
| 103 | Home Assistant | 192.168.2.206 | - | Smart Home (Docker) |
| 105 | K3s | 192.168.2.216 | 100.112.34.54 | Kubernetes + ArgoCD |

**You can now deploy applications by just pushing to Git!** 🎉

---

*Setup completed: 2026-02-07*
*Admin password: TBzg7LT33AOdtQhP (change this!)*
