#!/bin/bash

# Log the entire process to a file
LOG_FILE="k8s_worker_setup.log"
exec > >(tee -a ${LOG_FILE} ) 2>&1

# Update the package list
echo "Updating package list..."
sudo apt-get update

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y docker.io

# Enable and start Docker
echo "Enabling and starting Docker..."
sudo systemctl enable docker
sudo systemctl start docker
echo "Checking Docker status..."
sudo systemctl status docker

# Install kubelet and kubeadm (kubectl is not needed for worker nodes)
echo "Setting up Kubernetes repository..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "Updating package list and installing kubelet and kubeadm..."
sudo apt update
sudo apt install -y kubelet kubeadm
sudo apt-mark hold kubelet kubeadm

# Enable kubelet
echo "Enabling kubelet service..."
sudo systemctl enable kubelet
echo "Kubelet Version:"
kubelet --version
echo "Kubeadm Version:"
kubeadm version

# Open necessary ports for the Worker Node with UFW
echo "Opening necessary ports with UFW..."
sudo systemctl start ufw
# Kubelet API
sudo ufw allow 10250/tcp
# NodePort Services (range of ports for NodePort services)
sudo ufw allow 30000:32767/tcp
# Optional: Kubelet Read-Only
sudo ufw allow 10255/tcp

# Finish setup
echo "Worker node setup completed successfully! Please use the kubeadm join command provided by the master node to join the cluster."
