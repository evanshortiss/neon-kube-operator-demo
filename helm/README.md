# Creating the Sealed Secret

Create a Kubernetes cluster (check the _/cluster-setup_ folder) and configure
the Sealed Secrets controller before running the following commands inside this
folder:

```bash
kubectl create secret generic mysecret \
--dry-run=client \
--from-literal=username=$YOUR_USERNAME \
--from-literal=password=$YOUR_PASSWORD \
-o json > role.secret.json

kubeseal -f role.secret.json -w role.sealed-secret.yaml
```
