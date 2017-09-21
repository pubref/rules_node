set -e

if (./server &) | grep -q 'Server listening on port 3000!'; then
    echo "PASS"
else
    exit 1
fi
