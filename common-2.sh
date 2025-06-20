#!/bin/bash

# Using Kubernetes 1.28.5 with containerd instead of CRI-O (more reliable)
KUBERNETES_VERSION="1.28.5-1.1"

set -euxo pipefail

# ↪ Suppress VirtualBox guest additions warnings (optional)
export VBOX_GA_INSTALL_TIMEOUT=0

# disable swap
sudo swapoff -a
# ↪ More robust crontab update
TMP_CRON=$(mktemp)
(crontab -l 2>/dev/null | grep -v "@reboot /sbin/swapoff -a"; echo "@reboot /sbin/swapoff -a") > "$TMP_CRON"
crontab "$TMP_CRON" && rm -f "$TMP_CRON"

sudo apt-get update -y

# Install containerd instead of CRI-O
# ↪ Add noninteractive frontend
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl params
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# ↪ Suppress sysctl warnings
sudo sysctl --system >/dev/null 2>&1 || true

# Install Kubernetes components
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg

# Add Kubernetes repository
sudo rm -f /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
# ↪ Noninteractive install
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y jq

local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF
