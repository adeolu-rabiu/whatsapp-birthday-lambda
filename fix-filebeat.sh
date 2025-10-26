#!/bin/bash

set -e

echo "🔧 Fixing filebeat..."
echo ""

# Create filebeat directory if it doesn't exist
mkdir -p filebeat

# 1. Create filebeat.yml configuration
echo "1️⃣ Creating filebeat/filebeat.yml..."
cat > filebeat/filebeat.yml << 'FILEBEATYML'
filebeat.inputs:
  # Collect logs from all containers
  - type: docker
    containers.ids:
      - '*'
    processors:
      - add_docker_metadata:
          host: "unix:///var/run/docker.sock"
      - decode_json_fields:
          fields: ["message"]
          target: ""
          overwrite_keys: true

  # Collect application logs
  - type: log
    enabled: true
    paths:
      - /logs/*.log
    fields:
      log_type: application
    multiline.pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
    multiline.negate: true
    multiline.match: after

# Output to Elasticsearch
output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  indices:
    - index: "filebeat-docker-%{+yyyy.MM.dd}"
      when.contains:
        container.name: "whatsapp-birthday"
    - index: "filebeat-app-%{+yyyy.MM.dd}"
      when.equals:
        fields.log_type: "application"

# Elasticsearch template
setup.template.name: "filebeat"
setup.template.pattern: "filebeat-*"
setup.template.enabled: true
setup.template.overwrite: true

# Kibana dashboard
setup.kibana:
  host: "kibana:5601"

# Logging
logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644

# Processors
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
FILEBEATYML
echo "✅ filebeat.yml created"
echo ""

# 2. Create Dockerfile
echo "2️⃣ Creating filebeat/Dockerfile..."
cat > filebeat/Dockerfile << 'DOCKERFILE'
FROM docker.elastic.co/beats/filebeat:8.12.2

USER root

# Copy Filebeat configuration
COPY filebeat.yml /usr/share/filebeat/filebeat.yml

# Set proper permissions
RUN chown root:filebeat /usr/share/filebeat/filebeat.yml && \
    chmod 0640 /usr/share/filebeat/filebeat.yml

USER filebeat
DOCKERFILE
echo "✅ Dockerfile created"
echo ""

# 3. Create .dockerignore
echo "3️⃣ Creating filebeat/.dockerignore..."
cat > filebeat/.dockerignore << 'DOCKERIGNORE'
*.log
.git
DOCKERIGNORE
echo "✅ .dockerignore created"
echo ""

echo "================================================"
echo "✅ Filebeat fixed!"
echo "================================================"
echo ""
echo "Files created:"
ls -la filebeat/
