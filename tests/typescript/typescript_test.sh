set -e

if ./ts_report | grep -q 'animal "Bear" has taxonomy Animalia/Chordata'; then
    echo "PASS"
else
    exit 1
fi
