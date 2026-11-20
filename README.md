# ShopCo Platform

Internal developer platform for **ShopCo**, a fictional e-commerce company. Every team used to ship differently: hand-made pipelines, infrastructure via tickets, and services nobody else could debug. This platform gives them one golden path from code to production.

> Portfolio project. "AWS" runs locally on [Floci](https://github.com/floci-io/floci) at zero cost; the same infrastructure code targets real AWS.

## What a developer gets

1. Pick a template in Backstage (serverless API, fullstack, containers, WordPress).
2. The platform creates the repo, CI, and a pull request to the GitOps repo.
3. After merge, ArgoCD and Crossplane provision the app and its infrastructure.
4. The app is live with TLS, traces, dashboards, and alerts.

## Deployment targets

| Target | Runs on | Purpose |
|---|---|---|
| `floci` | Floci (local AWS emulator) | Day-to-day, public demo, zero cost |
| `aws` | Real AWS | Same code, short validation sessions |
| `onprem` | k3s | Container workloads (CloudNativePG, Keycloak, object storage) |

## Repositories

| Repo | Contents |
|---|---|
| `platform` (this) | Terraform modules and environments, Crossplane APIs, platform components, policies, ADRs |
| `gitops` | Desired state per team and environment; written by Backstage via PRs |
| `ci-workflows` | Reusable CI workflows: build, security gate, deploy |
| `backstage` | Developer portal and software templates |
| `sample-apps` | Example apps that can be added to any generated service |

## Layout

```
terraform/
  modules/        # reusable modules, identical for every target
  envs/local/     # Floci
  envs/aws/       # real AWS
examples/         # sample function code used by environments
scripts/          # host tooling (Floci lifecycle)
tests/            # smoke tests
docs/adr/         # architecture decision records
```

## Quick start (local)

Requirements: Docker, Terraform >= 1.9, curl.

```bash
./scripts/floci.sh up                      # Floci on 127.0.0.1:4566
terraform -chdir=terraform/envs/local init
terraform -chdir=terraform/envs/local apply
./tests/smoke-hello-api.sh                 # PASS: ... -> 200 {"message": "Hello, shopco!"}
```

Known differences between Floci and AWS are tracked in [docs/floci-vs-aws.md](docs/floci-vs-aws.md).

## Roadmap

- [x] Phase 1: Terraform against Floci, a Lambda behind API Gateway reachable by URL
- [ ] Phase 2: ArgoCD + Crossplane `ServerlessApp` API
- [ ] Phase 3: Public apps via Gateway API + TLS + CloudFront
- [ ] Phase 4: CI on in-cluster runners + security gate
- [ ] Phase 5: Backstage portal and templates
- [ ] Phase 6: Observability, autoscaling, policies
- [ ] Phase 7: Real AWS session
- [ ] Phase 8: On-prem target and container templates
- [ ] Phase 9: Advanced serverless templates
