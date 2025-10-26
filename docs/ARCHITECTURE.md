%%{init: {"theme":"base","themeVariables":{"fontSize":"18px","fontFamily":"Arial","primaryColor":"#e3f2fd","primaryTextColor":"#000","primaryBorderColor":"#1976d2","lineColor":"#424242","secondaryColor":"#fff3e0","tertiaryColor":"#f3e5f5"}}}%%

flowchart TB

%% USER LAYER
subgraph USERS["USER ACCESS"]
  Browser["🌐 Web Browser<br/>Chrome/Firefox/Safari"]
  Mobile["📱 Mobile Device<br/>WhatsApp"]
end

%% DOCKER LAYER - CORE SERVICES
subgraph DOCKER["🐳 DOCKER HOST — Network: birthday-network"]
  subgraph CORE["📦 CORE SERVICES (3)"]
    WebUI["Web UI<br/>React (Node/CRA)<br/>Port: 3000"]
    PythonAPI["Python API<br/>Flask + Boto3<br/>Port: 5000"]
    WPPConnect["wppconnect-bot<br/>Node.js + Puppeteer<br/>Port: 3005"]
  end

  subgraph MONITOR["📊 MONITORING STACK (4)"]
    ES["Elasticsearch<br/>Log Storage<br/>Port: 9200"]
    Kibana["Kibana<br/>Log Visualization<br/>Port: 5601"]
    Filebeat["Filebeat<br/>Log Collector<br/>No Port"]
    Metricbeat["Metricbeat<br/>Metrics Collector<br/>No Port"]
  end

  subgraph SUPPORT["🔧 SUPPORT SERVICES (2)"]
    Dashboard["Dashboard<br/>Flask + Vanilla JS<br/>Port: 8080"]
    Cron["Cron Service<br/>Python Script Runner<br/>No Port"]
  end
end

%% AWS LAYER
subgraph AWS["☁️ AWS CLOUD"]
  DynamoDB["DynamoDB<br/>Tables: Birthdays, WhatsAppGroups<br/>Region: eu-west-2"]
end

%% EXTERNAL
WhatsApp["📱 WhatsApp Network<br/>Message Delivery"]

%% CONNECTIONS
Browser -->|"HTTP"| WebUI
Browser -->|"HTTP"| Dashboard
Mobile <-->|"Messages"| WhatsApp

WebUI -->|"REST API"| PythonAPI
Dashboard -->|"REST API"| PythonAPI
PythonAPI -->|"REST API"| WPPConnect
WPPConnect <-->|"WebSocket/HTTPS"| WhatsApp

PythonAPI -->|"AWS SDK (boto3)"| DynamoDB
Cron -->|"Python Script"| PythonAPI

Filebeat -->|"Ship Logs"| ES
Metricbeat -->|"Ship Metrics"| ES
Kibana -->|"Query Data"| ES

Cron -.->|"Daily 8:00 AM<br/>Birthday Check"| PythonAPI
Cron -.->|"Trigger Messages"| WPPConnect

PythonAPI -.->|"Logs"| Filebeat
WPPConnect -.->|"Logs"| Filebeat
WebUI -.->|"Logs"| Filebeat
Dashboard -.->|"Logs"| Filebeat

%% Styling
classDef coreStyle fill:#e3f2fd,stroke:#1976d2,stroke-width:3px,color:#000
classDef monitorStyle fill:#fff3e0,stroke:#f57c00,stroke-width:3px,color:#000
classDef supportStyle fill:#f3e5f5,stroke:#7b1fa2,stroke-width:3px,color:#000
classDef awsStyle fill:#fff9c4,stroke:#f57f17,stroke-width:3px,color:#000
classDef externalStyle fill:#e8f5e9,stroke:#388e3c,stroke-width:3px,color:#000

class WebUI,PythonAPI,WPPConnect coreStyle
class ES,Kibana,Filebeat,Metricbeat monitorStyle
class Dashboard,Cron supportStyle
class DynamoDB awsStyle
class WhatsApp externalStyle

