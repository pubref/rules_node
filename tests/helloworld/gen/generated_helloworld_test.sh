set -e

# Check the content of generated program
if cat gen/helloworld.js | grep -q 'console.log("Hello World");'; then
    echo "PASS"
else
    exit 1
fi
