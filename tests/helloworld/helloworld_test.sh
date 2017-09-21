set -e

if ./helloworld | grep -q 'Hello World!'; then
    echo "PASS"
else
    exit 1
fi
