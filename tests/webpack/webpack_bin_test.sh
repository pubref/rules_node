set -e

pwd
ls -al external/yarn_modules/webpack_bin_bundle/node_modules
#find .
if (./external/yarn_modules/webpack_bin --help &) | grep -q 'Server listening on port 3000!'; then
    echo "PASS"
else
    exit 1
fi
