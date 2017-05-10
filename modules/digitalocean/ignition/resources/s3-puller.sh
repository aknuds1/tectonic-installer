#!/bin/bash
if [ "$#" -ne "2" ]; then
    echo "Usage: $0 location destination"
    exit 1
fi

/usr/bin/sudo /usr/bin/rkt run \
    --net=host --dns=host \
    --trust-keys-from-https quay.io/coreos/awscli:025a357f05242fdad6a81e8a6b520098aa65a600 \
    --volume=tmp,kind=host,source=/tmp --mount=volume=tmp,target=/tmp \
    --set-env="LOCATION=$1" \
    --exec=/bin/bash -- -c '
        /usr/bin/aws --region=${region} s3 cp s3://${LOCATION} /tmp/${LOCATION//\//+}
    '

/usr/bin/sudo mv /tmp/${1//\//+} $2
