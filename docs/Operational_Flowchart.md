%%{init: {'themeVariables': { 'fontSize': '18px'}}}%%
flowchart TD
  %% Nodes
  T[08:00 daily cron<br/>whatsapp_birthday_service.py]
  A[Call Python API: /birthday/check]
  C[Fetch config and groups]
  D[Compute today's MM-DD]
  Q[(AWS RDS: Birthdays)]
  R{Any matches?}
  B1[Matches per group]
  M1[Render birthday message]
  S1[[wppconnect send-message]]
  W1[[WhatsApp groups]]
  L1[(Log success)]
  F1[Pick fun fact message]
  S2[[wppconnect send-message]]
  W2[[WhatsApp groups]]
  L2[(Log success)]
  E{Error?}
  H[Retry with backoff;<br/>write error log]
  EL[(Elasticsearch Kibana)]
  Done((Done))

  %% Edges
  T --> A --> C --> D --> Q --> R
  R -- Yes --> B1 --> M1 --> S1 --> W1 --> L1 --> Done
  R -- No  --> F1 --> S2 --> W2 --> L2 --> Done
  A --> E
  S1 --> E
  S2 --> E
  E -- Yes --> H --> EL
  E -- No  --> Done

  %% Styles (cool & gentle, bold text)
  classDef base       stroke-width:1.5px,font-weight:700;
  classDef start      fill:#e3f2fd,stroke:#64b5f6,color:#0d47a1,stroke-width:1.5px,font-weight:700;
  classDef process    fill:#e6f7ff,stroke:#66b3ff,color:#0b3d91,stroke-width:1.5px,font-weight:700;
  classDef decision   fill:#e0f7fa,stroke:#26c6da,color:#006064,stroke-width:1.5px,font-weight:700;
  classDef datastore  fill:#ede7f6,stroke:#7e57c2,color:#4527a0,stroke-width:1.5px,font-weight:700;
  classDef action     fill:#e8f0fe,stroke:#5c9ded,color:#1a73e8,stroke-width:1.5px,font-weight:700;
  classDef external   fill:#e8eaf6,stroke:#5c6bc0,color:#283593,stroke-width:1.5px,font-weight:700;
  classDef log        fill:#eceff1,stroke:#90a4ae,color:#37474f,stroke-width:1.5px,font-weight:700;
  classDef terminal   fill:#e0f2f1,stroke:#26a69a,color:#004d40,stroke-width:1.5px,font-weight:700;
  classDef error      fill:#ffeef0,stroke:#ef9a9a,color:#b71c1c,stroke-width:1.5px,font-weight:700;

  %% Assign classes
  class T start;
  class A,C,D,B1,M1,F1 process;
  class R,E decision;
  class Q datastore;
  class S1,S2 action;
  class W1,W2 external;
  class L1,L2,EL log;
  class Done terminal;
  class H error;

