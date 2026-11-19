#!/usr/bin/env bash
# Zip a function source directory and upload it to the artifacts bucket under a
# content-addressed key. Prints the key. Usage: publish-artifact.sh <src-dir> <app-name>
set -euo pipefail

SRC="${1:?source directory required}"
APP="${2:?app name required}"
BUCKET="${ARTIFACTS_BUCKET:-shopco-artifacts}"
ENDPOINT="${AWS_ENDPOINT_URL:-http://127.0.0.1:4566}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# Fixed timestamps and sorted entries keep the zip reproducible, so the key only
# changes when the code changes.
python3 - "$SRC" "$workdir/package.zip" <<'PY'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(src):
        dirs.sort()
        for name in sorted(files):
            path = os.path.join(root, name)
            info = zipfile.ZipInfo(os.path.relpath(path, src), date_time=(1980, 1, 1, 0, 0, 0))
            info.external_attr = 0o644 << 16
            with open(path, "rb") as fh:
                zf.writestr(info, fh.read(), zipfile.ZIP_DEFLATED)
PY

digest="$(sha256sum "$workdir/package.zip" | cut -c1-16)"
key="${APP}/${digest}.zip"

AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}" AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}" \
  aws --endpoint-url "$ENDPOINT" --region us-east-1 s3 cp --only-show-errors \
  "$workdir/package.zip" "s3://${BUCKET}/${key}"

echo "$key"
