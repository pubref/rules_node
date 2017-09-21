set -e

if ./question | grep -q 'The meaning of life is 42'; then
    echo "PASS"
else
    exit 1
fi
