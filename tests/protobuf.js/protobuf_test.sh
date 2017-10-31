set -euo pipefail

if ./app | grep -q 'SUCCESS'; then
    echo "PASS"
else
    exit 1
fi
