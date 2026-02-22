# Secure Data Automation Infrastructure

## Overview

This repository contains the Infrastructure as Code (IaC) configuration for a secure, self-hosted automation and data processing environment. The stack is designed to handle ETL (Extract, Transform, Load) pipelines and API orchestrations with a strong emphasis on security, network isolation, and **automated market intelligence using Large Language Models (LLM)**.

The architecture is fully containerized and enforces strict "Zero Trust" principles for continuous integration and deployment.

## Architecture & Tech Stack

The system is deployed via Docker Compose and relies on the following decoupled layers:

* **Automation Engine:** The core workflow execution environment (n8n), configured for production (filesystem binary mode) to ensure stability on memory-constrained hosts.
* **Relational Database:** PostgreSQL instance for persistent storage, utilizing advanced UPSERT logic to track price movements and historical data.
* **Intelligence Layer:** Integration with Google Gemini (or equivalent LLMs) to perform qualitative scoring and probabilistic market analysis.
* **Off-site Storage:** S3-compatible Object Storage (Scaleway / AWS) for secure, immutable backups managed via **Rclone**.

## Data Integrity & Backups

To ensure business continuity, the infrastructure implements a robust "Off-site" backup strategy:

* **Streaming Dumps:** Daily SQL dumps are performed and piped directly to Object Storage using `rclone rcat`. This "Streaming" approach eliminates the need for large local temporary files, preserving disk I/O and space.
* **Lifecycle Management:** Retention is enforced at the storage provider level via Lifecycle Rules, automatically purging archives older than 30 days to optimize costs and comply with data minimization principles.

## Monitoring & Observability

The system follows a **"Silent Success"** philosophy to prevent alert fatigue:

* **Critical Alerts:** Real-time notifications are sent via Discord Webhooks only in the event of pipeline failures, backup errors, or system-level exceptions.
* **Memory Management:** Node.js heap limits (`--max-old-space-size`) are explicitly defined to prevent Out-Of-Memory (OOM) kills on VPS environments.

## Security Posture

* **Network Isolation:** The database instance does not expose any port to the public internet. Access is restricted to the internal Docker network.
* **Secret Management:** No credentials or webhooks are tracked in version control. All sensitive data is injected via GitHub Actions Secrets and managed through environment variables on the host.
* **Zero Trust CI/CD:** The deployment process uses short-lived, encrypted sessions to transfer the stack definition to the VPS.

## Continuous Deployment (CI/CD)

The repository utilizes GitHub Actions to implement a push-based deployment strategy:

1. Provision an ephemeral runner and generate the `.env` from encrypted secrets.
2. Deploy configuration files and maintenance scripts via SCP.
3. Set execution permissions on deployment and backup scripts.
4. Execute `docker compose up -d` with image pruning to ensure a lean host environment.

## Local Development Setup

To run this stack locally:

1. Clone the repository.
2. `cp .env.example .env` and populate it with your credentials.
3. Ensure **Rclone** is configured on your local machine to match the `BACKUP_RCLONE_REMOTE` variable.
4. `docker compose up -d`
