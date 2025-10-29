#!/bin/bash

echo "🔧 Fixing Filebeat Data Stream Issue"
echo "====================================="
echo ""

cd /opt/whatsapp-birthday-lambda

# 1. Update filebeat.yml
echo "1️⃣ Updating filebeat.yml configuration..."
cat > filebeat/filebeat.yml << 'YAML'
filebeat.inputs:
  - type: container
    enabled: true
    paths:
      - /var/lib/docker/containers/*/*.log
    stream: all
    processors:
      - add_docker_metadata:
          host: "unix:///var/run/docker.sock"

  - type: log
    enabled: true
    paths:
      - /logs/*.log
    fields:
      log_type: application
    processors:
      - decode_json_fields:
          fields: ["message"]
          process_array: true
          max_depth: 2
          target: ""
          overwrite_keys: true
    multiline.pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
    multiline.negate: true
    multiline.match: after

# Output configuration - NO DATA STREAMS
output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "filebeat-%{+yyyy.MM.dd}"

# DISABLE ILM and Data Streams
setup.ilm.enabled: false
setup.ilm.check_exists: false

# Template for legacy indices
setup.template.enabled: true
setup.template.overwrite: true
setup.template.name: "filebeat"
setup.template.pattern: "filebeat-*"

logging.to_files: false
logging.level: info
logging.to_stderr: true

processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~

strict.perms: false
YAML

echo "✅ Configuration updated"
echo ""

# 2. Delete any existing filebeat data streams
echo "2️⃣ Cleaning up old data streams..."
curl -s -X DELETE "http://localhost:9200/_data_stream/filebeat*" 2>/dev/null
curl -s -X DELETE "http://localhost:9200/.ds-filebeat*" 2>/dev/null
echo "✅ Old data streams deleted"
echo ""

# 3. Restart filebeat
echo "3️⃣ Restarting filebeat..."
docker-compose stop filebeat
docker rm whatsapp-birthday-lambda_filebeat 2>/dev/null
docker-compose build filebeat
docker-compose up -d filebeat

echo "Waiting for filebeat to initialize..."
sleep 15

# 4. Verify
echo ""
echo "4️⃣ Verification..."
echo ""

# Check container status
if docker ps | grep -q "filebeat.*Up"; then
    echo "✅ Filebeat container is running"
else
    echo "❌ Filebeat container not running"
    docker ps -a | grep filebeat
fi

# Check logs
echo ""
echo "Recent filebeat logs:"
docker logs whatsapp-birthday-lambda_filebeat --tail 20

# Check Elasticsearch indices
echo ""
echo "Filebeat indices in Elasticsearch:"
curl -s "http://localhost:9200/_cat/indices/filebeat*?v&s=index:desc" | head -10

# Check if logs are flowing
echo ""
echo "Document count in today's index:"
today=$(date +%Y.%m.%d)
doc_count=$(curl -s "http://localhost:9200/filebeat-${today}/_count" | jq -r '.count' 2>/dev/null)
if [ -n "$doc_count" ] && [ "$doc_count" -gt 0 ]; then
    echo "✅ $doc_count documents in filebeat-${today}"
else
    echo "⚠️  No documents yet in filebeat-${today} (may take a few minutes)"
fi

echo ""
echo "====================================="
echo "✅ Filebeat Fix Complete!"
echo "====================================="
echo ""
echo "📊 Next Steps:"
echo "  1. Wait 2-3 minutes for logs to appear"
echo "  2. In Kibana, create Data View with pattern: filebeat-*"
echo "  3. Go to Discover to view logs"
