#!/bin/bash

echo "🌡️ Adding ESXi Metrics to Dashboard"
echo "===================================="
echo ""

# Update the dashboard JSON to include ESXi temperature
cat > monitoring/grafana/dashboards/esxi-panel.json << 'JSON'
{
  "id": 20,
  "title": "ESXi Host Temperature",
  "type": "gauge",
  "gridPos": {"h": 4, "w": 6, "x": 0, "y": 23},
  "targets": [{
    "expr": "vmware_host_sensor_temperature_celsius",
    "refId": "A"
  }],
  "fieldConfig": {
    "defaults": {
      "unit": "celsius",
      "thresholds": {
        "steps": [
          {"color": "green", "value": 0},
          {"color": "yellow", "value": 60},
          {"color": "orange", "value": 75},
          {"color": "red", "value": 85}
        ]
      }
    }
  }
}
JSON

echo "✅ ESXi panel JSON created"
echo ""
echo "Dashboard panels to add:"
echo "  - ESXi CPU Usage: vmware_host_cpu_usage"
echo "  - ESXi Memory Usage: vmware_host_memory_usage"
echo "  - ESXi Temperature: vmware_host_sensor_temperature_celsius"
echo "  - ESXi Power State: vmware_host_power_state"
echo "  - ESXi Uptime: vmware_host_uptime_seconds"

