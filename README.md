![](kubectl-kubeconfig-logo.png)



[![Open Source](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://opensource.org/)
[![GitHub license](https://img.shields.io/github/license/JovianX/kubectl-kubeconfig)](https://github.com/JovianX/kubectl-kubeconfig)
![GitHub contributors](https://img.shields.io/github/contributors/JovianX/kubectl-kubeconfig)
![Discord](https://img.shields.io/discord/1014893148599754894?style=flat)
[![GitHub stars](https://img.shields.io/github/stars/JovianX/kubectl-kubeconfig)](https://github.com/JovianX/kubectl-kubeconfig/stargazers)

| **Please star ⭐ the repo if you find it useful.** |
| -------------------------------------------------- |

# `kubectl-kubeconfig` Plugin

A **kubectl plugin** that generates token-based (authentication via kubernetes service-account token)  kubeconfig files for your Kubernetes clusters.

## Use-Cases

```
✅ Grant Kubernetes cluster access without cloud provider auth helper
✅ Use Servce-Accounts tokens to provide access to a Kubernetes cluster
✅ Automagically add clusters to JovianX Service Hub via Kubectl command
```

## Installation

Install the plugin via bash command

```
curl -s https://kubeconfig.jovianx.app/install | bash
```

## Usage

See full list of available options by running:

```
$ kubectl kubeconfig generate --help

Generate a token-based (authentication via kubernetes service-account token) Kubeconfig file,
based on configured kubeconfig context.

Available parameters:
    --output-file       Path to creating Kubernetes configuration file.
                        Default: './kubeconfig-jovianx-admin-jovianx-system.yaml'.

    --context           Name of existing context to use during generation of a
                        new kubeconfig file. Defaults to current context of existing
                        configuration.

    --service-account   Name of service account. Defaults to 'jovianx-admin'.

    --role              Name of role during creation of cluster role binding.
                        Defaults to 'cluster-admin'.

    --namespace         Name of namespace where to service account will be
                        created. Defaults to 'jovianx-system'.

    --jwt-token         JWT token to authenticate on configuration upload. If
                        provided the generated kubeconfig file will be uploaded to
                        JovianX Service Hub. Note: when set the kubeconfig file
                        is not saved locally.

    --jovianx-url       JovianX host URL. Defaults to: 'https://hub.jovianx.app'

    --debug             if this flag set additional output is provided.

    --help              Print this message.
```
