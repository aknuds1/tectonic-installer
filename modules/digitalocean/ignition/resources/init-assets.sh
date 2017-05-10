#!/bin/bash
set -e

# Defer cleanup of rkt containers and images.
trap "{ /usr/bin/rkt gc --grace-period=0; /usr/bin/rkt image gc --grace-period 0; } &> /dev/null" EXIT

mkdir -p /run/metadata

# Download the assets from S3.
/usr/bin/bash /opt/s3-puller.sh ${assets_s3_location} /opt/tectonic/tectonic.zip
unzip -o -d /opt/tectonic/ /opt/tectonic/tectonic.zip
rm /opt/tectonic/tectonic.zip

# Populate the kubelet.env file.
mkdir -p /etc/kubernetes
echo "KUBELET_IMAGE_URL=${kubelet_image_url}" > /etc/kubernetes/kubelet.env
echo "KUBELET_IMAGE_TAG=${kubelet_image_tag}" >> /etc/kubernetes/kubelet.env

exit 0
