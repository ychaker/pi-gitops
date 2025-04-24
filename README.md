# Home Kubernetes Cluster with GitOps

This repository is designed to set up and manage a Kubernetes cluster on a Raspberry Pi cluster using GitOps (Flux). The cluster includes the following tools and applications:

- **k3s** (Lightweight Kubernetes)
- **Prometheus** (Monitoring)
- **Flux** (GitOps tool)
- **Traefik** (Ingress controller)
- **Home Assistant** (Home automation)
- **Ubiquity Unifi Agent** (Network management)
- **NFS Storage** (Using a home NAS system)

## Repository Structure

```
repo-root/
├── clusters/
│   └── home-cluster/
│       ├── flux-system/       # Flux configuration files
│       ├── kustomization.yaml # Links to other components
│       └── apps/
│           ├── home-assistant/
│           ├── prometheus/
│           └── ubiquity-unifi-agent/
├── infrastructure/
│   ├── ingress/               # Traefik configuration
│   ├── monitoring/            # Prometheus configuration
│   ├── storage/               # NFS storage configuration
├── ansible/                   # Ansible playbooks for k3s installation
└── README.md
```

## Prerequisites

1. **k3s**: Install k3s on your Raspberry Pi cluster.
2. **Home NAS**: Ensure your NAS is configured with an NFS share.

## Installing Flux

Flux is a GitOps tool used to automate the deployment of resources to your Kubernetes cluster by syncing with this Git repository.

### Step 1: Install Flux CLI

Install the Flux CLI on your local machine:

For Linux/macOS:
```bash
curl -s https://fluxcd.io/install.sh | sudo bash
```

For Windows (using Chocolatey):
```bash
choco install flux
```

Verify the installation:
```bash
flux --version
```

### Step 2: Bootstrap Flux

Use the Flux CLI to bootstrap the GitOps system. Replace `<github-username>` with your GitHub username:

```bash
flux bootstrap github \
  --owner=ychaker \
  --repository=pi-gitops \
  --branch=main \
  --path=clusters/home-cluster
```

This step sets up Flux in your cluster and links it to this repository.

## Installing k3s on Raspberry Pi Nodes

k3s must be installed on your Raspberry Pi cluster before using GitOps. You can automate this using the Ansible playbooks in this repository.

### Step 1: Install Ansible

Install Ansible on your local machine:
```bash
sudo apt update
sudo apt install ansible -y
```

### Step 2: Update the Inventory File

Edit the `ansible/inventory.ini` file to include the IP addresses and SSH credentials of your Raspberry Pi nodes.

### Step 3: Run the Ansible Playbook

Run the following command to install k3s on your Raspberry Pi nodes:
```bash
ansible-playbook -i ansible/inventory.ini ansible/install_k3s.yml
```

## Getting Started

1. Clone this repository:
   ```bash
   git clone https://github.com/ychaker/pi-gitops.git
   cd pi-gitops
   ```

2. Apply the manifests:
   ```bash
   kubectl apply -k clusters/home-cluster
   ```

3. Monitor the cluster:
   ```bash
   kubectl get pods --all-namespaces
   ```

## Storage Configuration

The `infrastructure/storage/` directory contains configurations for setting up NFS storage using your home NAS.

---

Happy hacking!
