# TJ's Kubernetes Service

🚀 **Automated Talos Kubernetes cluster deployment on Proxmox VE**

Deploy a production-ready Kubernetes cluster with 3 control planes + 3 workers using Terraform and Talos Linux.

---

## ✨ What You Get

| Component | Description |
|-----------|-------------|
| **Talos Linux** | Immutable, secure Kubernetes OS (no SSH, minimal attack surface) |
| **High Availability** | 3 control plane nodes with Virtual IP failover |
| **QEMU Guest Agent** | Pre-installed via Talos Factory for Proxmox integration |
| **Infrastructure as Code** | Fully automated with Terraform |

---

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Post Install](#-post-install)
- [Scaling the Cluster](#-scaling-the-cluster)
- [Troubleshooting](#-troubleshooting)

---

## 📦 Prerequisites

### Required Tools

Install these on your local machine:

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y curl wget git

# Terraform (Infrastructure provisioning)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# kubectl (Kubernetes CLI)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# talosctl (Talos CLI)
curl -sL https://talos.dev/install | sh
```

### Proxmox VE Setup

1. **Enable SSH Access** to your Proxmox host with an SSH key (password auth won't work)

2. **Create an API Token:**
   - Go to: Datacenter → Permissions → API Tokens → Add
   - User: `root@pam`
   - Token ID: `terraform`
   - **Uncheck** "Privilege Separation"
   - Copy the token (looks like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

### Network Planning

You need to reserve static IPs (via DHCP reservation) for your nodes:

| Purpose | Count | Example IPs | Notes |
|---------|-------|-------------|-------|
| Virtual IP (VIP) | 1 | `192.168.1.50` | Shared by control planes for HA |
| Control Planes | 3 | `192.168.1.51`, `.52`, `.53` | Run Kubernetes control plane |
| Worker Nodes | 3 | `192.168.1.61`, `.62`, `.63` | Run your workloads |

**Important:** Create DNS records and DHCP reservations matching the MAC addresses you'll configure.

---

## 🚀 Installation

### Step 1: Cd in Repository 

```bash
cd TJs-Kubernetes-Service
```

### Step 2: Configure Proxmox Credentials

Create `vars/config.env` with your Proxmox connection details:

```bash
cp vars/config.env.example vars/config.env
```

Edit `vars/config.env`:

```bash
export PROXMOX_VE_ENDPOINT="https://192.168.1.10:8006"
export PROXMOX_VE_INSECURE="true"
export PROXMOX_VE_API_TOKEN="root@pam!terraform=YOUR-TOKEN-HERE"
export PROXMOX_VE_SSH_AGENT="true"
export PROXMOX_VE_SSH_USERNAME="root"
```

### Step 3: Add SSH Key to Agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/your_proxmox_key
```

### Step 4: Configure Cluster Settings

Review `variables.tf` and create a tfvars file for your environment:

```bash
cp vars/test.tfvars vars/cluster.tfvars
```

Edit `vars/cluster.tfvars` with your settings:

```hcl
# Proxmox Connection
proxmox_hostname     = "192.168.1.10"            # Your Proxmox IP/hostname
proxmox_ssh_key_path = "/home/master/.ssh/id_rsa"  # FULL path to SSH key (no ~)

# Storage
talos_image_node_name = "pve"                    # Proxmox node name
controlplane_node_name = "pve"
workernode_node_name   = "pve"

# Network - MUST match your DHCP reservations
talos_virtual_ip       = "192.168.1.50"          # HA Virtual IP
controlplane_ip_prefix = "192.168.1.5"           # Creates .51, .52, .53
workernode_ip_prefix   = "192.168.1.6"           # Creates .61, .62, .63

# MAC Addresses - MUST match your DHCP reservations
controlplane_mac_address_prefix = "00:00:00:00:00:1"  # Creates :11, :12, :13
workernode_mac_address_prefix   = "00:00:00:00:00:2"  # Creates :21, :22, :23

# VM IDs
controlplane_vmid_prefix = 800                   # Creates 801, 802, 803
workernode_vmid_prefix   = 900                   # Creates 901, 902, 903

# Resources (adjust based on your hardware)
controlplane_cpu_cores = 2
controlplane_memory    = 3072                    # 3GB per control plane
workernode_cpu_cores   = 4
workernode_memory      = 8192                    # 8GB per worker
```

### Step 5: Create DNS & DHCP Reservations

Before deploying, create DNS records and DHCP reservations matching your config:

| Hostname | MAC Address | IP Address |
|----------|-------------|------------|
| k8s-vip | N/A | 192.168.1.50 |
| k8s-cp-1 | 00:00:00:00:00:11 | 192.168.1.51 |
| k8s-cp-2 | 00:00:00:00:00:12 | 192.168.1.52 |
| k8s-cp-3 | 00:00:00:00:00:13 | 192.168.1.53 |
| k8s-worker-1 | 00:00:00:00:00:21 | 192.168.1.61 |
| k8s-worker-2 | 00:00:00:00:00:22 | 192.168.1.62 |
| k8s-worker-3 | 00:00:00:00:00:23 | 192.168.1.63 |

### Step 6: Deploy the Cluster

```bash
# Load Proxmox credentials
source vars/config.env

# Initialize Terraform
terraform init

# (Optional) Create a workspace for multiple clusters
terraform workspace new cluster

# Review what will be created
terraform plan -var-file="vars/cluster.tfvars"

# Deploy! (Type 'yes' when prompted)
terraform apply -var-file="vars/cluster.tfvars"
```

⏳ **Wait 5-10 minutes** for the cluster to bootstrap.

### Step 7: Configure kubectl Access

```bash
# Create config directories
mkdir -p ~/.kube ~/.talos

# Export configurations from Terraform
terraform output -raw kubeconfig > ~/.kube/config-cluster
terraform output -raw talosconfig > ~/.talos/config-cluster

# Set as default (or use kubecm/kubectx to manage multiple clusters)
export KUBECONFIG=~/.kube/config-cluster
export TALOSCONFIG=~/.talos/config-cluster
```

### Step 8: Verify the Cluster

```bash
# Watch nodes come online (Ctrl+C to exit)
watch kubectl get nodes

# Expected output (after a few minutes):
# NAME           STATUS   ROLES           AGE   VERSION
# k8s-cp-1       Ready    control-plane   5m    v1.33.6
# k8s-cp-2       Ready    control-plane   5m    v1.33.6
# k8s-cp-3       Ready    control-plane   5m    v1.33.6
# k8s-worker-1   Ready    <none>          4m    v1.33.6
# k8s-worker-2   Ready    <none>          4m    v1.33.6
# k8s-worker-3   Ready    <none>          4m    v1.33.6
```

🎉 **Congratulations!** Your Kubernetes cluster is ready!

---

## 🔧 Post Install

### Enabling QEMU Guest Agent

The QEMU Guest Agent is included in the Talos image (via [Talos Factory](https://factory.talos.dev/)), but needs an **upgrade** to activate it. This allows Proxmox to gracefully shutdown VMs and report IP addresses.

```bash
# Upgrade all nodes to enable QEMU Guest Agent
NODES=$(kubectl get nodes --no-headers | awk '{print $1}' | tr '\n' ',')
./bin/manage_nodes upgrade $NODES
```

> **Tip:** The `manage_nodes` script accepts both node names (`k8s-cp-1`) and IP addresses (`192.168.1.51`).

### Installing a Different CNI (Optional)

By default, Talos uses **Flannel**. To use a different CNI like Cilium:

1. Set `talos_disable_flannel = true` in your tfvars **before** deploying
2. The cluster won't be functional until you install a CNI
3. Install your preferred CNI (e.g., [Cilium](https://cilium.io/))

If you see pending Certificate Signing Requests after installing a CNI:

```bash
# View pending CSRs
kubectl get csr

# Approve them manually (or install kubelet-csr-approver)
kubectl certificate approve <csr-name>
```

---

## 📈 Scaling the Cluster

### Adding/Removing Nodes

Simply update `controlplane_num` or `workernode_num` in your tfvars and re-apply:

```bash
# Edit your tfvars file to change node count
# Then apply the changes
terraform apply -var-file="vars/cluster.tfvars"
```

When scaling **down**, Terraform automatically removes nodes from Kubernetes.

### Upgrading Nodes

After adding new nodes, upgrade them to enable QEMU Guest Agent:

```bash
./bin/manage_nodes upgrade k8s-worker-4
```

### Limitations

- Maximum **9 control planes** and **9 workers** (due to IP/MAC addressing scheme)
- Cannot choose which specific node to remove when scaling down (always removes the last one)

---

## 🔍 Troubleshooting

### Nodes Not Becoming Ready

1. **Check Talos status:**
   ```bash
   talosctl health --nodes 192.168.1.51
   ```

2. **View Talos logs:**
   ```bash
   talosctl logs --nodes 192.168.1.51
   ```

3. **Check VM console** in Proxmox for boot errors

### Terraform Stuck Deleting VMs

Proxmox can't gracefully shutdown VMs without QEMU Guest Agent. If Terraform hangs during destroy:

1. **Option A:** Manually stop VMs in Proxmox, then retry `terraform destroy`

2. **Option B:** Force remove via SSH:
   ```bash
   ssh root@proxmox "qm list | grep k8s | awk '{print \$1}' | xargs -L1 qm stop"
   sleep 5
   ssh root@proxmox "qm list | grep k8s | awk '{print \$1}' | xargs -L1 qm destroy"
   ```

3. Then run: `terraform destroy -var-file="vars/cluster.tfvars"`

### Cannot Connect to Kubernetes API

1. Verify the Virtual IP is reachable: `ping 192.168.1.50`
2. Check if any control plane is running: `talosctl health --nodes 192.168.1.51`
3. Ensure your kubeconfig is correct: `kubectl cluster-info`

### Upgrade Fails

If `manage_nodes upgrade` fails:

```bash
# Check the installer image
terraform output talos_installer_image

# Manual upgrade with verbose output
talosctl upgrade --nodes 192.168.1.51 \
  --image $(terraform output -raw talos_installer_image) \
  --preserve=true
```

---

## 📚 Additional Resources

- [Talos Documentation](https://www.talos.dev/latest/)
- [Talos Factory](https://factory.talos.dev/) - Customize your Talos image
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Terraform Talos Provider](https://registry.terraform.io/providers/siderolabs/talos/latest/docs)

---

## 📄 License

See [LICENSE](LICENSE) file.
