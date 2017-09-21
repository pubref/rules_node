set -e



if ./lyrics | grep -q 'Count (letter a): 16'; then
    echo "PASS"
else
    exit 1
fi
