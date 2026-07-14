#!/usr/bin/env bash
# Stops the @calcom/web server started by setup.sh so each fix-loop retry
# begins on a clean port (avoids EADDRINUSE on retried setup attempts).
set -uo pipefail

pkill -f "next start" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true

exit 0
