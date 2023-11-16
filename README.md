# Kube Preview Environments with Neon Database Operator

NOTE: You need to run the [neon-kube-operator](https://github.com/evanshortiss/neon-kube-operator) locally for this demo (at present!)

```bash
git clone git@github.com:evanshortiss/neon-kube-operator.git
cd neon-kube-operator

# Create namespace and a secret containing a Neon API Key
kubectl create namespace neon-operator
kubectl create secret generic neon-operator-secrets \
--from-literal=neon-api-key=$NEON_API_KEY \
-n neon-operator

# Install the operator's CRDs into the kubernetes cluster
# and run the operator in your local environment
make install run
```

## Prerequisites

* Kubernetes cluster with Argo CD installed and exposed via an HTTPS ingress.
* A [Neon account](https://console.neon.tech/sign_in) and project.

_Note: If you'd like help setting up a lightweight Kubernetes on your development machine using [Kind](https://kind.sigs.k8s.io/), visit [_kind-cluster/README.md_](/kind-cluster/README.md)._

## Usage

Click the **Use this template** button in the top-right corner of this
repository. Create a new repository using the following options:

* Repository name: `neon-kube-operator-demo`
* Vsibility: Public

Set these secrets in the *Secrets and variables > Actions* screen from
your new repository's settings screen:

* `DOCKERHUB_USERNAME` - Your Docker Hub username.
* `DOCKERHUB_TOKEN` - A token generated [Account Settings](https://hub.docker.com/settings/security) on Docker Hub.
* `ARGOCD_HOSTNAME` - Strictly the hostname, e.g `argocd.foo.bar` without `https`.

The following secret is optional. It's used to generate a preview URL
provided by [ngrok](https://ngrok.io), and assumes you've installed the 
[ngrok ingress controller](https://ngrok.com/blog-post/ngrok-k8s) on the
cluster where Argo CD is deploying your application. Remember, if you're using
the ngrok free tier you only have access to a single subdomain which limits
your preview environment count.

*Note: If you have an alternative ingress solution configured on your Kubernetes cluster do not set this secret. Instead edit the Helm Chart and GitHub Actions Workflow to use your chosen ingress solution.*

* `NGROK_SUBDOMAIN` - Used to generate a preview URL with the format `pr-$NUMBER.$NGROK_SUBDOMAIN`, e.g `pr-1.evanshortiss.ngrok.app`

