# MetalLB Setup Guide

This guide provides instructions to install and configure MetalLB in your Kubernetes cluster, specifically using the `IPAddressPool` and `L2Advertisement` resources to manage IP address allocation and Layer 2 advertisement.


## Prerequisites

- **Kubernetes Cluster**: Make sure you have a running Kubernetes cluster.
- **Namespace `metallb-system`**: MetalLB components should be deployed in the `metallb-system` namespace. If the namespace does not exist, create it using:

    ```bash
    kubectl create namespace metallb-system
    ```


## Installation

### Step 1: Install MetalLB

- To install MetalLB in your Kubernetes cluster, apply the manifest file from the official MetalLB GitHub repository:

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
    ```

### Step 2: Verify Installation

- After installing MetalLB, verify that the necessary pods are running properly:

    ```bash
    kubectl get pods -n metallb-system
    ```

You should see several pods, such as the controller and speaker pods, running in the `metallb-system` namespace. Ensure that all pods are in the `Running` state before proceeding to the next step.


## Configuring MetalLB

Now that MetalLB is installed, you need to configure it to manage IP addresses for services of type `LoadBalancer`.

### Step 3: Create IPAddressPool

The `IPAddressPool` resource defines a range of IP addresses that MetalLB can allocate to services.

1. Save the following YAML as `ipaddresspool.yaml`:

    ```yaml
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: my-ip-pool
      namespace: metallb-system
    spec:
      addresses:
      - 192.168.1.240/32
      - 192.168.1.241/32  # Example: You can add more IPs here
      autoAssign: true
    ```

2. Apply the configuration using the following command:

    ```bash
    kubectl apply -f ipaddresspool.yaml
    ```

   This command creates an IP address pool named `my-ip-pool` with multiple IPs (`192.168.1.240`, `192.168.1.241`). The `autoAssign: true` flag allows MetalLB to automatically assign addresses from this pool to services.

### Step 4: Create L2Advertisement

The `L2Advertisement` resource instructs MetalLB to use Layer 2 mode to advertise the IP addresses from the pool.

1. Save the following YAML as `l2advertisement.yaml`:

    ```yaml
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: my-l2-advertisement
      namespace: metallb-system
    spec:
      ipAddressPools:
        - my-ip-pool
    ```

2. Apply the configuration using the following command:

    ```bash
    kubectl apply -f l2advertisement.yaml
    ```

   This command sets up Layer 2 advertisement for the IP addresses defined in `my-ip-pool`.


## Verification

After applying the configurations, verify that MetalLB is properly set up:

1. **Check IPAddressPool Resource**:

    ```bash
    kubectl get ipaddresspool -n metallb-system
    ```

   You should see the `my-ip-pool` listed, confirming that the IP address pool has been successfully created.

2. **Check L2Advertisement Resource**:

    ```bash
    kubectl get l2advertisement -n metallb-system
    ```

   You should see `my-l2-advertisement` listed, indicating that Layer 2 advertisement is set up correctly.


## Testing the Setup

To test if MetalLB is working as expected, you can create a `LoadBalancer` service in Kubernetes.

### Example LoadBalancer Service

1. Save the following YAML as `example-service.yaml`:

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: my-service
      namespace: default
    spec:
      type: LoadBalancer
      selector:
        app: my-app
      ports:
        - protocol: TCP
          port: 80
          targetPort: 8080
    ```

2. Apply the service configuration:

    ```bash
    kubectl apply -f example-service.yaml
    ```

3. Verify that MetalLB has assigned an IP address from the pool to the service:

    ```bash
    kubectl get service my-service
    ```

   You should see an external IP address assigned to the `my-service` service, which is one of the IP addresses from the `my-ip-pool`.


## Troubleshooting

- **Pods Not Running**: If any MetalLB pods are not running, check the logs for more details:

    ```bash
    kubectl logs <pod-name> -n metallb-system
    ```

- **No External IP Assigned**: If no external IP address is assigned to your service, ensure that:
  - The `IPAddressPool` and `L2Advertisement` configurations have been applied correctly.
  - The IP addresses in the pool (`192.168.1.240`, `192.168.1.241`) are available and not used by another service or device.


## Summary

- **MetalLB Installation**: Installed MetalLB in the `metallb-system` namespace.
- **IPAddressPool** (`ipaddresspool.yaml`): Defined a pool of IP addresses (`192.168.1.240`, `192.168.1.241`) for MetalLB to allocate.
- **L2Advertisement** (`l2advertisement.yaml`): Configured MetalLB to advertise the IP addresses using Layer 2.
- **Service Testing**: Created a sample LoadBalancer service to verify that MetalLB assigns an external IP address.

MetalLB provides a simple way to enable load balancing for services in your Kubernetes cluster by managing a pool of IP addresses and advertising them over the network.


## Notes

- Ensure that the IP addresses (`192.168.1.240`, `192.168.1.241`, ...) are available in your network and are not being used elsewhere.
- MetalLB should only be deployed in a network environment that supports Layer 2 or BGP, depending on your configuration.
- Check the status of MetalLB components regularly to ensure that the load balancing is working correctly.
