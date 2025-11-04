#!/bin/bash

# Load testing script for IoT Sensor API
# This script generates load to trigger auto-scaling

echo "Starting load test for IoT Sensor API..."
echo "This will generate traffic to trigger auto-scaling"

# Get the service URL (assuming port-forward is running)
SERVICE_URL="http://localhost:8080"

# Function to make requests
make_requests() {
    local duration=$1
    local concurrent=$2
    echo "Making $concurrent concurrent requests for $duration seconds..."
    
    for i in $(seq 1 $concurrent); do
        {
            while true; do
                # Mix of different endpoints to simulate real traffic
                curl -s "$SERVICE_URL/api/sensors" > /dev/null &
                curl -s "$SERVICE_URL/api/load-test?duration=500" > /dev/null &
                curl -s -X POST "$SERVICE_URL/api/sensors" \
                     -H "Content-Type: application/json" \
                     -d '{"sensorId":"load-test-'$i'","temperature":25,"humidity":60}' > /dev/null &
                sleep 0.1
            done
        } &
    done
    
    # Let it run for specified duration
    sleep $duration
    
    # Kill all background jobs
    jobs -p | xargs kill 2>/dev/null
    wait 2>/dev/null
}

echo "Phase 1: Light load (10 concurrent requests for 60 seconds)"
make_requests 60 10

echo "Waiting 30 seconds..."
sleep 30

echo "Phase 2: Medium load (25 concurrent requests for 120 seconds)"
make_requests 120 25

echo "Waiting 30 seconds..."
sleep 30

echo "Phase 3: Heavy load (50 concurrent requests for 180 seconds)"
make_requests 180 50

echo "Load test completed!"
echo "Check the HPA status with: kubectl get hpa iot-sensor-api-hpa -w"