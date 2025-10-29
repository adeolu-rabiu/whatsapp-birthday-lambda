#!/usr/bin/env bash
set -euo pipefail

cd /opt/whatsapp-birthday-lambda

# ---- Settings ---------------------------------------------------------------
# Set DRY_RUN=true to preview without sending
DRY_RUN=${DRY_RUN:-false}

# Put any groups you DON'T want to message here (exact names)
EXCLUDE_GROUPS=(
  # "Admins Only"
  # "Testing"
)

# Rate limit between sends (seconds)
SLEEP_SECS=2
# -----------------------------------------------------------------------------


# Message (preserves newlines & emojis)
apology=$(cat <<'MSG'
Hi everyone! 👋

Apologies for the test message this morning at 8 AM. We were debugging the birthday reminder system and forgot to remove test code.

The issue has been fixed. From tomorrow onwards, you'll receive:
🎂 Birthday greetings when someone has a birthday
💡 Fun facts on days without birthdays

Thanks for your patience!
- O-BOT Team
MSG
)

# Helper: check if a value is in EXCLUDE_GROUPS
should_exclude() {
  local name="$1"
  for ex in "${EXCLUDE_GROUPS[@]}"; do
    [[ "$name" == "$ex" ]] && return 0
  done
  return 1
}

echo "📥 Fetching groups from bot..."
groups_json="$(curl -fsS http://localhost:3005/groups)"
mapfile -t groups < <(echo "$groups_json" | jq -r '.[].name' | awk 'NF' | sort -u)

if [[ ${#groups[@]} -eq 0 ]]; then
  echo "❌ No groups returned by /groups. Is the bot logged in? Try: curl -s http://localhost:3005/health"
  exit 1
fi

echo "✅ Found ${#groups[@]} groups"
[[ "$DRY_RUN" == "true" ]] && echo "🔎 DRY-RUN is ON — no messages will be sent."

for g in "${groups[@]}"; do
  if should_exclude "$g"; then
    echo "⏭️  Skipping excluded group: $g"
    continue
  fi

  echo "📨 Sending apology to: $g"

  if [[ "$DRY_RUN" == "true" ]]; then
    continue
  fi

  payload="$(jq -n --arg group "$g" --arg msg "$apology" '{group:$group, message:$msg}')"
  http_code="$(curl -sS -o /tmp/send_resp.$$ -w "%{http_code}" \
    -X POST http://localhost:3005/send \
    -H 'Content-Type: application/json' \
    -d "$payload")"

  if [[ "$http_code" == "200" ]]; then
    echo "   ✅ Sent to \"$g\""
  else
    echo "   ❌ Failed ($http_code) for \"$g\": $(cat /tmp/send_resp.$$)"
  fi
  rm -f /tmp/send_resp.$$
  sleep "$SLEEP_SECS"
done

echo "🎉 Done."

