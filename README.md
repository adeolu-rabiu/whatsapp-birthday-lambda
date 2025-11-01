# 🎂 WhatsApp Birthday Bot - Enterprise Edition

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue)](https://docs.docker.com/compose/)
[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://www.python.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18-green)](https://nodejs.org/)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-orange)](https://prometheus.io/)

> **Automated WhatsApp birthday reminder system with enterprise-grade monitoring, observability, and disaster recovery capabilities.**

Never forget a birthday again! This fully automated system sends personalized WhatsApp messages to designated groups on birthdays, with complete monitoring, logging, and backup infrastructure.

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Data Flow](#-data-flow)
- [Technology Stack](#-technology-stack)
- [System Components](#-system-components)
- [Monitoring & Observability](#-monitoring--observability)
- [Service Manager](#-service-manager)
- [Backup & Disaster Recovery](#-backup--disaster-recovery)
- [API Documentation](#-api-documentation)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)

---

## ✨ Features

### Core Functionality
- 🎂 **Automated Birthday Reminders** - Daily checks at 8:00 AM
- 📱 **WhatsApp Integration** - Send messages via wppconnect
- 🌐 **Web Dashboard** - React-based UI for management
- 🔄 **RESTful API** - Complete CRUD operations
- 📊 **Multiple Group Support** - Different messages per group
- 🎨 **Fun Facts** - Random fun facts when no birthdays

### Enterprise Features
- 📈 **Complete Monitoring Stack** - Prometheus + Grafana (7 services)
- 🚨 **Alerting System** - Real-time alerts via Slack
- 💾 **Automated Backups** - Daily backups with 90-day retention
- 🔄 **Disaster Recovery** - Complete system restore capability
- 📊 **Observability** - Metrics, logs, and traces
- 🎯 **Health Checks** - Automated service monitoring
- 🐳 **Container Orchestration** - Docker Compose with 12 services
- 🔐 **Security** - Environment-based secrets management

---

## 🏗️ Architecture

### System Architecture
```mermaid
graph TB
    subgraph "USER ACCESS LAYER"
        Browser["🌐 WEB BROWSER<br/>Chrome/Firefox/Safari"]
        Mobile["📱 MOBILE DEVICE<br/>WhatsApp"]
    end

    subgraph "DOCKER HOST - Ubuntu 24 VM on ESXi"
        
        subgraph "MONITORING & OBSERVABILITY (7)"
            Grafana["📊 GRAFANA<br/>Port: 3001<br/>Visualization<br/>Dashboards"]
            Prometheus["📈 PROMETHEUS<br/>Port: 9090<br/>Time-series DB<br/>Metrics Storage"]
            Alertmanager["🚨 ALERTMANAGER<br/>Port: 9093<br/>Alert Router<br/>Slack Notifications"]
            NodeExporter["💻 NODE EXPORTER<br/>Port: 9100<br/>CPU/RAM/Disk"]
            cAdvisor["🐳 CADVISOR<br/>Port: 8081<br/>Container Metrics"]
            Blackbox["🔍 BLACKBOX<br/>Port: 9115<br/>Health Probes"]
            VMware["🌡️ VMWARE EXPORTER<br/>Port: 9272<br/>ESXi Temp"]
        end
        
        subgraph "CORE APPLICATION (3)"
            Cron["⏰ CRON SERVICE<br/>Python Runner<br/>Daily 8:00 AM<br/>Birthday Checker"]
            PythonAPI["💼 PYTHON API<br/>Flask + Boto3<br/>Port: 5000<br/>Business Logic<br/>/metrics endpoint"]
            WPPConnect["💬 WPPCONNECT-BOT<br/>Node.js + Puppeteer<br/>Port: 3005<br/>WhatsApp Gateway<br/>WebSocket/HTTPS"]
        end
        
        subgraph "SUPPORTING SERVICES (2)"
            Dashboard["📊 DASHBOARD<br/>Flask + JS<br/>Port: 8080<br/>System Overview"]
            WebUI["📱 WEB UI<br/>React (CRA)<br/>Port: 3000<br/>Birthday Management"]
        end
    end

    subgraph "AWS CLOUD"
        DynamoDB["☁️ DYNAMODB<br/>Tables:<br/>• Birthdays<br/>• WhatsAppGroups<br/>Region: eu-west-2"]
    end

    subgraph "EXTERNAL INFRASTRUCTURE"
        ESXi["🖥️ ESXI HOST<br/>VM Hypervisor<br/>Temperature Sensors<br/>Resource Pool"]
        WhatsAppNet["📱 WHATSAPP NETWORK<br/>Message Delivery<br/>Group Messages"]
    end

    Browser -->|HTTP/HTTPS| WebUI
    Browser -->|HTTP/HTTPS| Dashboard
    Browser -->|HTTP/HTTPS| Grafana
    Mobile <-->|Messages| WhatsAppNet

    WebUI -->|REST API| PythonAPI
    Dashboard -->|REST API| PythonAPI

    Cron -->|Trigger 8AM| PythonAPI
    PythonAPI -->|AWS SDK| DynamoDB
    PythonAPI -->|REST API| WPPConnect
    WPPConnect <-->|WebSocket| WhatsAppNet

    Grafana -->|Query| Prometheus
    Prometheus -->|Scrape| PythonAPI
    Prometheus -->|Scrape| NodeExporter
    Prometheus -->|Scrape| cAdvisor
    Prometheus -->|Scrape| VMware
    Prometheus -->|Scrape| Blackbox
    Prometheus -->|Alerts| Alertmanager
    
    Blackbox -->|Probe| PythonAPI
    Blackbox -->|Probe| WPPConnect
    
    VMware -->|vSphere API| ESXi
    NodeExporter -.->|System Calls| ESXi

    classDef monitoring fill:#ff6b6b,stroke:#c92a2a,stroke-width:3px,color:#fff
    classDef core fill:#4a90e2,stroke:#2e5c8a,stroke-width:3px,color:#fff
    classDef support fill:#7b68ee,stroke:#5a4fcf,stroke-width:3px,color:#fff
    classDef external fill:#ffa500,stroke:#cc8400,stroke-width:3px,color:#000
    classDef aws fill:#ff9900,stroke:#cc7a00,stroke-width:3px,color:#000
    classDef user fill:#2ecc71,stroke:#27ae60,stroke-width:3px,color:#fff

    class Grafana,Prometheus,Alertmanager,NodeExporter,cAdvisor,Blackbox,VMware monitoring
    class Cron,PythonAPI,WPPConnect core
    class Dashboard,WebUI support
    class DynamoDB aws
    class ESXi,WhatsAppNet external
    class Browser,Mobile user
```

### Architecture Summary

**12 Services Total:**
- 🔴 **Monitoring & Observability:** 7 services
- 🔵 **Core Application:** 3 services  
- 🟣 **Supporting Services:** 2 services

**External Dependencies:**
- 🟠 **AWS DynamoDB** - Data storage
- 🟠 **ESXi Host** - VM infrastructure
- 🟠 **WhatsApp Network** - Message delivery

---

## 🔄 Data Flow

### Daily Birthday Check Process
```mermaid
flowchart TD
    Start([⏰ 08:00 Daily Cron<br/>whatsapp_birthday_service.py]) --> CallAPI[📞 Call Python API<br/>/birthday/check]
    
    CallAPI --> FetchConfig[📋 Fetch config and groups]
    FetchConfig --> ComputeDate[📅 Compute today's MM-DD]
    ComputeDate --> QueryDB[(🗄️ AWS RDS: Birthdays<br/>Query: date = today)]
    
    QueryDB --> CheckMatch{❓ Any matches?}
    
    CheckMatch -->|YES| MatchGroup[�� Matches per group]
    MatchGroup --> RenderBDay[🎂 Render birthday message]
    RenderBDay --> SendBDay[📤 wppconnect.send-message<br/>Birthday message]
    SendBDay --> DeliverBDay[📱 WhatsApp groups]
    DeliverBDay --> LogSuccess1[✅ Log success]
    
    CheckMatch -->|NO| PickFact[🎲 Pick fun fact message]
    PickFact --> SendFact[📤 wppconnect.send-message<br/>Fun fact]
    SendFact --> DeliverFact[📱 WhatsApp groups]
    DeliverFact --> LogSuccess2[✅ Log success]
    
    LogSuccess1 --> CheckError{❌ Error?}
    LogSuccess2 --> CheckError
    
    CheckError -->|YES| RetryBackoff[⏳ Retry with backoff<br/>write error log]
    CheckError -->|NO| UpdateMetrics[📊 Update Prometheus metrics]
    RetryBackoff --> LogKibana[(📊 Elasticsearch Kibana)]
    UpdateMetrics --> Done([✅ Done<br/>Wait for next day])
    LogKibana --> Done

    style Start fill:#4a90e2,stroke:#2e5c8a,stroke-width:3px,color:#fff
    style QueryDB fill:#ff9900,stroke:#cc7a00,stroke-width:2px,color:#fff
    style CheckMatch fill:#17a2b8,stroke:#117a8b,stroke-width:2px,color:#fff
    style DeliverBDay fill:#28a745,stroke:#1e7e34,stroke-width:2px,color:#fff
    style DeliverFact fill:#28a745,stroke:#1e7e34,stroke-width:2px,color:#fff
    style CheckError fill:#ffc107,stroke:#d39e00,stroke-width:2px,color:#000
    style RetryBackoff fill:#dc3545,stroke:#bd2130,stroke-width:2px,color:#fff
    style Done fill:#28a745,stroke:#1e7e34,stroke-width:3px,color:#fff
```

### Message Delivery Sequence
```mermaid
sequenceDiagram
    participant Cron as ⏰ Cron Service
    participant API as 💼 Python API
    participant DB as 🗄️ DynamoDB
    participant WPP as �� wppconnect-bot
    participant WA as 📱 WhatsApp Network
    participant Prom as 📈 Prometheus

    Note over Cron,Prom: Daily 8:00 AM Trigger
    
    Cron->>API: Trigger birthday check
    activate API
    
    API->>DB: Query birthdays (today's date)
    activate DB
    DB-->>API: Return matching birthdays
    deactivate DB
    
    alt Birthdays Found
        API->>API: Render personalized messages
        loop For each birthday
            API->>WPP: Send birthday message to group
            activate WPP
            WPP->>WA: Deliver via WebSocket
            activate WA
            WA-->>WPP: Delivery confirmation
            deactivate WA
            WPP-->>API: Success response
            deactivate WPP
            API->>Prom: Record success metric
        end
    else No Birthdays
        API->>API: Pick random fun fact
        API->>WPP: Send fun fact to all groups
        activate WPP
        WPP->>WA: Deliver to groups
        activate WA
        WA-->>WPP: Delivery confirmation
        deactivate WA
        WPP-->>API: Success response
        deactivate WPP
        API->>Prom: Record metric
    end
    
    API->>Prom: Update final metrics
    API-->>Cron: Completion status
    deactivate API
    
    Note over Cron,Prom: Wait for next day
```

---

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/adeolu-rabiu/whatsapp-birthday-lambda.git
cd whatsapp-birthday-lambda
```

### 2. Configure Environment
```bash
# Copy example environment file
cp .env.example .env

# Edit with your credentials
nano .env
```

Required variables:
```env
# AWS Configuration
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_REGION=eu-west-2
DYNAMODB_TABLE_NAME=Birthdays
WHATSAPP_GROUPS_TABLE=WhatsAppGroups

# API Configuration
AUTH_TOKEN=your_secure_token

# Monitoring
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASS=agzo

# ESXi Monitoring (Optional)
VSPHERE_HOST=192.168.1.2
VSPHERE_USER=root
VSPHERE_PASSWORD=your_esxi_password
```

### 3. Start Services
```bash
# Using Service Manager (Recommended)
chmod +x service_manager.v6
./service_manager.v6
# Choose option 1: Start All Services

# Or using Docker Compose directly
docker-compose up -d
```

### 4. Connect WhatsApp
```bash
# Via Service Manager
./service_manager.v6
# Choose option 6: Manage WhatsApp Connection
# Choose option 4: Show QR Code

# Direct URL
# Visit: http://192.168.1.66:3005/qr-code.png
# Scan with WhatsApp: Settings → Linked Devices → Link a Device
```

### 5. Access Applications

| Service | URL | Credentials |
|---------|-----|-------------|
| 🌐 Web UI | http://192.168.1.66:3000 | - |
| 📊 Dashboard | http://192.168.1.66:8080 | - |
| 💼 API | http://192.168.1.66:5000 | - |
| 📈 Grafana | http://192.168.1.66:3001 | admin / agzo |
| 🔍 Prometheus | http://192.168.1.66:9090 | - |
| 💬 WhatsApp Bot | http://192.168.1.66:3005 | - |

---

## 💻 Technology Stack
```mermaid
mindmap
  root((WhatsApp<br/>Birthday Bot))
    Backend
      Python 3.11
      Flask Framework
      Boto3 AWS SDK
      APScheduler
    Frontend
      React 18
      Create React App
      Axios
      Modern UI
    WhatsApp
      wppconnect
      Puppeteer
      Node.js 18
      WebSocket
    Infrastructure
      Docker
      Docker Compose
      Ubuntu 24.04
      VMware ESXi
    Monitoring
      Prometheus 2.55
      Grafana 11.2
      Alertmanager 0.27
      cAdvisor 0.49
      Node Exporter 1.8
    Data
      AWS DynamoDB
      Local Backups
      GitHub Artifacts
    DevOps
      GitHub Actions
      Git Version Control
      Automated Testing
```

### Component Versions

| Component | Version | Purpose |
|-----------|---------|---------|
| Python | 3.11 | Backend API & Logic |
| Node.js | 18 | WhatsApp Bot |
| React | 18 | Frontend UI |
| Flask | 2.3+ | Web Framework |
| Prometheus | 2.55 | Metrics Collection |
| Grafana | 11.2 | Visualization |
| Docker | 24+ | Containerization |
| Ubuntu | 24.04 | Host OS |

---

## 🎯 System Components

### Service Overview
```mermaid
graph LR
    subgraph "Core Services"
        A1[Python API<br/>:5000]
        A2[wppconnect-bot<br/>:3005]
        A3[Cron Service<br/>8AM Daily]
    end
    
    subgraph "Supporting"
        B1[Web UI<br/>:3000]
        B2[Dashboard<br/>:8080]
    end
    
    subgraph "Monitoring"
        C1[Prometheus<br/>:9090]
        C2[Grafana<br/>:3001]
        C3[Alertmanager<br/>:9093]
        C4[Node Exporter<br/>:9100]
        C5[cAdvisor<br/>:8081]
        C6[Blackbox<br/>:9115]
        C7[VMware<br/>:9272]
    end

    B1 --> A1
    B2 --> A1
    A3 --> A1
    A1 --> A2
    
    C1 --> A1
    C1 --> C4
    C1 --> C5
    C1 --> C6
    C1 --> C7
    C2 --> C1
    C3 --> C1

    classDef core fill:#4a90e2,stroke:#2e5c8a,stroke-width:2px,color:#fff
    classDef support fill:#7b68ee,stroke:#5a4fcf,stroke-width:2px,color:#fff
    classDef monitor fill:#ff6b6b,stroke:#c92a2a,stroke-width:2px,color:#fff

    class A1,A2,A3 core
    class B1,B2 support
    class C1,C2,C3,C4,C5,C6,C7 monitor
```

### Port Allocation
```mermaid
graph TD
    subgraph "Application Ports"
        P3000[":3000<br/>Web UI"]
        P5000[":5000<br/>Python API"]
        P3005[":3005<br/>wppconnect"]
        P8080[":8080<br/>Dashboard"]
    end
    
    subgraph "Monitoring Ports"
        P9090[":9090<br/>Prometheus"]
        P3001[":3001<br/>Grafana"]
        P9093[":9093<br/>Alertmanager"]
        P9100[":9100<br/>Node Exporter"]
        P8081[":8081<br/>cAdvisor"]
        P9115[":9115<br/>Blackbox"]
        P9272[":9272<br/>VMware"]
    end
    
    style P3000 fill:#7b68ee,color:#fff
    style P5000 fill:#4a90e2,color:#fff
    style P3005 fill:#4a90e2,color:#fff
    style P8080 fill:#7b68ee,color:#fff
    
    style P9090 fill:#ff6b6b,color:#fff
    style P3001 fill:#ff6b6b,color:#fff
    style P9093 fill:#ff6b6b,color:#fff
    style P9100 fill:#ff6b6b,color:#fff
    style P8081 fill:#ff6b6b,color:#fff
    style P9115 fill:#ff6b6b,color:#fff
    style P9272 fill:#ff6b6b,color:#fff
```

---

## 📊 Monitoring & Observability

### Monitoring Architecture
```mermaid
graph TB
    subgraph "Data Sources"
        API[Python API<br/>/metrics]
        Node[Node Exporter<br/>System Metrics]
        Cadv[cAdvisor<br/>Container Metrics]
        BB[Blackbox<br/>Health Probes]
        VM[VMware<br/>ESXi Metrics]
    end
    
    subgraph "Collection & Storage"
        Prom[Prometheus<br/>Time-series DB<br/>15s scrape interval]
    end
    
    subgraph "Alerting"
        Rules[Alert Rules<br/>CPU > 80%<br/>Memory > 85%<br/>Service Down]
        AM[Alertmanager<br/>Route & Notify]
        Slack[Slack<br/>Notifications]
    end
    
    subgraph "Visualization"
        Graf[Grafana<br/>Dashboards<br/>Panels<br/>Graphs]
    end
    
    API --> Prom
    Node --> Prom
    Cadv --> Prom
    BB --> Prom
    VM --> Prom
    
    Prom --> Rules
    Rules --> AM
    AM --> Slack
    
    Prom --> Graf
    
    classDef source fill:#4a90e2,stroke:#2e5c8a,stroke-width:2px,color:#fff
    classDef storage fill:#ff9900,stroke:#cc7a00,stroke-width:2px,color:#fff
    classDef alert fill:#dc3545,stroke:#bd2130,stroke-width:2px,color:#fff
    classDef viz fill:#28a745,stroke:#1e7e34,stroke-width:2px,color:#fff
    
    class API,Node,Cadv,BB,VM source
    class Prom storage
    class Rules,AM,Slack alert
    class Graf viz
```

### Available Metrics
```promql
# Application Metrics
whatsapp_messages_sent_total{group="Family",message_type="birthday"} 42
whatsapp_messages_failed_total{group="Friends",reason="timeout"} 2
birthday_bot_daily_check_status 1
birthdays_found_today 3
whatsapp_connection_status 1

# System Metrics
node_cpu_seconds_total{mode="idle"} 98.5
node_memory_MemAvailable_bytes 4294967296
node_filesystem_avail_bytes{mountpoint="/"} 10737418240
node_load1 0.5

# Container Metrics
container_cpu_usage_seconds_total{name="python-api"} 0.25
container_memory_usage_bytes{name="wppconnect-bot"} 524288000

# ESXi Metrics
vmware_host_sensor_temperature_celsius{sensor="CPU0"} 45
vmware_host_cpu_usage 35
vmware_host_memory_usage 60
```

### Grafana Dashboards

**Pre-configured:**
1. **Birthday Bot Overview** - Application metrics
2. **System Resources** - VM performance
3. **Container Metrics** (ID: 193) - Docker stats
4. **ESXi Monitoring** - Host metrics

**Import Additional:**
- Dashboard 1860: Node Exporter Full
- Dashboard 14282: cAdvisor Details

---

## 🎮 Service Manager

**Version 6.0** - Complete Stack Control
```mermaid
stateDiagram-v2
    [*] --> MainMenu
    
    MainMenu --> ServiceManagement
    MainMenu --> Applications
    MainMenu --> Monitoring
    MainMenu --> Tools
    
    ServiceManagement --> Start
    ServiceManagement --> Stop
    ServiceManagement --> Restart
    ServiceManagement --> Status
    ServiceManagement --> Logs
    
    Applications --> WhatsApp
    Applications --> Birthdays
    Applications --> Backups
    
    WhatsApp --> CheckStatus
    WhatsApp --> ShowQR
    WhatsApp --> ForceRescan
    WhatsApp --> SendTest
    
    Birthdays --> List
    Birthdays --> Add
    Birthdays --> Delete
    Birthdays --> TriggerCheck
    
    Backups --> CreateFull
    Backups --> CreateDynamoDB
    Backups --> CreateDocker
    Backups --> Restore
    Backups --> ListBackups
    
    Monitoring --> Health
    Monitoring --> Targets
    Monitoring --> Metrics
    Monitoring --> Alerts
    Monitoring --> OpenGrafana
    
    Tools --> Troubleshoot
    Tools --> Rebuild
    Tools --> CleanDocker
    Tools --> GitStatus
    
    Start --> MainMenu
    Stop --> MainMenu
    CheckStatus --> WhatsApp
    CreateFull --> Backups
    Health --> Monitoring
```

### Launch
```bash
./service_manager.v6
```

### Main Features

**Service Management:**
- ✅ Start/Stop/Restart all services
- ✅ Check service status
- ✅ View logs (all or specific)
- ✅ Restart single service

**WhatsApp Management:**
- ✅ Check connection status
- ✅ Display all groups
- ✅ Send test messages
- ✅ Show QR code
- ✅ **Force new QR code (rescan)**
- ✅ Restart connection

**Backup & Restore:**
- ✅ Complete backups (DynamoDB + Docker)
- ✅ DynamoDB only backups
- ✅ Docker images only
- ✅ List all backups
- ✅ Restore from any backup
- ✅ Setup automatic daily backups

**Monitoring:**
- ✅ Stack health check
- ✅ View Prometheus targets
- ✅ View real-time metrics
- ✅ Check active alerts
- ✅ Quick access to Grafana
- ✅ System resource usage

---

## 💾 Backup & Disaster Recovery

### Backup Strategy
```mermaid
graph LR
    subgraph "Backup Types"
        B1[Complete Backup<br/>DynamoDB + Images]
        B2[DynamoDB Only<br/>Tables Export]
        B3[Docker Images<br/>All Services]
    end
    
    subgraph "Storage Locations"
        S1[Local Server<br/>/opt/backups/]
        S2[GitHub Artifacts<br/>90 days]
        S3[Project Directory<br/>backups/]
    end
    
    subgraph "Automation"
        A1[Daily Cron<br/>2:00 AM]
        A2[CI/CD Pipeline<br/>Every Commit]
        A3[Manual<br/>Service Manager]
    end
    
    B1 --> S1
    B2 --> S2
    B3 --> S3
    
    A1 --> B1
    A2 --> B2
    A3 --> B1
    
    classDef backup fill:#17a2b8,stroke:#117a8b,stroke-width:2px,color:#fff
    classDef storage fill:#ffc107,stroke:#d39e00,stroke-width:2px,color:#000
    classDef auto fill:#28a745,stroke:#1e7e34,stroke-width:2px,color:#fff
    
    class B1,B2,B3 backup
    class S1,S2,S3 storage
    class A1,A2,A3 auto
```

### Recovery Process
```mermaid
flowchart TD
    Start([�� Disaster Event]) --> Assess{📋 Assess Damage}
    
    Assess -->|Complete Loss| FullRestore[🔄 Full System Restore]
    Assess -->|Data Loss| DataRestore[📦 DynamoDB Restore]
    Assess -->|Service Issues| ServiceRestore[🐳 Docker Restore]
    
    FullRestore --> Download[📥 Download DR Package]
    Download --> Extract[📂 Extract Archive]
    Extract --> RunRestore[▶️ Run restore.sh]
    
    DataRestore --> GetBackup[📥 Get DynamoDB Backup]
    GetBackup --> RestoreDB[🔄 Restore to DynamoDB]
    
    ServiceRestore --> PullImages[📥 Pull Docker Images]
    PullImages --> StartServices[▶️ Start Services]
    
    RunRestore --> Verify{✅ Verify}
    RestoreDB --> Verify
    StartServices --> Verify
    
    Verify -->|Success| Complete([✅ Recovery Complete<br/>RTO: 30 minutes])
    Verify -->|Issues| Troubleshoot[🔧 Troubleshoot]
    Troubleshoot --> Verify
    
    style Start fill:#dc3545,stroke:#bd2130,stroke-width:3px,color:#fff
    style Complete fill:#28a745,stroke:#1e7e34,stroke-width:3px,color:#fff
    style Verify fill:#ffc107,stroke:#d39e00,stroke-width:2px,color:#000
```

**RTO (Recovery Time Objective):** 30 minutes  
**RPO (Recovery Point Objective):** Last backup (< 24 hours)

---

## 📡 API Documentation

### Base URL
```
http://192.168.1.66:5000
```

### Endpoints Overview
```mermaid
graph LR
    Client[API Client] --> Health[/health<br/>GET]
    Client --> Birthdays[/birthdays<br/>GET/POST/DELETE]
    Client --> Trigger[/send-birthday-messages<br/>POST]
    Client --> Metrics[/metrics<br/>GET]
    
    Health --> Status[Health Status]
    Birthdays --> CRUD[CRUD Operations]
    Trigger --> Manual[Manual Check]
    Metrics --> Prom[Prometheus Format]
    
    classDef endpoint fill:#4a90e2,stroke:#2e5c8a,stroke-width:2px,color:#fff
    classDef response fill:#28a745,stroke:#1e7e34,stroke-width:2px,color:#fff
    
    class Health,Birthdays,Trigger,Metrics endpoint
    class Status,CRUD,Manual,Prom response
```

### Example Requests

#### Health Check
```bash
GET /health

# Response
{
  "status": "healthy",
  "timestamp": "2024-10-30T12:00:00Z",
  "services": {
    "dynamodb": "connected",
    "whatsapp": "connected"
  }
}
```

#### List Birthdays
```bash
GET /birthdays

# Response
[
  {
    "id": "uuid",
    "name": "John Doe",
    "date": "1990-10-30",
    "group": "Family"
  }
]
```

#### Add Birthday
```bash
POST /birthdays
Content-Type: application/json

{
  "name": "Jane Smith",
  "date": "1995-05-15",
  "group": "Friends"
}
```

---

## 🔧 Troubleshooting

### Common Issues
```mermaid
graph TD
    Issue{Problem Type?}
    
    Issue -->|WhatsApp| WA[WhatsApp Issues]
    Issue -->|Service| Svc[Service Down]
    Issue -->|Performance| Perf[High Usage]
    Issue -->|Data| Data[Database]
    
    WA --> QR[Show QR Code]
    WA --> Rescan[Force Rescan]
    WA --> RestartWPP[Restart Container]
    
    Svc --> Logs[Check Logs]
    Svc --> Rebuild[Rebuild Image]
    Svc --> Restart[Restart Service]
    
    Perf --> Memory[Check Memory]
    Perf --> Clean[Clean Docker]
    Perf --> RestartAll[Restart Stack]
    
    Data --> TestAWS[Test AWS]
    Data --> CheckCreds[Check Credentials]
    Data --> ScanTable[Scan Table]
    
    style Issue fill:#ffc107,stroke:#d39e00,stroke-width:3px,color:#000
    style WA fill:#dc3545,stroke:#bd2130,stroke-width:2px,color:#fff
    style Svc fill:#dc3545,stroke:#bd2130,stroke-width:2px,color:#fff
    style Perf fill:#fd7e14,stroke:#e8590c,stroke-width:2px,color:#fff
    style Data fill:#dc3545,stroke:#bd2130,stroke-width:2px,color:#fff
```

### Quick Fixes

**WhatsApp Not Connected:**
```bash
./service_manager.v6
# Option 6 → Option 5: Force New QR Code
```

**Service Down:**
```bash
docker-compose logs <service-name>
docker-compose restart <service-name>
```

**High Memory:**
```bash
docker stats
docker system prune -af
docker-compose restart
```

---

## 🤝 Contributing

Contributions welcome! Please follow our guidelines:
```mermaid
gitGraph
    commit id: "main"
    branch feature/new-feature
    checkout feature/new-feature
    commit id: "implement feature"
    commit id: "add tests"
    commit id: "update docs"
    checkout main
    merge feature/new-feature
    commit id: "release v6.1"
```

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file

---

## 🙏 Acknowledgments

- [wppconnect-team](https://github.com/wppconnect-team) - WhatsApp Web API
- [Prometheus](https://prometheus.io/) - Monitoring
- [Grafana Labs](https://grafana.com/) - Visualization
- AWS DynamoDB - Data storage

---

## 📞 Support

- 🐛 **Issues:** [GitHub Issues](https://github.com/adeolu-rabiu/whatsapp-birthday-lambda/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/adeolu-rabiu/whatsapp-birthday-lambda/discussions)
- 📚 **Docs:** [Wiki](https://github.com/adeolu-rabiu/whatsapp-birthday-lambda/wiki)

---

<div align="center">

**⭐ Star this repository if you find it helpful!**

**Made with ❤️ by [Adeolu Rabiu](https://github.com/adeolu-rabiu)**

</div>
