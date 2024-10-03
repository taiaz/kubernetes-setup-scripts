#!/bin/bash

# Log the entire process to a file
LOG_FILE="k8s_setup.log"
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

# Install kubelet, kubeadm, kubectl
echo "Setting up Kubernetes repository..."
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "Updating package list and installing Kubernetes components..."
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
echo "Enabling kubelet service..."
sudo systemctl enable kubelet
echo "Kubelet Version:"
kubelet --version
echo "Kubeadm Version:"
kubeadm version
echo "Kubectl Version:"
kubectl version --client

# Open necessary ports for the Master Node with UFW 
echo "Opening necessary ports with UFW..."
sudo systemctl start ufw 
# API Server
sudo ufw allow 6443/tcp
# Etcd
sudo ufw allow 2379:2380/tcp
# Scheduler
sudo ufw allow 10251/tcp
# Controller Manager
sudo ufw allow 10252/tcp
# Kubelet
sudo ufw allow 10250/tcp
# Authentication/Healthz
sudo ufw allow 10255/tcp

# Initialize Kubernetes Cluster with kubeadm
echo "Initializing Kubernetes cluster..."
kubeadm_output=$(sudo kubeadm init --apiserver-advertise-address=103.173.66.104 --pod-network-cidr=192.168.0.0/16 2>&1)

# Check if kubeadm init succeeded
if [ $? -eq 0 ]; then
    echo "Kubernetes cluster initialized successfully."

    # Save output to log file (already done automatically via 'tee')
    # Extract the join command from the kubeadm init output
    join_command=$(echo "$kubeadm_output" | grep -A 2 "kubeadm join")

    # Log the join command
    echo "=============================================="
    echo "Use the following command to join worker nodes:"
    echo "$join_command"
    echo "=============================================="
else
    echo "Failed to initialize Kubernetes cluster. See the output below for more details:"
    echo "$kubeadm_output"
    exit 1
fi

# Set up kubeconfig for the current user
echo "Setting up kubeconfig for the current user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

# Install Calico as the network plugin for the Kubernetes Cluster
echo "Installing Calico network plugin..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml

# Check the status of Calico operator pods
echo "Checking the status of Calico operator pods..."
kubectl get pods -n tigera-operator
echo "Checking for CRDs related to Calico..."
kubectl get crds | grep 'tigera.io'

# Download and apply Calico custom resources configuration
echo "Downloading and applying Calico custom resources..."
wget https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml
kubectl create -f custom-resources.yaml

echo "Kubernetes setup completed successfully!"
