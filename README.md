# Radio Ecosystem Orchestrator (Radio Infra)

Orchestration and deployment repository for the **radio-registry** and **radio-analytics** microservices.

This repository does not contain application code — it wires together the independent [`radio-registry`](https://github.com/giuliopetteno/radio-registry) and [`radio-analytics`](https://github.com/giuliopetteno/radio-analytics) repositories via Docker Compose, and drives their automated deployment to Amazon Web Services (AWS).

> **⚠️ Work in Progress**
>
> This project is currently under active development and serves as a demonstration of modern DevOps and cloud infrastructure practices.

## Architecture

- `radio-registry` — producer service (medical equipment management system)
- `radio-analytics` — consumer service (medical equipment analytics system)
- Services communicate exclusively via **Apache Kafka**; they share no code and are versioned in separate repositories
- A shared Docker network (`radio-net`) connects both containers

## Deployment Modes

This repo supports three distinct Compose configurations:

- **`docker-compose.yml`** — local development. Uses Compose `include` to pull in each service's own compose file from sibling directories, building images from local source.
- **`docker-compose.prod.yml`** — local prod development. Uses Compose `include` to pull in each service's own `.prod` compose file from sibling directories, building images from local source.
- **`docker-compose.aws.yml`** — cloud production. Self-contained (no dependency on sibling repos being cloned), pulls pre-built images directly from Amazon ECR, and is the configuration deployed to EC2.

## Technology Stack

- Containerization with Docker & Docker Compose
- Apache Kafka for event-driven communication
- Amazon Web Services (AWS) deployment:
	- EC2 (Docker Compose orchestration, IAM-only access via SSM)
	- ECR for container image registry
	- Automated CI/CD: GitHub Actions (cross-repo triggering) → OIDC → ECR → SSM Run Command deploy
	- IAM: least-privilege roles throughout (GitHub Actions OIDC roles, EC2 instance role)
	- Secrets management via AWS Systems Manager Parameter Store
	- TLS via Let's Encrypt/Certbot, Route 53 DNS-01 validation, automated renewal
	- Route 53, Elastic IP + custom domain (`giuliopetteno.dev`)
