#!/bin/bash
set -e

unzip -o -d /var/tmp/tectonic/ /var/tmp/tectonic.zip
rm /var/tmp/tectonic.zip
# make files in /opt/tectonic available atomically
mv /var/tmp/tectonic /opt/tectonic

# Populate the kubelet.env file
mkdir -p /etc/kubernetes
echo "KUBELET_IMAGE_URL=${kubelet_image_url}" > /etc/kubernetes/kubelet.env
echo "KUBELET_IMAGE_TAG=${kubelet_image_tag}" >> /etc/kubernetes/kubelet.env

exit 0
