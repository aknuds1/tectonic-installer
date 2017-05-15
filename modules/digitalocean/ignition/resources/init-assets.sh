#!/bin/bash
set -e

# Populate the kubelet.env file
mkdir -p /etc/kubernetes
echo "KUBELET_IMAGE_URL=${kubelet_image_url}" > /etc/kubernetes/kubelet.env
echo "KUBELET_IMAGE_TAG=${kubelet_image_tag}" >> /etc/kubernetes/kubelet.env

exit 0
