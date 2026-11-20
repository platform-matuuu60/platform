#!/usr/bin/env bash
# Bootstrap the Keycloak realm used by the IDP portal (idempotent).
#   - realm "idp" without self-registration
#   - confidential OIDC client "backstage"
#   - SealedSecret backstage/backstage-auth with the client secret and a session secret
#
# Requires: curl, python3, kubectl, kubeseal and a port-forward to Keycloak:
#   kubectl -n keycloak port-forward svc/keycloak 18080:8080
# Admin credentials come from the environment or an interactive prompt, never from arguments:
#   KC_ADMIN_USER, KC_ADMIN_PASSWORD
set -euo pipefail

KC_URL="${KC_URL:-http://127.0.0.1:18080}"
REALM="${REALM:-idp}"
CLIENT_ID="${CLIENT_ID:-backstage}"
PORTAL_URL="${PORTAL_URL:-https://backstage.cloud-it.com.ar}"
OUT="${OUT:-kubernetes/backstage/sealed-auth.yaml}"
if [[ -z "${KC_ADMIN_USER:-}" ]]; then read -rp "Keycloak admin user: " KC_ADMIN_USER; fi
if [[ -z "${KC_ADMIN_PASSWORD:-}" ]]; then read -rsp "Keycloak admin password: " KC_ADMIN_PASSWORD; echo; fi

json() { python3 -c "import sys,json; d=json.load(sys.stdin); print($1)"; }

if ! TOKEN_JSON="$(curl -fsS "$KC_URL/realms/master/protocol/openid-connect/token" \
  --data-urlencode grant_type=password --data-urlencode client_id=admin-cli \
  --data-urlencode "username=$KC_ADMIN_USER" --data-urlencode "password=$KC_ADMIN_PASSWORD")"; then
  echo "error: Keycloak rejected the admin credentials for realm master" >&2
  exit 1
fi
TOKEN="$(json 'd["access_token"]' <<<"$TOKEN_JSON")"
api() { curl -fsS -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"; }

if api -o /dev/null "$KC_URL/admin/realms/$REALM" 2>/dev/null; then
  echo "realm $REALM: exists"
else
  api -X POST "$KC_URL/admin/realms" -d @- <<EOF
{"realm":"$REALM","displayName":"IDP","enabled":true,"registrationAllowed":false,
 "resetPasswordAllowed":true,"loginWithEmailAllowed":true,"duplicateEmailsAllowed":false,
 "sslRequired":"external","bruteForceProtected":true}
EOF
  echo "realm $REALM: created"
fi

client_uuid() { api "$KC_URL/admin/realms/$REALM/clients?clientId=$CLIENT_ID" | json 'd[0]["id"] if d else ""'; }
UUID="$(client_uuid)"
if [[ -n "$UUID" ]]; then
  echo "client $CLIENT_ID: exists"
else
  api -X POST "$KC_URL/admin/realms/$REALM/clients" -d @- <<EOF
{"clientId":"$CLIENT_ID","name":"Backstage","protocol":"openid-connect","enabled":true,
 "publicClient":false,"standardFlowEnabled":true,"directAccessGrantsEnabled":false,
 "implicitFlowEnabled":false,"serviceAccountsEnabled":false,
 "redirectUris":["$PORTAL_URL/api/auth/oidc/handler/frame"],
 "webOrigins":["$PORTAL_URL"],"rootUrl":"$PORTAL_URL"}
EOF
  UUID="$(client_uuid)"
  echo "client $CLIENT_ID: created"
fi

CLIENT_SECRET="$(api "$KC_URL/admin/realms/$REALM/clients/$UUID/client-secret" | json 'd["value"]')"
SESSION_SECRET="$(python3 -c 'import secrets; print(secrets.token_urlsafe(48))')"

kubectl create secret generic backstage-auth -n backstage \
  --from-literal=keycloak-client-secret="$CLIENT_SECRET" \
  --from-literal=session-secret="$SESSION_SECRET" \
  --dry-run=client -o yaml \
  | kubeseal --controller-namespace kube-system --controller-name sealed-secrets-controller \
      --format yaml > "$OUT"
echo "sealed secret written to $OUT"
