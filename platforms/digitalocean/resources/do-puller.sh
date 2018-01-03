#!/bin/bash
# This is a utility to download a file from DigitalOcean Spaces object storage.
set -e
set -o pipefail

if [ "$#" -ne "2" ]; then
    echo "Usage: $0 location destination"
    exit 1
fi

export ACCESS_KEY_ID=${do_access_key_id}
export SECRET_ACCESS_KEY=${do_secret_access_key}
export REGION=${do_region}

# A tool for interacting with DO's object storage: https://github.com/aknuds1/do-spaces-tool
docker pull aknudsen/do-spaces-tool:0.2.0 > /dev/null
# shellcheck disable=SC2034,SC1083
FILENAME_DEST=$(basename $${2})
# shellcheck disable=SC2034,SC1083
docker run --rm -e ACCESS_KEY_ID -e SECRET_ACCESS_KEY -e REGION -t --net=host -v /tmp:/spaces aknudsen/do-spaces-tool:0.2.0 download $${1} /spaces/$${FILENAME_DEST}
# shellcheck disable=SC2034,SC1083
/usr/bin/sudo mv /tmp/$${FILENAME_DEST} $${2}
