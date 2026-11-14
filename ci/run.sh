#!/bin/bash
set -euo pipefail
# Keep the local all-in-one entry point; --lane selects an isolated CI partition.
exec python3 "$(dirname "$0")/run.py" "$@"
