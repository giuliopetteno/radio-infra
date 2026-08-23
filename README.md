# Radio Ecosystem Orchestrator (Radio Infra)

Orchestration, observability, and deployment repository for the Radio ecosystem microservices.

This repository does not contain application code — it wires together the independent [`radio-registry`](https://github.com/giuliopetteno/radio-registry) and [`radio-analytics`](https://github.com/giuliopetteno/radio-analytics) microservices via Docker Compose, and drives their automated deployment to Amazon Web Services (AWS).

Microservices application traces, metrics, and logs are collected by **Alloy** and stored in **Prometheus** (metrics), **Tempo** (distributed traces), and **Loki** (logs).
**Grafana** ties the three signals together for visualization, dashboards, and trace-to-log correlation.

> **🚧 Work in Progress**
>
> This project is currently under active development and serves as a demonstration of modern DevOps and cloud infrastructure practices.

## Live Demo

Grafana dashboards are available at:
[`radio-analytics.giuliopetteno.dev`](https://giuliopetteno.s.gy/radio-analytics) *(short link for click tracking)*

- [`Radio Analytics - Insights`](https://radio-analytics.giuliopetteno.dev/d/adc7w8k/insights) → Business analytics for medical devices, including inventory, allocation, lifecycle, organizational structure, and activity trends, available both in real time and as scheduled, persisted reports
- [`Radio Analytics - Performance`](https://radio-analytics.giuliopetteno.dev/d/adflz27/performance) → Analytics engine execution monitoring, including outcomes, execution times, KPI status and performance, across both real-time and scheduled report executions
- [`Radio Ecosystem - Operations`](https://radio-analytics.giuliopetteno.dev/d/ad9wm9g/operations) → End-to-end observability of the entire ecosystem, including service dependencies, HTTP and Kafka traffic, logs, and distributed traces

> **Note:** Anonymous read-only access — no login required.

## Features

- Containerization
- Automated CI/CD pipeline
- Cloud deployment
- Full observability stack: distributed tracing, metrics, and structured logging with cross-signal correlation

## Architecture

```mermaid
flowchart LR
  Client([Client])

  subgraph aws["AWS"]
    subgraph ec2["AWS EC2"]
      Nginx[nginx]

      subgraph compose["Docker Compose · radio-infra"]
        subgraph network["Docker network · radio-net"]
          Registry[radio-registry]
          Analytics[radio-analytics]
          Kafka[Apache Kafka]
          Alloy[Alloy]
          Prometheus[Prometheus]
          Tempo[Tempo]
          Loki[Loki]
          Grafana[Grafana]
        end
      end
    end

    RDS["AWS RDS · PostgreSQL"]
  end

  Client --> Nginx
  Nginx --> Registry
  Nginx --> Grafana

  Registry -- radio_registry schema --> RDS
  Analytics -- radio_analytics schema --> RDS

  Registry --> Kafka
  Kafka --> Analytics

  Grafana --> Analytics

  Registry -. OTLP .-> Alloy
  Analytics -. OTLP .-> Alloy
  Alloy -. metrics .-> Prometheus
  Alloy -. logs .-> Loki
  Alloy -. traces .-> Tempo

  Grafana --> Prometheus
  Grafana --> Loki
  Grafana --> Tempo

  style aws fill:#fff,stroke:#d0d7de
  style ec2 fill:#fff,stroke:#ed7100,stroke-width:2px
  style compose fill:#f6f8fa,stroke:#d0d7de
  style network fill:#fff,stroke:#d0d7de,stroke-dasharray:5 5

  classDef app fill:#f6f8fa,stroke:#d0d7de,color:#24292f
  classDef proxy fill:#e8467c,stroke:#e8467c,color:#0d1117
  classDef broker fill:#79c0ff,stroke:#79c0ff,color:#0d1117
  classDef metrics fill:#e6522c,stroke:#e6522c,color:#fff
  classDef grafana fill:#f9a825,stroke:#f9a825,color:#0d1117
  classDef awsService fill:#ed7100,stroke:#ed7100,color:#fff

  class Registry,Analytics,Client app
  class Nginx proxy
  class Kafka broker
  class Prometheus metrics
  class Alloy,Tempo,Loki,Grafana grafana
  class RDS awsService
```

- `radio-registry` — producer service (medical devices management system)
- `radio-analytics` — consumer service (medical devices analytics system)
- Services communicate exclusively via **Apache Kafka**; they share no code and are versioned in separate repositories
- A shared Docker network (`radio-net`) connects all containers
- Application code lives in the service repositories; the message broker and observability stack are defined and orchestrated here

## Deployment Modes

This repo supports three distinct Compose configurations:

- **`docker-compose.yml`** — local development. Uses Compose `include` to pull in each service's own compose file from sibling directories, building images from local source
- **`docker-compose.prod.yml`** — production-like local environment. Uses Compose `include` to pull in each service's own `.prod` compose file from sibling directories, building images from local source
- **`docker-compose.aws.yml`** — cloud production. Self-contained (no dependency on sibling repos being cloned), pulls pre-built images directly from Amazon ECR, and is the configuration deployed to EC2

## CI/CD Pipeline

```mermaid
flowchart LR
  subgraph github["GitHub"]
    subgraph repos["Repositories"]
      RegistryRepo[radio-registry]
      AnalyticsRepo[radio-analytics]
      InfraRepo[radio-infra]
    end

    subgraph ci["CI · GitHub Actions"]
      Build[Build and test]
      Image[Build container image]
    end

    subgraph cd["CD · GitHub Actions"]
      Deploy[SSM Run Command]
    end
  end

  subgraph aws["AWS"]
    ECR[AWS ECR]

    subgraph ec2["AWS EC2"]
      Compose[Docker Compose<br/>radio-infra]
    end
  end

  RegistryRepo -- push --> Build
  AnalyticsRepo -- push --> Build

  Build --> Image
  Image -- docker push · OIDC --> ECR
  Image -- repository_dispatch --> InfraRepo

  InfraRepo --> Deploy
  Deploy -- OIDC --> Compose
  Compose -- docker pull --> ECR

  style github fill:#fff,stroke:#d0d7de
  style repos fill:#fff,stroke:#d0d7de
  style ci fill:#fff,stroke:#d0d7de
  style cd fill:#fff,stroke:#d0d7de
  style aws fill:#fff,stroke:#d0d7de
  style ec2 fill:#fff,stroke:#d0d7de

  classDef repo fill:#f6f8fa,stroke:#d0d7de,color:#24292f
  classDef pipeline fill:#a371f7,stroke:#a371f7,color:#0d1117
  classDef awsService fill:#ed7100,stroke:#ed7100,color:#fff

  class RegistryRepo,AnalyticsRepo,InfraRepo repo
  class Build,Image,Deploy pipeline
  class ECR,Compose awsService
```

## Technology Stack

- Containerization with Docker and Docker Compose
- Automated CI/CD with GitHub Actions
- Amazon Web Services (AWS) deployment:
  - EC2 (Docker Compose orchestration, IAM-only access via SSM)
  - ECR for container image registry
  - RDS (PostgreSQL, private subnet, EC2-scoped security group, SSM tunnel for local dev)
  - GitHub Actions → OIDC → ECR → SSM Run Command deploy
  - IAM: least-privilege roles throughout (GitHub Actions OIDC roles, EC2 instance role)
  - Secrets management via AWS Systems Manager Parameter Store
  - Nginx reverse proxy for name-based routing, with TLS via Let's Encrypt and automated renewal
  - DNS-based service routing under a custom domain (`giuliopetteno.dev`) via Route 53 with Elastic IP
- Observability stack:
  - Alloy as unified OpenTelemetry (OTLP) collector
  - Prometheus for metrics storage
  - Tempo for distributed trace storage
  - Loki for log aggregation
  - Grafana for dashboards, visualization, and trace-to-log correlation
