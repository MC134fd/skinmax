#!/bin/bash
# check-secrets.sh — CI guardrail for hardcoded API keys in tracked source.
# Exit 1 if any real sk- style key literal is found in tracked files.
# Ignores:
#   - placeholder strings containing "your" (e.g., "sk-your-openai-api-key-here")
#   - .hasPrefix("sk-") style format checks
#   - this script itself

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "=== Secret Pattern Check ==="

# Search tracked files for sk- followed by 20+ alphanumeric/dash chars (real key pattern).
# Filter out known safe patterns.
MATCHES=$(git ls-files -z \
    | xargs -0 grep -n -E 'sk-[A-Za-z0-9_-]{20,}' \
    -- 2>/dev/null \
    | grep -v 'sk-your' \
    | grep -v 'hasPrefix' \
    | grep -v 'check-secrets.sh' \
    || true)

if [ -n "$MATCHES" ]; then
    echo "FAIL: Possible hardcoded API key(s) found in tracked source:"
    echo "$MATCHES"
    exit 1
fi

echo "PASS: No hardcoded API key patterns found in tracked source."
exit 0
