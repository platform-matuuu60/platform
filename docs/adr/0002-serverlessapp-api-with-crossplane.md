# 2. ServerlessApp platform API with Crossplane

Date: 2026-11-19
Status: Accepted

## Context

Teams need HTTP APIs without learning Lambda, API Gateway or IAM. The cluster already runs ArgoCD and Crossplane v2. Floci runs on the host (ADR 0001), outside the pod network.

## Decision

- **One namespaced API, `ServerlessApp`** (`platform.idp.internal/v1alpha1`). A team declares runtime, sizing and the artifact key; the platform composes an IAM role, the Lambda function, an HTTP API (integration, `$default` route and stage) and the invoke permission. The URL is reported in `status.url`.
- **`spec.target` selects the `ClusterProviderConfig`** of the same name (`floci`, later `aws`). One Composition serves both targets; only the provider config differs.
- **Composition functions**: `function-go-templating` renders the resources, `function-auto-ready` derives readiness. Resources reference each other by name (`roleRef`, `apiIdRef`, `integrationUriRef`, `targetRef`, `functionNameRef`).
- **AWS names are prefixed with the namespace** (`team-shop-hello-api`) because AWS names are account-wide while Kubernetes names are per namespace.
- **Terraform owns platform base, Crossplane owns team requests.** The artifacts bucket is created by `terraform/envs/local`; teams never request it.
- **Floci reaches the cluster through the private Docker gateway** (`172.18.0.1:4566`), exposed in-cluster as the `floci.floci-system` Service backed by a static EndpointSlice. Nothing listens on the public interface.
- **Only the needed service providers are installed** (`iam`, `lambda`, `apigatewayv2`); each provider is a separate pod.

## Consequences

- Deploying new code is a one-line change of `spec.artifact.key`; rolling back is `git revert` in the gitops repo.
- The provider config must list every AWS service explicitly. An unlisted service silently goes to real AWS (see docs/floci-vs-aws.md).
- S3 buckets cannot be managed by Crossplane against Floci yet, because the S3 provider calls S3 Control with an account-ID host prefix that does not resolve in-cluster. Revisit for frontend buckets in phase 3.
