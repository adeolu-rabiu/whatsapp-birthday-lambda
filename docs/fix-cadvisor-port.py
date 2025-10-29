import yaml

with open('docker-compose.yml', 'r') as f:
    compose = yaml.safe_load(f)

# Change cadvisor port from 8080 to 8081
compose['services']['cadvisor']['ports'] = ['8081:8080']

with open('docker-compose.yml', 'w') as f:
    yaml.dump(compose, f, default_flow_style=False, sort_keys=False)

print("✅ Changed cadvisor port from 8080 to 8081")
