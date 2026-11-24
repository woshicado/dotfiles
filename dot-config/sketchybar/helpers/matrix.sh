#!/bin/bash
# Unread Matrix counts for the notification widget, as {"msg_count":N,"mention_count":M}.
# Cinny sets no Dock badge, so the counts come from the homeserver: a filtered /sync that
# returns little more than each joined room's unread_notifications.
#
# One-time setup: `matrix.sh login` creates a dedicated "sketchybar" device and prints
# its token; put MATRIX_URL and MATRIX_TOKEN into ~/dotfiles/secrets.env (sops edit).

CACHE_FILE="/tmp/matrix_unread.json"
LOCK_DIR="/tmp/matrix_unread.lock"
TTL=25 # seconds; just under the widget's 30s tick, so each tick syncs once
ZERO='{"msg_count":0,"mention_count":0}'

if [ "$1" = "login" ]; then
  if [ ! -t 0 ]; then
    echo "login needs an interactive terminal (it prompts for the password)" >&2
    exit 1
  fi
  read -rp "Homeserver [https://optiplex.tail1e6376.ts.net:8448]: " URL
  URL=${URL:-https://optiplex.tail1e6376.ts.net:8448}
  read -rp "User [joshua]: " USER_NAME
  read -rsp "Password: " PASSWORD
  echo
  # The password goes through stdin, never argv.
  RESPONSE=$(jq -n --arg u "${USER_NAME:-joshua}" --arg p "$PASSWORD" '{
    type: "m.login.password",
    identifier: {type: "m.id.user", user: $u},
    password: $p,
    device_id: "sketchybar",
    initial_device_display_name: "sketchybar"
  }' | curl -sS --max-time 10 -H "Content-Type: application/json" -d @- "$URL/_matrix/client/v3/login")
  TOKEN=$(echo "$RESPONSE" | jq -r '.access_token // empty' 2>/dev/null)
  if [ -z "$TOKEN" ]; then
    echo "Login failed: ${RESPONSE:-no response (is Tailscale up?)}" >&2
    exit 1
  fi
  echo "Add to ~/dotfiles/secrets.env (sops edit):"
  echo "MATRIX_URL=$URL"
  echo "MATRIX_TOKEN=$TOKEN"
  exit 0
fi

age_of() { echo $(($(date +%s) - $(date -r "$1" +%s))); }

if [ -f "$CACHE_FILE" ] && [ "$(age_of "$CACHE_FILE")" -lt "$TTL" ]; then
  cat "$CACHE_FILE"
  exit 0
fi

# Both count commands of a tick run at once; only one of them syncs. A lock left by a
# killed run is cleared after 30s.
if [ -d "$LOCK_DIR" ] && [ "$(age_of "$LOCK_DIR")" -gt 30 ]; then
  rmdir "$LOCK_DIR" 2>/dev/null
fi
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  for _ in $(seq 1 35); do
    [ -d "$LOCK_DIR" ] || break
    sleep 0.2
  done
  cat "$CACHE_FILE" 2>/dev/null || echo "$ZERO"
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

export FILTER='{"presence":{"types":[]},"account_data":{"types":[]},"room":{"timeline":{"limit":1},"state":{"types":[]},"ephemeral":{"types":[]},"account_data":{"types":[]}}}'
RESPONSE=$(
  sops exec-env ~/secrets.env 'curl -s --connect-timeout 2 --max-time 5 -G -H "Authorization: Bearer ${MATRIX_TOKEN}" --data-urlencode "timeout=0" --data-urlencode "filter=${FILTER}" "${MATRIX_URL}/_matrix/client/v3/sync"'
)

if echo "$RESPONSE" | jq -e '.next_batch' >/dev/null 2>&1; then
  echo "$RESPONSE" | jq -c '[.rooms.join // {} | .[].unread_notifications] | {
    msg_count: (map(.notification_count // 0) | add // 0),
    mention_count: (map(.highlight_count // 0) | add // 0)
  }' >"$CACHE_FILE"
  cat "$CACHE_FILE"
else
  # Unreachable (e.g. Tailscale down) or not logged in: keep showing the last counts, and
  # refresh the cache's mtime so the next attempt waits a full TTL instead of every call
  # paying the timeout.
  [ -f "$CACHE_FILE" ] || echo "$ZERO" >"$CACHE_FILE"
  touch "$CACHE_FILE"
  cat "$CACHE_FILE"
fi
