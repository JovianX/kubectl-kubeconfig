# Generate administrative Kubeconfig file for your cluster


To generate an administrative Kubeconfig file follow steps run the following command 


```bash 
$ bash <(curl -s https://raw.githubusercontent.com/JovianX/Generate-Kubeconfig/master/kubeconfig-create.sh)
```


```
Generate administrative Kubeconfig file for your cluster

This script generates a Kubeconfig file that allows full administrative access to your cluster
Please note that this creates a Kubernetes service account 'jovianx-admin' with *CLUSTER-ADMIN* role in the 'jovianx-system' namespace.

Proceed?[Y/n] 
```

Note: that this creates a Kubernetes service account 'jovianx-admin' with *CLUSTER-ADMIN* role in the 'jovianx-system' namespace.
