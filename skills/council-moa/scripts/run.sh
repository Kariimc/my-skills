#!/usr/bin/env bash
# run.sh — run the council using council.config.json (+ .env if present).
# Usage:  ./run.sh "Should we adopt microservices?"
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$dir/.env" ] && { set -a; . "$dir/.env"; set +a; }
[ -z "${1:-}" ] && { echo 'Usage: ./run.sh "your question"'; exit 1; }
python "$dir/council.py" "$*" --config "$dir/council.config.json"
