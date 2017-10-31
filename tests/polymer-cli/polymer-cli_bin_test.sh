set -e

if (./external/yarn_modules/polymer-cli_polymer_bin --help &) | grep -qF '/__\/   /__\/  \/__\  The multi-tool for Polymer projects'; then
    echo "PASS"
else
    exit 1
fi
