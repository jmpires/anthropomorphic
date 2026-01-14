# Production environment
./deployNodes.sh node-0 ./k8ControlPlane.sh
./deployNodes.sh node-1 ./k8WorkerNode.sh
./joinWorkers.sh

# miniKube
minikube start --cpus 4 --memory 8192
kubectl cluster-info
kubectl cluster-info dump

minikube ip

