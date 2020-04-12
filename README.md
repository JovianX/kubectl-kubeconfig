# Generate administrative Kubeconfig file for your cluster

This script generates a Kubeconfig file that allows full administrative access to your cluster
Please note that this creates a Kubernetes service account 'jovianx-admin' with *CLUSTER-ADMIN* role in the 'jovianx-system' namespace.



```bash
$ ./kubeconfig-create.sh
```
