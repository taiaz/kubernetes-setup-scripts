#!/bin/bash

# Log the entire process to a file
LOG_FILE="install_ingress_cert_manager.log"
exec > >(tee -a ${LOG_FILE} ) 2>&1

# Add Helm repository for Ingress Nginx
echo "Adding Ingress Nginx Helm repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update

# Install Ingress Nginx
echo "Installing Ingress Nginx..."
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# Add Helm repository for Cert-Manager
echo "Adding Jetstack Helm repository for Cert-Manager..."
helm repo add jetstack https://charts.jetstack.io

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update

# Install Cert-Manager
echo "Installing Cert-Manager..."
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true

# Check the status of the pods in the ingress-nginx namespace
echo "Checking the status of Ingress Nginx pods..."
kubectl get pods -n ingress-nginx

# Check the status of the pods in the cert-manager namespace
echo "Checking the status of Cert-Manager pods..."
kubectl get pods -n cert-manager

echo "Ingress Nginx and Cert-Manager setup completed successfully!"
