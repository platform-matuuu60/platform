#!/usr/bin/env bash
# Smoke test: a ServerlessApp becomes Ready and its URL answers over HTTP.
# Usage: smoke-serverlessapp.sh <namespace> <name>
set -euo pipefail

NS="${1:?namespace required}"
NAME="${2:?name required}"
TIMEOUT="${TIMEOUT:-300s}"

if ! kubectl -n "$NS" wait "serverlessapp/$NAME" --for=condition=Ready --timeout="$TIMEOUT" >/dev/null 2>&1; then
  echo "FAIL: serverlessapp $NS/$NAME not Ready within $TIMEOUT" >&2
  kubectl -n "$NS" get "serverlessapp/$NAME" 2>&1 >&2 || true
  exit 1
fi

URL="$(kubectl -n "$NS" get "serverlessapp/$NAME" -o jsonpath='{.status.url}')"
if [[ -z "$URL" ]]; then
  echo "FAIL: status.url is empty" >&2
  exit 1
fi

body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT
status="$(curl -s -o "$body_file" -w '%{http_code}' "${URL%/}/hello?name=idp")"
body="$(cat "$body_file")"

if [[ "$status" != "200" ]] || ! grep -q '"message": *"Hello, idp!"' <<<"$body"; then
  echo "FAIL: $URL -> $status $body" >&2
  exit 1
fi

echo "PASS: $NS/$NAME $URL -> $status $body"
