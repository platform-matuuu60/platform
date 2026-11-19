# 1. Local AWS emulation with Floci

Date: 2026-11-19
Status: Accepted

## Context

The platform must demonstrate AWS infrastructure (Lambda, API Gateway, DynamoDB, S3, CloudFront, EKS, RDS) without continuous AWS spend. LocalStack Community was archived in March 2026. AWS Emulator launched in November 2026 but its service coverage is still limited. Floci (MIT) runs Lambda, RDS, ElastiCache, ECS and EKS as real Docker containers and serves CloudFront and S3 website traffic.

## Decision

Use Floci as the `floci` target. Terraform modules and Crossplane compositions stay identical across `floci` and `aws`; only provider configuration differs per environment. IAM enforcement is enabled in Floci.

Floci runs on the host with Docker, not inside k3s, because Lambda execution needs a Docker engine and mounting the Docker socket into a pod is equivalent to host root. Floci is never exposed to the internet; only application hostnames are routed to it.

## Consequences

- Zero-cost iteration and a public demo.
- Fidelity gaps are expected and documented in a Floci vs AWS table (for example, CloudFront routes but does not cache; ACM certificates are issued without validation).
- A short real-AWS session validates the `aws` environment.
