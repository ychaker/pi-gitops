# Home Raspberry Pi Kubernetes Cluster (GitOps)

This repository manages a Kubernetes (k3s) cluster running on 6 Raspberry Pis using GitOps practices. The setup automates provisioning, application deployment, and monitoring with Ansible, Flux, and Helm. Storage is provided by your Synology NAS (NFS/SMB).

## Features

- **Automated provisioning** with Ansible
- **k3s**: Lightweight Kubernetes for ARM (Raspberry Pi)
- **Flux**: GitOps controller for repeatable, declarative app deployments
- **Traefik**: Ingress controller
- **Prometheus & Grafana**: Monitoring & dashboards
- **Persistent storage**: Synology NAS (NFS/SMB)
- **App stack**: Home Assistant, Unifi, Radarr, Lidarr, Prowlarr, Pi-hole, and more

---

## Hardware & Network Prerequisites

- 6x Raspberry Pi (recommend 2GB+ RAM, RPi 4 if possible)
- MicroSD card or SSD for each Pi
- Wired Ethernet (recommended)
- Synology NAS with NFS or SMB share enabled
- All devices on the same subnet, static IPs preferred

---

## Repo Structure

```
repo-root/
  ansible/                  # Ansible playbooks for provisioning
    install_k3s.yml
    inventory.ini
  clusters/
    home-cluster/           # Flux/Kustomize root
      kustomization.yaml
      flux-system/          # Flux configuration
      apps/                 # App manifests (HelmRelease/YAML)
        home-assistant.yaml
        unifi.yaml
        radarr.yaml
        lidarr.yaml
        prowlarr.yaml
        pihole.yaml
      infrastructure
         monitoring/           # Prometheus, Grafana
           prometheus.yaml
           grafana.yaml
         networking/           # Traefik Ingress
           traefik.yaml
         storage/              # NFS/SMB PVs/PVCs
           nfs-pv.yaml
           nfs-pvc.yaml
  README.md
```

---

## Setup Instructions

### 1. Prepare Raspberry Pis

#### Flash Raspberry Pi OS Lite

