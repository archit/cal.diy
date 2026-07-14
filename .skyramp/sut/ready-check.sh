#!/usr/bin/env bash
# Polled by Testbot's targetReadyCheckCommand until it exits 0. Must cover
# every service the UI tests will hit: the web app itself and Mailhog (used
# by E2E flows that assert on received emails, e.g. magic links / OTP).
set -uo pipefail

curl -sf http://localhost:3000/ >/dev/null 2>&1 || exit 1
curl -sf http://localhost:8025/ >/dev/null 2>&1 || exit 1

exit 0
