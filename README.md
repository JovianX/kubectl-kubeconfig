# Generate administrative Kubeconfig file for your cluster


To generate an administrative Kubeconfig file follow steps 


1. Clone this repo
```
$ git clone https://github.com/JovianX/Generate-Kubeconfig
```

2. Run the kubeconfig-create.sh script, this script generates a Kubeconfig file that allows full administrative access to the cluster.
```bash
$ ./kubeconfig-create.sh
Generate administrative Kubeconfig file for your cluster

This script generates a Kubeconfig file that allows full administrative access to your cluster
Please note that this creates a Kubernetes service account 'jovianx-admin' with *CLUSTER-ADMIN* role in the 'jovianx-system' namespace.

Proceed?[Y/n] 
```

> Note that this creates a Kubernetes service account 'jovianx-admin' with *CLUSTER-ADMIN* role in the 'jovianx-system' namespace.
