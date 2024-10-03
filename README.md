# Kubernetes Setup Guide for Master Node and Worker Node

This document provides instructions for setting up the **master node** and **worker node** in a Kubernetes cluster using automated setup scripts.

## Master Node Setup

1. **Grant execute permissions for the master setup script:**

   ```bash
   chmod +x k8s-setup-script.sh
   ```

2. **Run the master setup script:**

   ```bash
   ./k8s-master-setup.sh
   ```

## Worker Node Setup

1. **Grant execute permissions for the worker setup script:**

   ```bash
   chmod +x k8s-worker-setup.sh
   ```

2. **Run the worker setup script:**

   ```bash
   ./k8s-worker-setup.sh
   ```


## Worker Node Join Guide for Kubernetes Cluster

1. **Retrieve the `kubeadm join` command from the Master Node:**

   - After running the master setup script, you will see the `kubeadm join` command in the `k8s_setup.log` file.
   - Use the following command to extract the `kubeadm join` command:

     ```bash
     cat k8s_setup.log | grep "kubeadm join"
     ```

2. **Run the `kubeadm join` command on the Worker Node:**

   - Log in to the worker node.
   - Run the `kubeadm join` command that you retrieved from the master node:

     ```bash
     sudo kubeadm join <master_ip>:<port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
     ```

3. **Verify that the Worker Node has successfully joined:**

   - Go back to the master node and run the following command to verify:

     ```bash
     kubectl get nodes
     ```

   - The worker node should have the `Ready` status, indicating that it has successfully joined the cluster.


## Notes

- Before running any script, ensure you have granted execute permissions (`chmod +x`) for the script files.
- The above commands need to be executed with root privileges or using `sudo` to ensure sufficient permissions for making system changes.
- Make sure that the `kubeadm join` command is executed only after the worker node has completed the installation of Docker and `kubelet`.
- **Firewall Rules**: Ensure that necessary ports are open on both the master and worker nodes to allow communication between them.
- **Swap Disabled**: Kubernetes requires swap to be disabled on all nodes for stability. Run `sudo swapoff -a` to disable it.
- **Hostname Configuration**: Ensure each node has a unique hostname to avoid conflicts.
- **Time Synchronization**: Ensure all nodes have synchronized time using `ntp` or `chrony`.
- **Network Plugin**: The network plugin (e.g., Calico) must be set up on the master node before adding worker nodes.
- **Kubeadm Join Token Expiration**: If the `kubeadm join` token expires, create a new one using `sudo kubeadm token create --print-join-command`.
- **Kubeconfig Access**: Ensure the kubeconfig file is configured properly for `kubectl` access (`$HOME/.kube/config`).





