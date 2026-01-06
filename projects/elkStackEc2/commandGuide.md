# Elasticsearch

## Deploying Elasticsearch
kubectl create -f es-deployment.yaml
kubectl get deployments
kubectl get pods            # aprox. 4 min.
kubectl describe deployment es-logging
kubectl describe pod <pod_name>
kubectl logs -f deployments/es-logging

## Exposing Elasticsearch

