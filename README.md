# Radio Ecosystem Orchestrator (Radio Infra)

Orchestration repository for the **radio-registry** and **radio-analytics** microservices.

This repository does not contain application code — it wires together the independent [`radio-registry`](https://github.com/giuliopetteno/radio-registry) and [`radio-analytics`](https://github.com/giuliopetteno/radio-analytics) repositories via Docker Compose, so both services can be built, networked, and launched with a single command.

## Architecture

- `radio-registry` — producer service (medical equipment management system)
- `radio-analytics` — consumer service (medical equipment analytics system)
- Services communicate exclusively via **Apache Kafka**; they share no code and are versioned in separate repositories
- A shared Docker network (`radio-net`) connects both containers
- This repo uses Compose's [`include`](https://docs.docker.com/compose/how-tos/multiple-compose-files/include/) feature to pull in each service's own `docker-compose.yml` (or `docker-compose.prod.yml` for production environment), keeping ownership of service config inside each service's repository
