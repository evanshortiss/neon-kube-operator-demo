# Setup a Kubernetes Cluster using Kind

This README explains how to create a Kubernetes cluster using
[Kind](https://kind.sigs.k8s.io/). It assumes you're using macOS or Linux-based
environment. The Argo CD instance running inside that cluster will be exposed
online using the [ngrok Ingress Controller for Kubernetes](https://ngrok.com/docs/using-ngrok-with/k8s/). 

## Requirements

Install [Docker](https://docs.docker.com/engine/install/) on your development
machine.

_Note: If you're using macOS, refer to the Docker [resources guide for macOS](https://docs.docker.com/desktop/settings/mac/#resources) to ensure your Docker installation has access to a couple of cores and gigabytes of RAM before continuing._

Install the following CLIs. Most are available via package managers suc as
[`brew`](https://brew.sh/):

* [kubectl](https://kubernetes.io/docs/reference/kubectl/)
* [helm](https://helm.sh/docs/intro/install/)
* [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

## Setup

A `setup.sh` script is included in this directory to simplify the creation of
your Kubernetes cluster using Kind, and the installation and configuration of
Argo CD.

_Note: If you're using an unpaid ngrok account, go to **Cloud Edge > Domains** and create a new domain. Use that domain as the value for the `NGROK_ARGOCD_HOSTNAME` in the script below._

```bash
cd kind-cluster/

# Edit the "owner" and "repoURL" fields to match your GitHub org/username
vi application-set.yaml

# Run the setup script with your NGROK credentials
NGROK_API_KEY="api-key-goes-here" \
NGROK_AUTHTOKEN="authtoken_goes_here" \
NGROK_ARGOCD_HOSTNAME="argocd.$USER.ngrok.app" \
./setup.sh
```
