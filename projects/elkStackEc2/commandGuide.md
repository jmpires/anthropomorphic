# Production environment
./deployNodes.sh node-0 ./k8ControlPlane.sh
./deployNodes.sh node-1 ./k8WorkerNode.sh
./joinWorkers.sh

# miniKube
minikube start --cpus 4 --memory 8192
kubectl cluster-info
kubectl cluster-info dump

minikube service es-service
minikube ip

# Elasticsearch

## Deploying Elasticsearch
kubectl apply -f es-deployment.yaml
kubectl get deployments
kubectl get pods                                    # aprox. 3 min.
kubectl describe deployment es-logging
kubectl describe pod <elastic_pod_name>
kubectl logs -f deployments/es-logging

## Exposing Elasticsearch
kubectl apply -f es-svc.yaml
kubectl get svc

minikube service es-service
minikube ip

http://192.168.49.2:31041/_cluster/health           # the URL and port should came from the minikube service es-service result


## Deploying Kibana
kubectl apply -f kibana-deployment.yaml
kubectl get deployment kibana-logging
kubectl get pods                                    # aprox. 3 min.
kubectl logs <kibana_pod_name>

minikube ip

kubectl set env deployment/kibana-logging ELASTICSEARCH_HOSTS=<URL_from minikube service es-service result> 
kubectl set env deployment/kibana-logging ELASTICSEARCH_HOSTS=http://192.168.49.2:31041

kubectl get pods
kubectl logs -f pod/<kibana_pod_name> | grep -i running

## Exposing Kibana
kubectl apply -f kibana-svc.yaml
kubectl get svc

minikube service kibana-service






