#!/bin/bash

# Change into this directory, and exit on script errors
cd $(dirname $0)
set -e

LOG_FILE="/tmp/nkp-setup.log"
CLUSTER_NAME="${CLUSTER_NAME:-argocd-previews}"
NGROK_ARGOCD_HOSTNAME="${NGROK_ARGOCD_HOSTNAME:-$(whoami).argocd.ngrok.app}"
WEBHOOK_SECRET=$(head -c 512 /dev/urandom | shasum | head -c 40)

required_vars=(NGROK_API_KEY NGROK_AUTHTOKEN NGROK_ARGOCD_HOSTNAME CLUSTER_NAME)
required_pkgs=("docker" "kind" "helm" "kubectl")

# Remove prior log file
rm -f $LOG_FILE

# Verify that required tools are installed
for pkg in "${required_pkgs[@]}"; do
  has_pkg=$(which $pkg)

  if [ -z "${has_pkg}" ]; then
    echo "$pkg is was not found. Please install $pkg"
    exit 1
  fi
done

# Verify that required environment variables are set
for var in "${required_vars[@]}"; do
  if [[ -z "${!var}" ]]; then
    echo "Please set $var when running the script, e.g \"$var=value_goes_here ./setup.sh\""
    exit 1
  fi
done

# Check if the cluster already exists, and if so exit with a error
existing_cluster=$(kind get clusters 2>/dev/null || echo "" | grep "$CLUSTER_NAME")
if [[ "$CLUSTER_NAME" == "$existing_cluster" ]]; then
    echo "A kind cluster named $CLUSTER_NAME already exists. To delete it, run:"
    echo "kind delete cluster --name $CLUSTER_NAME"
    exit 1
fi

# Create a Kubernetes cluster and set it as the current kubectl context
echo "Starting cluster setup. Logs and errors will be written to $LOG_FILE"
echo ""
echo "Creating Kind cluster..."
kind create cluster --name $CLUSTER_NAME >> $LOG_FILE
kubectl config use-context 'kind-argocd-previews' >> $LOG_FILE

# Create a namespace and deploy Argo CD into it
echo "Installing Argo CD..."
kubectl create namespace argocd >> $LOG_FILE
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml >> $LOG_FILE

# Patch Argo CD to stop ngrok ingress health from causing the Argo CD
# application to get stuck in a "progressing" status, and create a webhook
# secret for GitHub webhook integration
echo "Configuring Argo CD..."
kubectl patch configmap argocd-cm -n argocd --patch "$(cat argocd-cm.patch.yaml)" >> $LOG_FILE
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data": {"server.insecure": "true"}}' >> $LOG_FILE
kubectl patch secret argocd-secret -n argocd --type='json' -p='[{"op": "add", "path": "/stringData", "value": {"webhook.github.secret": "'"$WEBHOOK_SECRET"'"}}]' >> $LOG_FILE
kubectl apply -f application-set.yaml >> $LOG_FILE
kubectl rollout restart deployment/argocd-server -n argocd >> $LOG_FILE

# Install ngrok ingress controller and...
echo "Installing ngrok ingress controller..."
helm repo add ngrok https://ngrok.github.io/kubernetes-ingress-controller >> $LOG_FILE
helm install ngrok-ingress-controller ngrok/kubernetes-ingress-controller \
  --namespace ngrok-ingress-controller \
  --create-namespace \
  --set credentials.apiKey=$NGROK_API_KEY \
  --set credentials.authtoken=$NGROK_AUTHTOKEN >> $LOG_FILE

# ...create an ingress to access Argo CD over HTTPS from anywhere
NGROK_ARGOCD_HOSTNAME=$NGROK_ARGOCD_HOSTNAME envsubst < ./argocd-ingress.yaml | kubectl apply -f - >> $LOG_FILE

# Install sealed secrets controller
echo "Installing sealed secrets controller"
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets -n kube-system --set-string fullnameOverride=sealed-secrets-controller sealed-secrets/sealed-secrets

# Print a helpful message with Argo CD login details
echo "Cluster setup complete. Getting Argo CD admin password..."
ARGOCD_PASSWORD=""
max_retries=10
retry_count=0
retry_delay=10

# Get the Argo CD password, as soon as it's available
while [ $retry_count -lt $max_retries ]; do
  ((retry_count++))
  ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' 2>/dev/null | base64 --decode)

  if [ $? -eq 0 ] && [ -n "$ARGOCD_PASSWORD" ]; then
    break
  else
    echo "Failed to retrieve Argo CD password. Retrying in $retry_delay seconds. (Attempt $retry_count/$max_retries)"
    sleep $retry_delay
  fi
done

if [ $retry_count -eq $max_retries ]; then
    echo ""
    echo "Maximum retry count reached. Use the following command to retreive the password when Argo CD is ready:"
    echo "kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode"
fi

echo ""
echo "Login to Argo CD using the following parameters:"
echo "- Argo CD URL: https://$NGROK_ARGOCD_HOSTNAME"
echo "- Username: admin"
echo "- Password: $ARGOCD_PASSWORD"
echo "- WebHook URL: https://$NGROK_ARGOCD_HOSTNAME/api/webhook (application/json)"
echo "- WebHook Secret: $WEBHOOK_SECRET"
echo ""
