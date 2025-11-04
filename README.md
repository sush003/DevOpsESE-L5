# IoT Sensor API - Kubernetes Auto-scaling Demo

This project demonstrates Kubernetes Horizontal Pod Autoscaler (HPA) with an IoT Sensor API application.

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud cluster)
- kubectl configured
- Docker
- metrics-server installed in cluster

### Install metrics-server (if not already installed):

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

For local clusters (minikube/kind), you might need to patch metrics-server:

```bash
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

## Quick Start

### 1. Deploy the Application

```bash
./deploy.sh
```

### 2. Access the API

```bash
# Port forward to access the service
kubectl port-forward service/iot-sensor-api-service 8080:80
```

### 3. Test the API

```bash
# Health check
curl http://localhost:8080/health

# Get sensors
curl http://localhost:8080/api/sensors

# Add sensor data
curl -X POST http://localhost:8080/api/sensors \
  -H "Content-Type: application/json" \
  -d '{"sensorId":"test-001","temperature":25,"humidity":60,"location":"lab"}'
```

### 4. Generate Load and Observe Scaling

```bash
# In terminal 1: Monitor scaling
./monitor.sh

# In terminal 2: Generate load
./load-test.sh
```

## Manual Commands

### Deploy Components

```bash
# Build image
docker build -t iot-sensor-api:latest .

# Deploy application
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
```

### Monitor Auto-scaling

```bash
# Watch HPA
kubectl get hpa iot-sensor-api-hpa -w

# Check pods
kubectl get pods -l app=iot-sensor-api -w

# View CPU usage
kubectl top pods -l app=iot-sensor-api
```

### Generate Load Manually

```bash
# Simple load test
for i in {1..100}; do
  curl -s http://localhost:8080/api/load-test?duration=1000 &
done
```

## Expected Behavior

1. **Initial State**: 1 pod running
2. **Under Load**: CPU usage increases above 50%
3. **Scale Up**: HPA creates additional pods (up to 5)
4. **Load Stops**: After 5 minutes, pods scale down to minimum (1)

## Configuration

- **Min Replicas**: 1
- **Max Replicas**: 5
- **CPU Target**: 50%
- **Resource Limits**: 500m CPU, 256Mi memory
- **Resource Requests**: 100m CPU, 128Mi memory

## Troubleshooting

### HPA shows "unknown" for CPU

```bash
# Check metrics-server
kubectl get pods -n kube-system | grep metrics-server

# Check if metrics are available
kubectl top nodes
kubectl top pods
```

### Pods not scaling

```bash
# Check HPA events
kubectl describe hpa iot-sensor-api-hpa

# Check deployment events
kubectl describe deployment iot-sensor-api
```

## Cleanup

```bash
kubectl delete -f hpa.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
docker rmi iot-sensor-api:latest
```
