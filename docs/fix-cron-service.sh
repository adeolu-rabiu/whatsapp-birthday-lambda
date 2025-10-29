#!/bin/bash

cd /opt/whatsapp-birthday-lambda

# Backup docker-compose.yml
cp docker-compose.yml docker-compose.yml.backup

# Update cron service to remove problematic health checks
python3 << 'PYTHON'
import yaml

with open('docker-compose.yml', 'r') as f:
    compose = yaml.safe_load(f)

# Update cron service
if 'cron' in compose['services']:
    cron = compose['services']['cron']
    
    # Remove health check if exists
    if 'healthcheck' in cron:
        del cron['healthcheck']
    
    # Simplify depends_on if exists
    if 'depends_on' in cron:
        # Make it a simple list without health conditions
        cron['depends_on'] = ['python-api', 'wppconnect-bot']
    
    print("✅ Updated cron service configuration")

with open('docker-compose.yml', 'w') as f:
    yaml.dump(compose, f, default_flow_style=False, sort_keys=False)

print("✅ docker-compose.yml updated")
PYTHON

echo "Cron service updated to remove health check dependencies"