- Download Raspberry Pi Imager or use [Raspberry Pi OS Lite (64-bit)](https://www.raspberrypi.com/software/).
- Flash the SD card or SSD for each Pi.

#### Boot, Set Unique Hostnames, Enable SSH

1. **Insert the SD card and boot each Raspberry Pi.**
2. **Enable SSH:**
   - Create an empty file named `ssh` (no extension) in the boot partition of the SD card before first boot, or run:
     ```sh
     sudo systemctl enable ssh
     sudo systemctl start ssh
     ```
3. **Set a unique hostname:**
   - SSH into each Pi (default user: `pi`, default password: `raspberry`):
     ```sh
     ssh pi@raspberrypi.local
     ```
   - Change the hostname (replace `pi1` with your chosen hostname):
     ```sh
     sudo raspi-config
     # Choose: System Options > Hostname > set as pi1, pi2, etc.
     ```
     Or edit `/etc/hostname` and `/etc/hosts` manually:
     ```sh
     sudo nano /etc/hostname
     sudo nano /etc/hosts
     ```
     - Replace the existing name with `pi1`, `pi2`, etc. in both files.
   - Reboot:
     ```sh
     sudo reboot
     ```

#### Set Static IPs

You can set static IPs via your router (DHCP reservation, recommended) or on each Pi:

- **Using dhcpcd.conf (on the Pi):**
  ```sh
  sudo nano /etc/dhcpcd.conf
  ```

  Add at the end (replace with your network details and static IP for each Pi):

  ```
  interface eth0
    static ip_address=192.168.1.71/24
    static routers=192.168.1.1
    static domain_name_servers=192.168.1.1 8.8.8.8
  ```
  - Save and reboot the Pi.

##### Print Your Gateway and DNS (Helper Script)

A helper script `scripts/get_network_info.sh` is provided to print your current default gateway and DNS server(s).

**Usage:**
1. Download or copy `scripts/get_network_info.sh` to your laptop (macOS or Linux).
2. Make it executable and run it:
   ```sh
   chmod +x get_network_info.sh
   ./get_network_info.sh
   ```
3. Use the printed values as input for `setup_pi.sh` when configuring your Raspberry Pis.

**Example Output:**

```
=== Default Gateway (Router) ===
Gateway: 192.168.1.1

=== DNS Servers ===
DNS: 192.168.1.1
DNS: 8.8.8.8

Copy and paste these values when prompted by setup_pi.sh!
```

#### Update System and Enable SSH Key Authentication

- Update and upgrade the OS:
  ```sh
  sudo apt update && sudo apt upgrade -y
  ```
- Copy your SSH public key to each Pi (from your workstation):
  ```sh
  ssh-copy-id pi@<pi-ip>
  ```

#### Automated Initial Setup (Optional)

You can use the provided `setup_pi.sh` script to automate initial Pi configuration (hostname, static IP, SSH, updates).

**Usage:**

1. Download the setup script:
   ```sh
   mkdir -p cluster
   cd cluster
   curl -O https://raw.githubusercontent.com/ychaker/pi-gitops/main/scripts/setup_pi.sh
   ```
2. Run:
   ```sh
   chmod +x setup_pi.sh
   sudo ./setup_pi.sh
   ```
3. Follow the prompts.

**After the Pi reboots, from your laptop:**

```sh
ssh-copy-id pi@<pi-ip>
```

This will enable passwordless SSH login for Ansible and cluster setup.

Or use the script:

```sh
./scripts/config_k3s.sh
```

### 2. Configure Ansible

Edit `ansible/inventory.ini` with Pi hostnames/IPs.

```ini
[pis]
pi1 ansible_host=192.168.1.71
pi2 ansible_host=192.168.1.72
pi3 ansible_host=192.168.1.73
pi4 ansible_host=192.168.1.74
pi5 ansible_host=192.168.1.75
pi6 ansible_host=192.168.1.76
```

### 3. Provision the cluster

On your workstation, install Ansible:

```sh
brew install ansible
```

Run the playbook to install k3s and dependencies on all Pis:

```sh
ansible-playbook -i ansible/inventory.ini ansible/install_k3s.yml
```

To limit to a particular node:

```sh
ansible-playbook -i ansible/inventory.ini ansible/install_k3s.yml --limit pi2,pi4
```

### 4. Bootstrap Flux

Install Flux CLI ([docs](https://fluxcd.io/docs/installation/)):

```sh
brew install fluxcd/tap/flux
```

Bootstrap Flux, targeting this repo:

```sh
flux bootstrap github \
  --token-auth \
  --owner=ychaker \
  --repository=pi-gitops \
  --branch=main \
  --path=clusters/home-cluster
```

Flux will now reconcile everything under `clusters/home-cluster/`.

### 5. Configure Storage

On your Synology NAS:
- Create an NFS (or SMB) share for persistent data.
- Note: Allow access from all Pi IPs.

Edit `clusters/home-cluster/storage/nfs-pv.yaml` and `nfs-pvc.yaml` with your NAS IP/export details.

Apply storage resources:

```sh
kubectl apply -k clusters/home-cluster/infrastructure/storage
```

### 6. Deploy Applications

- Edit or add HelmRelease/YAML manifests to `clusters/home-cluster/apps/` for services you want.
- Commit and push. Flux will deploy automatically.

### 7. Check status:

```sh
kubectl get helmrepositories -n flux-system
kubectl get helmreleases --all-namespaces
```

---

## Usage Examples

**Reboot all Pis:**

```sh
ansible -i ansible/inventory.ini pis -a "sudo reboot"
```

**Check cluster health:**

```sh
kubectl get nodes
kubectl get pods -A
```

**Add a new app:**
1. Create manifest (see `apps/` examples).
2. Commit & push.
3. Wait for Flux to sync.

**View dashboards:**
- See Traefik ingress for links to Prometheus/Grafana

**Force apply:**

```sh
find clusters/home-cluster/apps/ -type f -name '*.yaml' ! -name 'kustomization.yaml' -print0 | xargs -0 -n 1 kubectl apply -f
```

---

## Disaster Recovery

1. Flash new Pis/SDs as above.
2. Run Ansible to provision.
3. Bootstrap Flux.
4. Storage and app state is restored from Git/NAS.

---

## License

MIT
