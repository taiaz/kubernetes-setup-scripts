# Ingress Nginx and Cert-Manager Setup Guide

This guide provides instructions for setting up **Ingress Nginx** and **Cert-Manager** in your Kubernetes cluster using the provided YAML configuration files and Bash script.


## Prerequisites

- **Kubernetes Cluster**: Ensure that you have a running Kubernetes cluster.
- **Helm Installed**: Make sure Helm is already installed on your system.
- **kubectl Configured**: Ensure `kubectl` is properly configured to communicate with your Kubernetes cluster.


## Folder Structure

- This guide uses the following files to deploy **Ingress Nginx** and **Cert-Manager**:

    ```plaintext
    k8s-ingress-cert-setup/
    ├── ingress-cert-setup-guide.md          # The setup guide
    ├── ingress-nginx-service.yaml           # Service configuration for Ingress Nginx
    ├── install-ingress-cert-manager.sh      # Bash script to automate installation
    ├── letsencrypt-clusterissuer.yaml       # ClusterIssuer configuration for Cert-Manager
    ```

## Installation

### Step 1: Install Ingress Nginx and Cert-Manager Using the Script

1. **Grant execute permissions for the script**:

- Before running the script, ensure that it has executable permissions:

   ```bash
   chmod +x install-ingress-cert-manager.sh
   ```

2. **Run the script**:

- Execute the script to install **Ingress Nginx** and **Cert-Manager**:

    ```bash
    ./install-ingress-cert-manager.sh
    ```

- The script will automatically add the necessary Helm repositories, update them, and install both Ingress Nginx and Cert-Manager in their respective namespaces (`ingress-nginx` and `cert-manager`).

3. **Verify the Installation**:

- The script will check the status of the pods in the `ingress-nginx` and `cert-manager` namespaces to ensure that they are running successfully. If any issues occur, consult the log file `install_ingress_cert_manager.log` for more details.

### Step 2: Configure Ingress Nginx Service

1. **Apply the `ingress-nginx-service.yaml` file**:

- Since you are using **MetalLB** for load balancing, there is no need to manually specify an `externalIPs` field. MetalLB will automatically assign an available IP address from the configured IP pool.

- Apply the service configuration using `kubectl`:

    ```bash
    kubectl apply -f ingress-nginx-service.yaml
    ```

### Step 3: Set Up Let's Encrypt ClusterIssuer

1. **Edit the `letsencrypt-clusterissuer.yaml` file**:

   - The `letsencrypt-clusterissuer.yaml` file contains the configuration for **Cert-Manager** to use **Let's Encrypt** for issuing SSL certificates. Ensure that the `email` field is updated with your own email address to receive notifications from Let's Encrypt regarding the status of your certificates.

2. **Apply the `letsencrypt-clusterissuer.yaml` file**:

   - Apply the configuration using `kubectl`:

     ```bash
     kubectl apply -f letsencrypt-clusterissuer.yaml
     ```

   - This command will create a `ClusterIssuer` resource named `letsencrypt-prod` that can be used by your Ingress resources to request SSL certificates from Let's Encrypt.

### Verification

1. **Check the Status of Ingress Nginx Pods**:

   - To ensure the Ingress Nginx controller is running properly, use the following command:

     ```bash
     kubectl get pods -n ingress-nginx
     ```

   - All pods should be in the `Running` state.

2. **Check the Status of Cert-Manager Pods**:

   - Verify that the Cert-Manager components are running properly:

     ```bash
     kubectl get pods -n cert-manager
     ```

   - Again, ensure that all pods are in the `Running` state.

3. **Verify the ClusterIssuer**:

   - To check that the `ClusterIssuer` is ready:

     ```bash
     kubectl get clusterissuer letsencrypt-prod
     ```

   - The status should indicate that it is ready to issue certificates.

### Step 4: Configure an Ingress Resource to Use Let's Encrypt Certificates

1. **Create an Ingress Resource**:

   - To request a certificate from Let's Encrypt using **Cert-Manager**, you need to create an Ingress resource that references the `ClusterIssuer`.
   - Below is an example of how to create an Ingress resource:

     ```yaml
     apiVersion: networking.k8s.io/v1
     kind: Ingress
     metadata:
       name: example-ingress
       namespace: default
       annotations:
         cert-manager.io/cluster-issuer: "letsencrypt-prod"
     spec:
       rules:
       - host: example.yourdomain.com
         http:
           paths:
           - path: /
             pathType: Prefix
             backend:
               service:
                 name: example-service
                 port:
                   number: 80
       tls:
       - hosts:
         - example.yourdomain.com
         secretName: example-tls
     ```

2. **Apply the Ingress Resource**:

   - Save the above configuration to a file named `example-ingress.yaml`, then apply it using `kubectl`:

     ```bash
     kubectl apply -f example-ingress.yaml
     ```

   - Cert-Manager will use the `letsencrypt-prod` ClusterIssuer to request a certificate for the specified host (`example.yourdomain.com`), and store it in a Kubernetes secret named `example-tls`.

### Summary

- **Installed Ingress Nginx**: Installed and configured the Ingress Nginx controller using Helm and exposed it with a LoadBalancer service managed by MetalLB.
- **Installed Cert-Manager**: Set up Cert-Manager for automated SSL certificate management using Let's Encrypt.
- **Configured ClusterIssuer**: Created a ClusterIssuer named `letsencrypt-prod` to automatically issue SSL certificates for your Ingress resources.
- **Configured Ingress Resource**: Created an example Ingress resource to verify that certificates are being issued by Let's Encrypt.

Follow these steps to complete the setup of **Ingress Nginx** and **Cert-Manager** in your Kubernetes cluster, ensuring that your applications can handle external traffic securely with valid SSL certificates.

### Notes

- **Namespaces**: The script and YAML files will create necessary namespaces (`ingress-nginx` and `cert-manager`) if they do not already exist.
- **External IP Address**: Since MetalLB is being used, an IP address will be automatically assigned from the configured pool to expose the Ingress Nginx service.
- **Certificate Renewal**: Let's Encrypt certificates issued by **Cert-Manager** are valid for 90 days, and **Cert-Manager** will automatically handle renewals before expiration.
- **Logs**: The installation process is logged to `install_ingress_cert_manager.log`, which can be used for troubleshooting if any issues occur.
- **Ingress Domain**: Ensure that the domain (`example.yourdomain.com`) used in the Ingress resource is correctly pointed to the IP address assigned by MetalLB in your DNS configuration.
