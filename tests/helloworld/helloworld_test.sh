set -e

if ./helloworld_bin | grep -q 'Hello World!'; then
    echo "PASS"
else
    exit 1
fi
