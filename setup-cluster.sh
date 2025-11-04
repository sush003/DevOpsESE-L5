#!/bin/bash

echo "🔧 Kubernetes Cluster Setup for Auto-scaling Demo"
echo "================================================="

# Check what's available
if command -v minikube &> /dev/null; then
    echo "Option 1: Using minikube"
    echo "Starting minikube cluster..."
    minikube start --cpus=2 --memory=4096
    echo "✅ Minikube cluster started"
    
elif command -v kind &> /dev/null; then
    echo "Option 2: Using kind"
    echo "Creating kind cluster..."
    kind create cluster --name autoscale-demo
    echo "✅ Kind cluster created"
    
else
    echo "❌ No local Kubernetes found."
    echo ""
    echo "Please install one of the following:"
    echo "1. Docker Desktop (enable Kubernetes in settings)"
    echo "2. minikube: brew install minikube"
    echo "3. kind: brew install kind"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Verify cluster
echo ""
echo "Verifying cluster..."
kubectl cluster-info
kubectl get nodes

echo ""
echo "✅ Cluster is ready!"
echo "Now run: ./complete-demo.sh"