#!/usr/bin/env bash
# Check that every URL in the catalog and README still loads.
# Network-dependent, so it runs weekly in CI rather than on every push.
set -uo pipefail

cd "$(dirname "$0")/.."
failed=0

for url in $(grep -rhoE 'https?://[^ "]+' catalog/*.yaml README.md | sort -u); do
  code=$(curl -s -o /dev/null -L --max-time 20 -A 'Mozilla/5.0' -w '%{http_code}' "$url")
  if [ "$code" -ge 400 ] || [ "$code" -eq 0 ]; then
    echo "broken ($code): $url"
    failed=1
  fi
done

[ "$failed" -eq 0 ] && echo "all links OK"
exit "$failed"
