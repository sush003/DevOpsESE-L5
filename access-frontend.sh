#!/bin/bash

echo "🌐 IoT Sensor Dashboard Access"
echo "=============================="

# Check if running locally
if docker ps --format "table {{.Names}}" | grep -q "iot-frontend-test"; then
    echo "✅ Found local Docker container running"
    echo "👉 Frontend URL: http://localhost:3000"
    echo ""
    echo "To stop local container: docker stop iot-frontend-test"
    exit 0
fi

# Check if Kubernetes deployment exists
if kubectl get deployment iot-sensor-api &> /dev/null; then
    echo "✅ Found Kubernetes deployment"
    
    # Check if port-forward is already running
    if lsof -i :8080 &> /dev/null; then
        echo "✅ Port-forward already running on port 8080"
    else
        echo "🔗 Starting port-forward..."
        kubectl port-forward service/iot-sensor-api-service 8080:80 &
        sleep 2
    fi
    
    echo "👉 Frontend URL: http://localhost:8080"
    echo "👉 API URL: http://localhost:8080/api/sensors"
    echo "👉 Health Check: http://localhost:8080/health"
    echo ""
    echo "To stop port-forward: pkill -f 'kubectl port-forward'"
    
elif docker images | grep -q "iot-sensor-api"; then
    echo "🐳 Docker image found but not running"
    echo "Starting local container..."
    docker run -d -p 3000:3000 --name iot-frontend-test iot-sensor-api:latest
    sleep 3
    echo "👉 Frontend URL: http://localhost:3000"
    
else
    echo "❌ No deployment found"
    echo ""
    echo "To run locally:"
    echo "  docker run -d -p 3000:3000 --name iot-frontend-test iot-sensor-api:latest"
    echo ""
    echo "To deploy to Kubernetes:"
    echo "  ./complete-demo.sh"
fi

echo ""
echo "📱 What you'll see in the frontend:"
echo "  • Real-time sensor dashboard"
echo "  • Add sensor readings"
echo "  • Generate load tests"
echo "  • Monitor auto-scaling"
echo "  • System health status"