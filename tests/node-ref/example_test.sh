set -e

if (./example &) | grep -q '12345'; then
    echo "PASS"
else
    exit 1
fi
