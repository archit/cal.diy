#!/usr/bin/env bash
# Run when targetReadyCheckCommand times out. Output is surfaced in the
# failure PR comment, so keep it focused on why the SUT isn't healthy.
set -uo pipefail

echo "--- last 200 lines of @calcom/web server log ---"
tail -n 200 /tmp/calcom-web.log 2>/dev/null || echo "(no log found at /tmp/calcom-web.log)"

echo "--- listening ports ---"
(ss -ltnp 2>/dev/null || netstat -ltnp 2>/dev/null) | grep -E ':3000|:8025|:5432' || echo "(nothing listening on 3000/8025/5432)"

echo "--- docker containers (Postgres/Mailhog service containers) ---"
docker ps -a 2>/dev/null || echo "(docker not available)"

exit 0
