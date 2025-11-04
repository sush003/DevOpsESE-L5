#!/bin/bash

echo "📊 Monitoring Auto-scaling Behavior"
echo "=================================="

# Function to show current status
show_status() {
    echo "$(date): Current Status"
    echo "----------------------"
    echo "Pods:"
    kubectl get pods -l app=iot-sensor-api --no-headers | wc -l | xargs echo "  Count:"
    kubectl get pods -l app=iot-sensor-api -o wide
    echo ""
    echo "HPA Status:"
    kubectl get hpa iot-sensor-api-hpa
    echo ""
    echo "CPU Usage:"
    kubectl top pods -l app=iot-sensor-api 2>/dev/null || echo "  Metrics not available yet"
    echo "=================================="
    echo ""
}

# Show initial status
show_status

# Monitor in a loop
echo "Monitoring every 30 seconds (Press Ctrl+C to stop)..."
while true; do
    sleep 30
    show_status
done