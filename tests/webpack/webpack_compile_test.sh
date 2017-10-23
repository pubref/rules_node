set -e

# Check for webpack signature in the compiled file (present on first line)
if (cat bundle.js &) | grep -q '// webpackBootstrap'; then
    echo "PASS"
else
    exit 1
fi
