const express = require("express");
const path = require("path");
const app = express();
const port = 3000;

// Middleware to parse JSON
app.use(express.json());

// Serve static files from public directory
app.use(express.static(path.join(__dirname, "public")));

// In-memory storage for sensor data
let sensorData = [];

// Serve dashboard at root
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// Health check endpoint
app.get("/health", (req, res) => {
  res
    .status(200)
    .json({ status: "healthy", timestamp: new Date().toISOString() });
});

// Get all sensor readings
app.get("/api/sensors", (req, res) => {
  // Simulate CPU load for testing autoscaling
  const start = Date.now();
  while (Date.now() - start < 100) {
    // CPU intensive operation
    Math.random() * Math.random();
  }

  res.json({
    sensors: sensorData,
    count: sensorData.length,
    timestamp: new Date().toISOString(),
  });
});

// Add new sensor reading
app.post("/api/sensors", (req, res) => {
  const { sensorId, temperature, humidity, location } = req.body;

  const reading = {
    id: Date.now(),
    sensorId: sensorId || `sensor-${Math.floor(Math.random() * 1000)}`,
    temperature: temperature || Math.floor(Math.random() * 40) + 10,
    humidity: humidity || Math.floor(Math.random() * 100),
    location: location || "unknown",
    timestamp: new Date().toISOString(),
  };

  sensorData.push(reading);

  // Keep only last 100 readings
  if (sensorData.length > 100) {
    sensorData = sensorData.slice(-100);
  }

  res.status(201).json(reading);
});

// Get sensor by ID
app.get("/api/sensors/:id", (req, res) => {
  const sensor = sensorData.find((s) => s.sensorId === req.params.id);
  if (!sensor) {
    return res.status(404).json({ error: "Sensor not found" });
  }
  res.json(sensor);
});

// Load testing endpoint (CPU intensive)
app.get("/api/load-test", (req, res) => {
  const duration = parseInt(req.query.duration) || 1000;
  const start = Date.now();

  while (Date.now() - start < duration) {
    Math.random() * Math.random() * Math.random();
  }

  res.json({
    message: "Load test completed",
    duration: `${duration}ms`,
    timestamp: new Date().toISOString(),
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`IoT Sensor API running on port ${port}`);
  console.log(`Health check: http://localhost:${port}/health`);
  console.log(`API endpoints: http://localhost:${port}/api/sensors`);
});
