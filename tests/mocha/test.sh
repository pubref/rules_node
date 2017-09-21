set -e

if ./test | grep -q 'PASSED'; then
    echo "PASS"
else
    exit 1
fi
