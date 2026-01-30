#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

PDS_ENV_FILE=${PDS_ENV_FILE:-"/pds/pds.env"}
source "${PDS_ENV_FILE}"

# Check if we should skip crawl requests (for non-production environments)
PDS_ENVIRONMENT="${PDS_ENVIRONMENT:-production}"
if [[ "${PDS_ENVIRONMENT}" != "production" ]]; then
  echo "Skipping crawl request: PDS_ENVIRONMENT is '${PDS_ENVIRONMENT}' (not production)"
  echo "This prevents sending dev/staging data to production Bluesky servers."
  exit 0
fi

RELAY_HOSTS="${1:-}"
if [[ "${RELAY_HOSTS}" == "" ]]; then
  RELAY_HOSTS="${PDS_CRAWLERS}"
fi

if [[ "${RELAY_HOSTS}" == "" ]]; then
  echo "ERROR: missing RELAY HOST parameter." >/dev/stderr
  echo "Usage: $0 <RELAY HOST>[,<RELAY HOST>,...]" >/dev/stderr
  exit 1
fi

for host in ${RELAY_HOSTS//,/ }; do
  echo "Requesting crawl from ${host}"
  if [[ $host != https:* && $host != http:* ]]; then
    host="https://${host}"
  fi
  curl \
    --fail \
    --silent \
    --show-error \
    --request POST \
    --header "Content-Type: application/json" \
    --data "{\"hostname\": \"${PDS_HOSTNAME}\"}" \
    "${host}/xrpc/com.atproto.sync.requestCrawl" >/dev/null
done

echo "done"
