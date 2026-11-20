# Floci vs AWS: fidelity gaps

Differences found while running the same Terraform against Floci and real AWS. Each gap is handled in the environment layer (`terraform/envs/*`), never inside modules.

| Area | Floci | Real AWS | Handled in |
|---|---|---|---|
| HTTP API URL | Served on `http://{api_id}.execute-api.localhost.floci.io:4566`; `api_endpoint` still reports the AWS hostname | `https://{api_id}.execute-api.{region}.amazonaws.com` | `envs/local` builds the URL from `api_id` |
| Local hostnames | `*.localhost.floci.io` resolves to loopback through public DNS | n/a | Requires outbound DNS from the host |
| Credentials | Static `test`/`test` keys map to the account root `000000000000` | Real IAM identities | `envs/local` provider block |
| CloudFront | Routes to origins, no caching | Global CDN with caching | Expected; documented in ADR 0001 |
| ACM | Certificates issued instantly without validation | DNS validation required | Expected; documented in ADR 0001 |
