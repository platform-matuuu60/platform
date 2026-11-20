#!/usr/bin/env bash
# Smoke test: the hello-api deployed by terraform/envs/local answers over HTTP.
set -euo pipefail

ENV_DIR="$(cd "$(dirname "$0")/../terraform/envs/local" && pwd)"
URL="$(terraform -chdir="$ENV_DIR" output -raw hello_api_url 2>/dev/null || true)"

if [[ -z "$URL" ]]; then
  echo "FAIL: no hello_api_url output (is the environment applied?)" >&2
  exit 1
fi

body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

status="$(curl -s -o "$body_file" -w '%{http_code}' "${URL%/}/hello?name=idp")"
body="$(cat "$body_file")"

if [[ "$status" != "200" ]]; then
  echo "FAIL: expected HTTP 200, got $status: $body" >&2
  exit 1
fi

if ! grep -q '"message": *"Hello, idp!"' <<<"$body"; then
  echo "FAIL: unexpected body: $body" >&2
  exit 1
fi

echo "PASS: $URL -> $status $body"
