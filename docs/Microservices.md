flowchart TD
  %% ===== Styles (keep simple for compatibility) =====
  classDef core fill:#E8F5E9,stroke:#2E7D32,stroke-width:1.5px,color:#1B5E20;
  classDef monitor fill:#FFF3E0,stroke:#EF6C00,stroke-width:1.5px,color:#E65100;
  classDef support fill:#EDE7F6,stroke:#5E35B1,stroke-width:1.5px,color:#4527A0;
  classDef external fill:#ECEFF1,stroke:#546E7A,stroke-width:1.5px,color:#263238;
  classDef note fill:#FFFFFF,stroke:#B0BEC5,color:#455A64,stroke-dasharray:5 3,stroke-width:1px;

  %% ===== Core Application Services (3) =====
  subgraph CORE [Core Application Services 3]
    direction TB
    UI[Web UI React - port 3000]
    PAPI[Python API Flask - port 5000]
    WPP[wppconnect bot - port 3005]
  end
  class UI,PAPI,WPP core

  %% ===== Monitoring & Logging Stack (4) =====
  subgraph MON [Monitoring and Logging Stack 4]
    direction TB
    ES[Elasticsearch - port 9200]
    KB[Kibana - port 5601]
    FB[Filebeat]
    MB[Metricbeat]
  end
  class ES,KB,FB,MB monitor

  %% ===== Supporting Services (2) =====
  subgraph SUPP [Supporting Services 2]
    direction TB
    DASH[Operational Dashboard - port 8080]
    CRON[Cron Service - runs at 08:00]
  end
  class DASH,CRON support

  %% ===== External or Shared =====
  DDB[(AWS DynamoDB Birthdays)]
  WA[[WhatsApp Network]]
  USER[[Admin or Users Browser]]
  LOGS[(Host Logs at app logs)]
  class DDB,WA,USER,LOGS external

  %% ===== Flows =====
  USER --> UI
  USER --> DASH
  UI -->|REST| PAPI
  DASH -->|proxy to API| PAPI
  PAPI -->|query| DDB
  PAPI -->|send message| WPP
  WPP --> WA
  CRON -->|schedule 08:00| PAPI
  CRON -->|verify bot| WPP

  FB --> ES
  MB --> ES
  ES <--> KB

  PAPI --- LOGS
  WPP --- LOGS
  CRON --- LOGS

  N1[Docker network birthday network]
  N2[Ports UI 3000 API 5000 WPP 3005 Dashboard 8080 ES 9200 Kibana 5601]
  N1 --- N2
  class N1,N2 note

