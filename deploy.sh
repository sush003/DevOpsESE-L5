#!/bin/bash

echo "🚀 Deploying IoT Sensor API with Auto-scaling..."

# Build Docker image
echo "📦 Building Docker image..."
docker build -t iot-sensor-api:latest .

# Apply Kubernetes manifests
echo "🔧 Applying Kubernetes manifests..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/iot-sensor-api

# Apply HPA (requires metrics-server)
echo "📊 Applying Horizontal Pod Autoscaler..."
kubectl apply -f hpa.yaml

# Show status
echo "✅ Deployment completed!"
echo ""
echo "📋 Current status:"
kubectl get pods -l app=iot-sensor-api
kubectl get svc iot-sensor-api-service
kubectl get hpa iot-sensor-api-hpa

echo ""
echo "🔗 To access the API, run:"
echo "kubectl port-forward service/iot-sensor-api-service 8080:80"
echo ""
echo "📊 To monitor auto-scaling:"
echo "kubectl get hpa iot-sensor-api-hpa -w"