#!/usr/bin/env bash
# Builds and starts @calcom/web (Next.js) from PR source, backed by the
# Postgres + Mailhog services declared on the Testbot job, then backgrounds
# the server so this script can exit. Mirrors the setup chain in
# .github/workflows/e2e.yml (yarn-install -> prisma generate -> cache-db ->
# cache-build) plus the exact server-start command from playwright.config.ts's
# webServer, since Testbot drives the browser directly instead of via `yarn e2e`.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Disk hygiene: this is a heavy monorepo build, prune before starting so
# fix-loop retries don't accumulate stale BuildKit/docker cache across attempts.
docker builder prune -af >/dev/null 2>&1 || true
docker image prune -f >/dev/null 2>&1 || true

export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=8192}"
: "${DATABASE_URL:=postgresql://postgres:postgres@localhost:5432/calendso}"
export DATABASE_URL
export DATABASE_DIRECT_URL="$DATABASE_URL"
: "${NEXTAUTH_SECRET:=$(openssl rand -base64 32)}"
export NEXTAUTH_SECRET
: "${CALENDSO_ENCRYPTION_KEY:=$(openssl rand -base64 24)}"
export CALENDSO_ENCRYPTION_KEY
: "${NEXTAUTH_URL:=http://localhost:3000}"
export NEXTAUTH_URL
: "${NEXT_PUBLIC_WEBAPP_URL:=http://localhost:3000}"
export NEXT_PUBLIC_WEBAPP_URL
: "${EMAIL_SERVER_HOST:=localhost}"
export EMAIL_SERVER_HOST
: "${EMAIL_SERVER_PORT:=1025}"
export EMAIL_SERVER_PORT
: "${E2E_TEST_MAILHOG_ENABLED:=1}"
export E2E_TEST_MAILHOG_ENABLED
export NEXT_PUBLIC_IS_E2E=1
export HUSKY=0

echo "==> yarn install"
yarn install --inline-builds

echo "==> yarn prisma generate"
yarn prisma generate

echo "==> yarn db-seed"
yarn db-seed

echo "==> yarn build (this can take a while on a cold cache)"
yarn build

echo "==> copy-app-store-static"
yarn workspace @calcom/web copy-app-store-static

echo "==> starting @calcom/web on :3000 (backgrounded)"
nohup env NEXT_PUBLIC_IS_E2E=1 NODE_OPTIONS='--dns-result-order=ipv4first' \
  yarn workspace @calcom/web start -p 3000 > /tmp/calcom-web.log 2>&1 &
disown

echo "==> setup.sh done, server starting in background (log: /tmp/calcom-web.log)"
