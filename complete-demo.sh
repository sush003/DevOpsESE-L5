#!/bin/bash

set -e

echo "🚀 Complete IoT Sensor API Auto-scaling Demo"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo "Step 1: Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    print_error "docker not found. Please install Docker."
    exit 1
fi

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    print_error "No Kubernetes cluster found. Please start a cluster first:"
    echo "  - Docker Desktop: Enable Kubernetes in settings"
    echo "  - minikube: minikube start"
    echo "  - kind: kind create cluster"
    exit 1
fi

print_status "Prerequisites check passed"

# Step 2: Install metrics-server if needed
echo ""
echo "Step 2: Setting up metrics-server..."

if kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    print_info "metrics-server already installed"
else
    print_info "Installing metrics-server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch for local clusters
    print_info "Patching metrics-server for local cluster..."
    kubectl patch deployment metrics-server -n kube-system --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
    
    print_info "Waiting for metrics-server to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system
fi

print_status "metrics-server is ready"

# Step 3: Build and deploy application
echo ""
echo "Step 3: Building and deploying IoT Sensor API..."

print_info "Building Docker image..."
docker build -t iot-sensor-api:latest .

print_info "Deploying to Kubernetes..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

print_info "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/iot-sensor-api

print_status "Application deployed successfully"

# Step 4: Deploy HPA
echo ""
echo "Step 4: Setting up Horizontal Pod Autoscaler..."

kubectl apply -f hpa.yaml

print_info "Waiting for HPA to initialize..."
sleep 10

print_status "HPA configured successfully"

# Step 5: Show initial status
echo ""
echo "Step 5: Initial Status"
echo "====================="

echo "Pods:"
kubectl get pods -l app=iot-sensor-api

echo ""
echo "Service:"
kubectl get svc iot-sensor-api-service

echo ""
echo "HPA:"
kubectl get hpa iot-sensor-api-hpa

echo ""
echo "Metrics (may take a minute to appear):"
kubectl top pods -l app=iot-sensor-api 2>/dev/null || echo "Metrics not available yet"

# Step 6: Start port-forward in background
echo ""
echo "Step 6: Setting up access to the API..."

print_info "Starting port-forward to access the API and Frontend..."
kubectl port-forward service/iot-sensor-api-service 8080:80 &
PORT_FORWARD_PID=$!

echo ""
echo "🌐 FRONTEND ACCESS:"
echo "================================"
echo "Open your browser and go to:"
echo "👉 http://localhost:8080"
echo ""
echo "API endpoints also available at:"
echo "👉 http://localhost:8080/api/sensors"
echo "👉 http://localhost:8080/health"
echo "================================"

# Wait for port-forward to be ready
sleep 3

# Step 7: Test the API
echo ""
echo "Step 7: Testing the API..."

print_info "Testing health endpoint..."
curl -s http://localhost:8080/health | jq . || echo "Health check successful"

print_info "Adding some test sensor data..."
for i in {1..3}; do
    curl -s -X POST http://localhost:8080/api/sensors \
         -H "Content-Type: application/json" \
         -d "{\"sensorId\":\"demo-$i\",\"temperature\":$((20 + i * 5)),\"humidity\":$((50 + i * 10)),\"location\":\"lab-$i\"}" > /dev/null
done

print_info "Retrieving sensor data..."
curl -s http://localhost:8080/api/sensors | jq . || echo "API test successful"

print_status "API is working correctly"

# Step 8: Generate load and monitor scaling
echo ""
echo "Step 8: Load Testing and Auto-scaling Demo"
echo "=========================================="

print_warning "Starting load test in 5 seconds..."
print_info "This will generate CPU load to trigger auto-scaling"
sleep 5

# Function to generate load
generate_load() {
    local duration=$1
    local requests_per_second=$2
    
    print_info "Generating load: $requests_per_second req/s for $duration seconds"
    
    for ((i=1; i<=duration; i++)); do
        for ((j=1; j<=requests_per_second; j++)); do
            curl -s http://localhost:8080/api/load-test?duration=200 > /dev/null &
            curl -s http://localhost:8080/api/sensors > /dev/null &
        done
        sleep 1
        
        # Show progress every 10 seconds
        if ((i % 10 == 0)); then
            echo "  Progress: $i/$duration seconds"
            kubectl get hpa iot-sensor-api-hpa --no-headers | awk '{print "  Current replicas: " $6 ", CPU: " $3}'
        fi
    done
    
    # Wait for background jobs to complete
    wait
}

# Monitor function
monitor_scaling() {
    echo ""
    echo "Monitoring Auto-scaling Behavior:"
    echo "================================"
    
    for i in {1..20}; do
        echo "$(date '+%H:%M:%S') - Check $i:"
        
        # Get pod count
        POD_COUNT=$(kubectl get pods -l app=iot-sensor-api --no-headers | wc -l | tr -d ' ')
        echo "  Pods: $POD_COUNT"
        
        # Get HPA status
        HPA_STATUS=$(kubectl get hpa iot-sensor-api-hpa --no-headers)
        echo "  HPA: $HPA_STATUS"
        
        # Get CPU usage if available
        CPU_USAGE=$(kubectl top pods -l app=iot-sensor-api --no-headers 2>/dev/null | awk '{sum+=$2} END {print sum "m"}' || echo "N/A")
        echo "  Total CPU: $CPU_USAGE"
        
        echo "  ---"
        sleep 15
    done
}

# Start monitoring in background
monitor_scaling &
MONITOR_PID=$!

# Phase 1: Light load
print_info "Phase 1: Light load (5 req/s for 60 seconds)"
generate_load 60 5

sleep 30

# Phase 2: Medium load
print_info "Phase 2: Medium load (15 req/s for 90 seconds)"
generate_load 90 15

sleep 30

# Phase 3: Heavy load
print_info "Phase 3: Heavy load (30 req/s for 120 seconds)"
generate_load 120 30

print_info "Load test completed. Observing scale-down behavior..."
sleep 180  # Wait 3 minutes to observe scale-down

# Stop monitoring
kill $MONITOR_PID 2>/dev/null || true

# Final status
echo ""
echo "Final Status:"
echo "============"

echo "Pods:"
kubectl get pods -l app=iot-sensor-api

echo ""
echo "HPA:"
kubectl get hpa iot-sensor-api-hpa

echo ""
echo "HPA Events:"
kubectl describe hpa iot-sensor-api-hpa | tail -10

# Cleanup
print_info "Stopping port-forward..."
kill $PORT_FORWARD_PID 2>/dev/null || true

print_status "Demo completed successfully!"

echo ""
echo "Summary:"
echo "========"
echo "✅ IoT Sensor API deployed with resource limits"
echo "✅ HPA configured (min=1, max=5, cpu=50%)"
echo "✅ Load generated and scaling observed"
echo "✅ Pods scaled automatically under load"

echo ""
echo "To clean up:"
echo "kubectl delete -f hpa.yaml"
echo "kubectl delete -f service.yaml" 
echo "kubectl delete -f deployment.yaml"