# Secure Data Automation Infrastructure

## Overview

This repository contains the Infrastructure as Code (IaC) configuration for a secure, self-hosted automation and data processing environment. The stack is designed to handle ETL (Extract, Transform, Load) pipelines and API orchestrations with a strong emphasis on security, network isolation, and automated deployment.

The architecture is fully containerized and enforces strict "Zero Trust" principles for continuous integration and deployment.

## Architecture & Tech Stack

The system is deployed via Docker Compose and relies on the following decoupled microservices:

* **Automation Engine:** The core workflow execution environment, configured for production (logging pruned, restricted memory limits) to ensure host stability.
* **Relational Database:** The persistent storage layer, initialized automatically via DDL scripts to ensure environment consistency and idempotency.
* **Dynamic Ingress Integration (production):** Instead of bundling a dedicated proxy, the stack leverages dynamic environment variables and an external Docker network to auto-register with the host's central Edge Router. This router handles TLS termination and network routing natively.

## Security Posture

Security and system isolation are the core drivers of this configuration:

* **Network Isolation:** The database instance does not expose any port to the public internet. Access is restricted to the internal Docker network, and explicitly bound to the host's local loopback to allow secure administration via SSH tunneling only.
* **Zero Trust CI/CD:** No environment files or hardcoded credentials are tracked in version control. Secrets are injected ephemerally by the CI/CD runner during the deployment process and securely transferred via encrypted protocols.
* **Privilege Separation:** The production deployment process operates under a dedicated, unprivileged service account, strictly isolated from root or personal directories, minimizing the blast radius in the event of a compromised pipeline.
* **Immutable Infrastructure:** Containers are run with read-only configurations where applicable, and persistent data is strictly segregated into dedicated Docker volumes.

## Continuous Deployment (CI/CD)

The repository utilizes GitHub Actions to implement a push-based deployment strategy. The pipeline executes the following sequence:

1. Provisions an ephemeral runner.
2. Dynamically generates the required configuration files using encrypted platform secrets.
3. Securely transfers the configuration definitions and initialization scripts to the target server.
4. Executes the deployment orchestrator to pull updated images and recreate altered services non-disruptively.
5. Performs garbage collection to clean up dangling images and prevent storage saturation over time.

## Local Development Setup

To run this stack locally, you must provide your own environment variables.

1. Clone the repository.
2. Duplicate the `.env.example` file to `.env` and populate it with your local development credentials.
3. Execute the container orchestration command to start the stack in detached mode.

---
